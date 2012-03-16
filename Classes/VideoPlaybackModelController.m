//
//  VideoPlaybackModelController.m
//  ipad
//
//  Created by Bill So on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "VideoPlaybackModelController.h"
#import "NMVideo.h"
#import "NMChannel.h"

#define NM_MAX_VIDEO_IN_QUEUE				3
#define NM_NMVIDEO_CACHE_SIZE				5

#define NM_MODEL_PREVIUOS_VIDEO_MASK		0x08
#define NM_MODEL_CURRENT_VIDEO_MASK			0x04
#define NM_MODEL_NEXT_VIDEO_MASK			0x02
#define NM_MODEL_NEXT_NEXT_VIDEO_MASK		0x01

static VideoPlaybackModelController * sharedVideoPlaybackModelController_ = nil;
NSString * const NMWillBeginPlayingVideoNotification = @"NMWillBeginPlayingVideoNotification";

@interface VideoPlaybackModelController (PrivateMethods)

- (void)initializePlayHead;
	
@end

@implementation VideoPlaybackModelController

@synthesize currentIndexPath, previousIndexPath;
@synthesize nextIndexPath, nextNextIndexPath;
@synthesize currentVideo, nextVideo;
@synthesize nextNextVideo, previousVideo;
@synthesize channel, dataDelegate, numberOfVideos;
@synthesize fetchedResultsController=fetchedResultsController_, managedObjectContext;
@synthesize debugMessageView;

+ (VideoPlaybackModelController *)sharedVideoPlaybackModelController {
	if ( sharedVideoPlaybackModelController_ == nil ) {
		sharedVideoPlaybackModelController_ = [[VideoPlaybackModelController alloc] init];
	}
	return sharedVideoPlaybackModelController_;
}

- (id)init {
	self = [super init];
	nowboxTaskController = [NMTaskQueueController sharedTaskQueueController];
	
	// listen to notification
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
//	[nc addObserver:self selector:@selector(handleDidGetVideoListNotification:) name:NMDidGetChannelVideoListNotification object:nil];
	[nc addObserver:self selector:@selector(handleErrorNotification:) name:NMDidFailGetYouTubeDirectURLNotification object:nil];
	[nc addObserver:self selector:@selector(handleErrorNotification:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];

	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[currentVideo release];
	[currentIndexPath release];
	[nextNextVideo release];
	[nextIndexPath release];
	[nextNextVideo release];
	[nextNextIndexPath release];
	[previousVideo release];
	[previousIndexPath release];
	[fetchedResultsController_ release];
	[managedObjectContext release];
	[super dealloc];
}

#pragma mark Getter-setter
- (void)setChannel:(NMChannel *)aChn {
	if ( aChn ) {
		// aChn is not null
		if ( channel != aChn ) {
			[channel release];
			if ( channel != nil ) self.fetchedResultsController = nil;
			channel = [aChn retain];
		} else {
			return;
		}
	} else {
		// aChn is null
		if ( channel ) {
			[channel release];
			channel = nil;
		}
		self.currentIndexPath = nil;
		self.currentVideo = nil;
		self.nextIndexPath = nil;
		self.nextVideo = nil;
		self.nextNextIndexPath = nil;
		self.nextNextVideo = nil;
		return;
		// return
	}
	
	if ( currentVideo ) {
		// mark the current video as "played"
		currentVideo.nm_did_play = [NSNumber numberWithBool:YES];
	}
	self.previousVideo = nil;
	self.previousIndexPath = nil;
	self.currentIndexPath = nil;
	self.currentVideo = nil;
	self.nextIndexPath = nil;
	self.nextVideo = nil;
	self.nextNextIndexPath = nil;
	self.nextNextVideo = nil;
	
	// 3 possible cases:
	// check if videos exists
	// check if last video exists
	// check if we need to get video list
	
	id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
	numberOfVideos = [sectionInfo numberOfObjects];
	// check if there's video to play
	if ( numberOfVideos ) {
		// check if we need to go back to the last video
		NMVideo * lastSessVid = [nowboxTaskController.dataController lastSessionVideoForChannel:aChn];
		if ( lastSessVid ) {
			// we can find the last watched video.
			self.currentIndexPath = [self.fetchedResultsController indexPathForObject:lastSessVid];
			self.currentVideo = lastSessVid;
			[dataDelegate didLoadCurrentVideoManagedObjectForController:self];
			
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
			NSLog(@"last viewed title: %@", self.currentVideo.title);
#endif
			// init the playhead. sth similar to initializePlayHead
			if ( currentIndexPath.row + 1 < numberOfVideos ) {
				self.nextIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row + 1 inSection:0];
				self.nextVideo = [self.fetchedResultsController objectAtIndexPath:nextIndexPath];
				
				// set the detail movie view for the next video
				[dataDelegate didLoadNextVideoManagedObjectForController:self];
				
			}
			if ( currentIndexPath.row + 2 < numberOfVideos ) {
				self.nextNextIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row + 2 inSection:0];
				self.nextNextVideo = [self.fetchedResultsController objectAtIndexPath:nextNextIndexPath];
				[dataDelegate didLoadNextNextVideoManagedObjectForController:self];
				// no need to set detail video object
			}
			if ( currentIndexPath.row - 1 > -1 ) {
				self.previousIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row - 1 inSection:0];
				self.previousVideo = [self.fetchedResultsController objectAtIndexPath:self.previousIndexPath];
				
				// set the detail movie view for the previous video
				[dataDelegate didLoadPreviousVideoManagedObjectForController:self];
			}
		} else {
			// we can't find the video from the vid stored. Start playing from the first video in the channel
			[self initializePlayHead];
		}
	}/* else {
		self.previousVideo = nil;
		self.previousIndexPath = nil;
		self.currentIndexPath = nil;
		self.currentVideo = nil;
		self.nextIndexPath = nil;
		self.nextVideo = nil;
		self.nextNextIndexPath = nil;
		self.nextNextVideo = nil;
	}*/
	// check if we need to download more. Or, in the case where there's no video, download
	if ( numberOfVideos == 0 || currentIndexPath.row + NM_NMVIDEO_CACHE_SIZE > numberOfVideos) {
		// download more video from Nowmov
		[nowboxTaskController issueGetMoreVideoForChannel:channel];
	}
	[dataDelegate controller:self didUpdateVideoListWithTotalNumberOfVideo:numberOfVideos];
}

- (void)setVideo:(NMVideo *)aVideo {
	if ( aVideo == nil ) return;
	NMChannel * aChn = aVideo.channel;
	if ( channel != aChn ) {
		[channel release];
		channel = [aChn retain];
		
		// need to refetch data
		self.fetchedResultsController = nil;
		id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
		numberOfVideos = [sectionInfo numberOfObjects];
		
	} else if ( aVideo == currentVideo ) {
		// special case
		// - user tap the current video. Do nth
		return;
	} else if ( aVideo == nextVideo ) {
		// check for special case:
		// - user tap the next video of the currently playing video
		// perform switch to next video
	} else if ( aVideo == nextNextVideo ) {
		// user tapped the next next video which should be buffered in queue player.
	}
	
	if ( currentVideo ) {
		// mark the current video as "played"
		currentVideo.nm_did_play = [NSNumber numberWithBool:YES];
	}
	self.previousVideo = nil;
	self.previousIndexPath = nil;
	self.currentIndexPath = nil;
	self.currentVideo = nil;
	self.nextIndexPath = nil;
	self.nextVideo = nil;
	self.nextNextIndexPath = nil;
	self.nextNextVideo = nil;
	
	self.currentIndexPath = [self.fetchedResultsController indexPathForObject:aVideo];
	self.currentVideo = aVideo;
	[dataDelegate didLoadCurrentVideoManagedObjectForController:self];
	
	// init the playhead. sth similar to initializePlayHead
	if ( currentIndexPath.row + 1 < numberOfVideos ) {
		self.nextIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row + 1 inSection:0];
		self.nextVideo = [self.fetchedResultsController objectAtIndexPath:nextIndexPath];
		
		// set the detail movie view for the next video
		[dataDelegate didLoadNextVideoManagedObjectForController:self];
		
	}
	if ( currentIndexPath.row + 2 < numberOfVideos ) {
		self.nextNextIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row + 2 inSection:0];
		self.nextNextVideo = [self.fetchedResultsController objectAtIndexPath:nextNextIndexPath];
		[dataDelegate didLoadNextNextVideoManagedObjectForController:self];
		// no need to set detail video object
	}
	if ( currentIndexPath.row > 0 ) {
		self.previousIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row - 1 inSection:0];
		self.previousVideo = [self.fetchedResultsController objectAtIndexPath:self.previousIndexPath];
		
		// set the detail movie view for the previous video
		[dataDelegate didLoadPreviousVideoManagedObjectForController:self];
	}
	
	// check if we need to download more. Or, in the case where there's no video, download
	if ( numberOfVideos == 0 || currentIndexPath.row + NM_NMVIDEO_CACHE_SIZE > numberOfVideos) {
		// download more video from Nowmov
		[nowboxTaskController issueGetMoreVideoForChannel:channel];
	}
	[dataDelegate controller:self didUpdateVideoListWithTotalNumberOfVideo:numberOfVideos];
}

#pragma mark Video list management

- (void)initializePlayHead {
	self.currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	self.currentVideo = [self.fetchedResultsController objectAtIndexPath:currentIndexPath];
	[dataDelegate didLoadCurrentVideoManagedObjectForController:self];
	if ( numberOfVideos > 1 ) {
		self.nextIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
		self.nextVideo = [self.fetchedResultsController objectAtIndexPath:nextIndexPath];
		[dataDelegate didLoadNextVideoManagedObjectForController:self];
	}
	if ( numberOfVideos > 2 ) {
		self.nextNextIndexPath = [NSIndexPath indexPathForRow:2 inSection:0];
		self.nextNextVideo = [self.fetchedResultsController objectAtIndexPath:nextNextIndexPath];
	}
}

- (NMVideo *)firstVideo {
	if ( numberOfVideos ) 
		return [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	return nil;
}


- (BOOL)moveToNextVideo {
	if ( nextIndexPath == nil ) {
		// we can't move forward. This may not mean we have no more items. It could be the data has not been loaded to Core Data.
		return NO;
	}
	
	// purge next video path
	self.previousIndexPath = currentIndexPath;
	self.currentIndexPath = nextIndexPath;
	// video
	self.previousVideo = currentVideo;
	self.currentVideo = nextVideo;
	
	// update next video
	self.nextIndexPath = nextNextIndexPath;
	self.nextVideo = nextNextVideo;
	if ( nextIndexPath ) {
		[dataDelegate didLoadNextVideoManagedObjectForController:self];
	}
	
	// update next next video
	if ( nextNextIndexPath && nextNextIndexPath.row + 1 < numberOfVideos ) {
		// load next next video
		self.nextNextIndexPath = [NSIndexPath indexPathForRow:nextNextIndexPath.row + 1 inSection:0];
		self.nextNextVideo = [self.fetchedResultsController objectAtIndexPath:nextNextIndexPath];
		[dataDelegate didLoadNextNextVideoManagedObjectForController:self];
	} else {
		self.nextNextIndexPath = nil;
		self.nextNextVideo = nil;
		// fetch more video
		[nowboxTaskController issueGetMoreVideoForChannel:channel];
	}
	return YES;
}

- (BOOL)moveToPreviousVideo {
	if ( previousIndexPath == nil ) {
		return NO;
	}
	
	// move next-next video
	self.nextNextIndexPath = nextIndexPath;
	self.nextNextVideo = nextVideo;
	
	// move next video
	self.nextIndexPath = currentIndexPath;
	self.nextVideo = currentVideo;
	
	// move current video
	self.currentIndexPath = previousIndexPath;
	self.currentVideo = previousVideo;
	
	// move previous video
	if ( previousIndexPath && previousIndexPath.row > 0 ) {
		// fetch the new previous video
		self.previousIndexPath = [NSIndexPath indexPathForRow:previousIndexPath.row - 1 inSection:0];
		// we can set the previous video
		self.previousVideo = [self.fetchedResultsController objectAtIndexPath:previousIndexPath];
		[dataDelegate didLoadPreviousVideoManagedObjectForController:self];
	} else {
		self.previousIndexPath = nil;
		self.previousVideo = nil;
	}
	
	return YES;
}

- (NSArray *)videosForBuffering {
	NSMutableArray * theArray = [NSMutableArray arrayWithCapacity:3];
	if ( currentVideo ) {
		[theArray addObject:currentVideo];
		
		if ( nextVideo ) {
			[theArray addObject:nextVideo];
			
			if ( nextNextVideo ) {
				[theArray addObject:nextNextVideo];
			}
		}
	}
	return [theArray count] ? theArray : nil;
}

- (void)revertVideoToNewState:(NMVideo *)vdo {
	vdo.nm_error = [NSNumber numberWithInteger:0];
	vdo.nm_playback_status = NMVideoQueueStatusNone;
	vdo.nm_direct_sd_url = nil;
	vdo.nm_direct_url = nil;
}

- (BOOL)checkDirectURLExpiryForVideo:(NMVideo *)vdo currentTime:(NSInteger)curTime {
	NSInteger vdoTime = vdo.nm_direct_url_expiry;
	if ( vdoTime && vdoTime - 10 < curTime ) {
		// the video link has expired
		[self revertVideoToNewState:vdo];
		return YES;
	}
	return NO;
}

- (BOOL)refreshDirectURLToBufferedVideos {
	BOOL needRefresh = YES;
	NSInteger curTime = (NSInteger)[[NSDate dateWithTimeIntervalSinceNow:0.0] timeIntervalSince1970];
	if ( [self checkDirectURLExpiryForVideo:currentVideo currentTime:curTime] ) {
		// if the first video is expired, we flush the whole playback queue.
		if ( nextVideo ) {
			[self revertVideoToNewState:nextVideo];
			if ( nextNextVideo ) {
				[self revertVideoToNewState:nextNextVideo];
			}
		}
		// the direct link of current video has expired.
		[dataDelegate shouldRevertCurrentVideoToNewStateForController:self];
	} else if ( [self checkDirectURLExpiryForVideo:nextVideo currentTime:curTime] ) {
		// flush remain of other video in the queue
		if ( nextNextVideo ) {
			[self revertVideoToNewState:nextNextVideo];
		}
		[dataDelegate shouldRevertNextVideoToNewStateForController:self];
	} else if ( [self checkDirectURLExpiryForVideo:nextNextVideo currentTime:curTime] ) {
		[dataDelegate shouldRevertNextNextVideoToNewStateForController:self];
	} else {
		needRefresh = NO;
	}
	return needRefresh;
}

#pragma mark Notification handlers

- (void)handleErrorNotification:(NSNotification *)aNotification {
	NSString * theName = [aNotification name];
	if ( [theName isEqualToString:NMDidFailGetYouTubeDirectURLNotification] ) {
		// error resolving the direct URL. Let the server knows about it
#ifdef DEBUG_PLAYBACK_QUEUE
		NSLog(@"received resolution error notificaiton - %@", [aNotification userInfo]);
#endif
		NSDictionary * info = [aNotification userInfo];
		[nowboxTaskController issueExamineVideo:[info objectForKey:@"target_object"] errorInfo:info];
	} else if ( [theName isEqualToString:AVPlayerItemFailedToPlayToEndTimeNotification] ) {
#ifdef DEBUG_PLAYER_DEBUG_MESSAGE
		NSError * theErr = [[aNotification userInfo] objectForKey:AVPlayerItemFailedToPlayToEndTimeErrorKey];
		debugMessageView.text = [debugMessageView.text stringByAppendingFormat:@"\n%@", [theErr localizedDescription]];
		NSLog(@"can't finish playing video. just skip it!");
#endif
//		didPlayToEnd = YES;
//		[self showNextVideo:YES];
	} else {
#ifdef DEBUG_PLAYBACK_QUEUE
		NSLog(@"other error playing video");
#endif
	}
	//TODO: remove the video from playlist
}
/*
- (void)handleDidGetVideoListNotification:(NSNotification *)aNotification {
	// MOC changes were made where notification is received
	NSDictionary * userInfo = [aNotification userInfo];
	NMChannel * srcChannel = [userInfo objectForKey:@"channel"];
	NSInteger numVideo = [[userInfo objectForKey:@"num_video_added"] integerValue];
	if ( srcChannel == channel && numVideo == 0 ) {
		// we can't get any new video from the server. try getting by doubling the count
		NSUInteger vidReq = [[userInfo objectForKey:@"num_video_requested"] unsignedIntegerValue];
		if ( vidReq < 41 ) {
			[nowboxTaskController issueGetVideoListForChannel:channel];
		} else {
			// we have finish up this channel
		}
	} 
}
*/
#pragma mark Fetched Results Controller
- (NSFetchedResultsController *)fetchedResultsController {
    
    if (fetchedResultsController_ != nil) {
        return fetchedResultsController_;
    }
    
    /*
     Set up the fetched results controller.
	 */
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:NMVideoEntityName inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
	[fetchRequest setReturnsObjectsAsFaults:NO];
	[fetchRequest setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"detail"]];
	
	// Make sure the condition here - predicate and sort order is EXACTLY the same as in deleteVideoInChannel:afterVideo: in data controller!!!
	// set predicate
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"channel == %@ AND nm_error == 0", channel]];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:5];
    
    // Edit the sort key as appropriate.
//    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:YES];
	NSSortDescriptor * timestampDesc = [[NSSortDescriptor alloc] initWithKey:@"published_at" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:timestampDesc, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [fetchRequest release];
//    [sortDescriptor release];
	[timestampDesc release];
    [sortDescriptors release];
    
    NSError *error = nil;
    if (![fetchedResultsController_ performFetch:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return fetchedResultsController_;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	changeSessionUpdateCount = YES;
	deletedOlderVideos = NO;
	videoEncounteredBitArray = 0;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	if ( changeSessionUpdateCount ) {
		changeSessionVideoCount = NO;
		// count the number of rows left. We MUST do the count here. Not in controllerWillChangeContent. Core Data have NOT modified the database yet in "controllerWillChangeContent"
		id <NSFetchedResultsSectionInfo> sectionInfo = [[controller sections] objectAtIndex:0];
		changeSessionVideoCount = [sectionInfo numberOfObjects];
	}
	switch (type) {
		case NSFetchedResultsChangeDelete:
		{
			rowCountHasChanged = YES;
			if ( [indexPath isEqual:currentIndexPath] ) {
				if ( currentIndexPath.row >= changeSessionVideoCount ) {
					self.nextIndexPath = nil;
					self.nextNextIndexPath = nil;
					if ( changeSessionVideoCount ) self.currentIndexPath = [NSIndexPath indexPathForRow:changeSessionVideoCount - 1 inSection:0];
					else self.currentIndexPath = nil;
					if ( currentIndexPath.row > 0 ) {
						self.previousIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row - 1 inSection:0];
					} else {
						self.previousIndexPath = nil;
					}
				} else {
					if ( currentIndexPath.row + 1 >= changeSessionVideoCount ) {
						self.nextIndexPath = nil;
					}
					if ( currentIndexPath.row + 2 >= changeSessionVideoCount ) {
						self.nextNextIndexPath = nil;
					}
				}
			} else if ( [indexPath isEqual:nextIndexPath] ) {
				if ( nextIndexPath.row >= changeSessionVideoCount ) {
					self.nextNextIndexPath = nil;
					
					if ( changeSessionVideoCount > 1 && changeSessionVideoCount - 1 != currentIndexPath.row ) {
						self.nextIndexPath = [NSIndexPath indexPathForRow:changeSessionVideoCount - 1 inSection:0];
					} else {
						self.nextIndexPath = nil;
					}
				} else if ( nextNextIndexPath.row >= changeSessionVideoCount ) {
					self.nextNextIndexPath = nil;
				}
			} else if ( [indexPath isEqual:nextNextIndexPath] ) {
				if ( nextNextIndexPath.row >= changeSessionVideoCount ) {
					if ( changeSessionVideoCount > 2 && changeSessionVideoCount - 1 != nextIndexPath.row ) {
						self.nextNextIndexPath = [NSIndexPath indexPathForRow:changeSessionVideoCount - 1 inSection:0];
					} else {
						self.nextNextIndexPath = nil;
					}
				}
			} else if ( indexPath.row < currentIndexPath.row ) {
				if ( previousIndexPath.row <= indexPath.row ) {
					if ( indexPath.row > 0 ) {
						if ( indexPath.row - 1 < changeSessionVideoCount ) {
							self.previousIndexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:0];
							self.currentIndexPath = indexPath;
						} else {
							self.previousIndexPath = nil;
							self.currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
						}
					} else {
						self.previousIndexPath = nil;
						self.currentIndexPath = indexPath;
					}
					if ( currentIndexPath.row + 1 < changeSessionVideoCount ) {
						self.nextIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row + 1 inSection:0];
					} else {
						self.nextIndexPath = nil;
					}
					if ( currentIndexPath.row + 2 < changeSessionVideoCount ) {
						self.nextNextIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row + 2 inSection:0];
					} else {
						self.nextNextIndexPath = nil;
					}
				}
				// flag that we have encountered some older videos
//				deletedOlderVideos = YES;
//				videoEncounteredBitArray = 0xff;
			}
			// issue reset Movie detail view
			deletedOlderVideos = YES;
			break;
		}
		case NSFetchedResultsChangeUpdate:
		case NSFetchedResultsChangeMove:
			break;
			
		case NSFetchedResultsChangeInsert:
		{
			rowCountHasChanged = YES;
//			NMVideo * vid = (NMVideo *)anObject;
//			vid.nm_sort_order = [NSNumber numberWithInteger:newIndexPath.row];
			if ( currentIndexPath == nil && newIndexPath.row == 0 ) {
				// inserting the first video
				self.currentIndexPath = newIndexPath;
				self.currentVideo = (NMVideo *)anObject;
				[dataDelegate didLoadCurrentVideoManagedObjectForController:self];
				
				// insert the next and next next video in this call too. If subsequent call for indexPath of next or next next video happens, we will not insert the same video again. 
				if ( nextIndexPath == nil && newIndexPath.row + 1 < changeSessionVideoCount ) {
					// check if we should add tne next video too
					self.nextIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row + 1 inSection:0];
					self.nextVideo = [controller objectAtIndexPath:nextIndexPath];
					[dataDelegate didLoadNextVideoManagedObjectForController:self];
				}
				
				if ( nextNextIndexPath == nil && newIndexPath.row + 2 < changeSessionVideoCount ) {
					self.nextNextIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row + 2 inSection:0];
					self.nextNextVideo = [controller objectAtIndexPath:nextNextIndexPath];
					[dataDelegate didLoadNextNextVideoManagedObjectForController:self];
					// no need to set movie detail view for "next next video". 
				}
			} else if ( nextIndexPath == nil && currentIndexPath && newIndexPath.row == currentIndexPath.row + 1) {
				self.nextIndexPath = newIndexPath;
				self.nextVideo = (NMVideo *)anObject;
				[dataDelegate didLoadNextVideoManagedObjectForController:self];
				
 				if ( nextNextIndexPath == nil && newIndexPath.row + 1 < changeSessionVideoCount ) {
					self.nextNextIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row + 1 inSection:0];
					self.nextNextVideo = [controller objectAtIndexPath:nextNextIndexPath];
					[dataDelegate didLoadNextNextVideoManagedObjectForController:self];
				}
			} else if ( nextNextIndexPath == nil && nextIndexPath && newIndexPath.row == nextIndexPath.row + 1 ) {
				// need to put the new object
				self.nextNextIndexPath = newIndexPath;
				self.nextNextVideo = (NMVideo *)anObject;
				[dataDelegate didLoadNextNextVideoManagedObjectForController:self];
			}
			break;
		}
			
		default:
			break;
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	if ( rowCountHasChanged ) {
		if ( deletedOlderVideos ) {
			// delay delete in this "did change content" method. This avoid all the hiccups when handling delete on-the-fly.
			NMVideo * fetchedVideo;
			if ( previousIndexPath ) {
				fetchedVideo = [controller objectAtIndexPath:previousIndexPath];
				if ( ![fetchedVideo isEqual:previousVideo] ) {
					self.previousVideo = fetchedVideo;
				}
				[dataDelegate didLoadPreviousVideoManagedObjectForController:self];
			} else {
				self.previousVideo = nil;
			}
			// get the current index path
			if ( currentIndexPath ) {
				fetchedVideo = [controller objectAtIndexPath:currentIndexPath];
				if ( ![fetchedVideo isEqual:currentVideo] ) {
					self.currentVideo = fetchedVideo;
				}
				[dataDelegate didLoadCurrentVideoManagedObjectForController:self];
			} else {
				self.currentVideo = nil;
			}
			if ( nextIndexPath ) {
				fetchedVideo = [controller objectAtIndexPath:nextIndexPath];
				if ( ![fetchedVideo isEqual:nextVideo] ) {
					self.nextVideo = fetchedVideo;
				}
				[dataDelegate didLoadNextVideoManagedObjectForController:self];
			} else {
				self.nextVideo = nil;
			}
			if ( nextNextIndexPath ) {
				fetchedVideo = [controller objectAtIndexPath:nextNextIndexPath];
				if ( ![fetchedVideo isEqual:nextNextVideo] ) {
					self.nextNextVideo = fetchedVideo;
				}
				[dataDelegate didLoadNextNextVideoManagedObjectForController:self];
			} else {
				self.nextNextVideo = nil;
			}
		}
		numberOfVideos = changeSessionVideoCount;
		[dataDelegate controller:self didUpdateVideoListWithTotalNumberOfVideo:numberOfVideos];
		//TODO: do we need to update the caching variables - currentIndexPath, currentVideo, etc
		if ( numberOfVideos < 5 ) {
			// fetch more video
			[nowboxTaskController issueGetMoreVideoForChannel:channel];
		}
	}
	rowCountHasChanged = NO;
}

#pragma mark Debug message
- (void)printDebugMessage:(NSString *)str {
//	debugMessageView.text = [debugMessageView.text stringByAppendingFormat:@"\n%@", str];
//	[debugMessageView scrollRangeToVisible:NSMakeRange([debugMessageView.text length], 0)];
}

@end
