//
//  VideoPlaybackModelController.m
//  ipad
//
//  Created by Bill So on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "VideoPlaybackModelController.h"
#import "NMMovieDetailView.h"
#import "NMVideo.h"
#import "NMChannel.h"

#define NM_MAX_VIDEO_IN_QUEUE				3
#define NM_NMVIDEO_CACHE_SIZE				5

static VideoPlaybackModelController * sharedVideoPlaybackModelController_ = nil;
NSString * const NMWillBeginPlayingVideoNotification = @"NMWillBeginPlayingVideoNotification";

@interface VideoPlaybackModelController (PrivateMethods)

- (void)initializePlayHead;
	
@end

@implementation VideoPlaybackModelController

@synthesize currentIndexPath, previousIndexPath, nextIndexPath, nextNextIndexPath;
@synthesize currentVideo, nextVideo, nextNextVideo, previousVideo;
@synthesize channel, dataDelegate;
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
	nowmovTaskController = [NMTaskQueueController sharedTaskQueueController];
	
	// listen to notification
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleDidGetVideoListNotification:) name:NMDidGetChannelVideoListNotification object:nil];
	[nc addObserver:self selector:@selector(handleErrorNotification:) name:NMDidFailGetYouTubeDirectURLNotification object:nil];
	[nc addObserver:self selector:@selector(handleErrorNotification:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
	[nc addObserver:self selector:@selector(handleErrorNotification:) name:NMURLConnectionErrorNotification object:nil];

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
			channel = [aChn retain];
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
	
	// 3 possible cases:
	// check if videos exists
	// check if last video exists
	// check if we need to get video list
	
	id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
	numberOfVideos = [sectionInfo numberOfObjects];
	// check if there's video to play
	if ( numberOfVideos ) {
		// check if we need to go back to the last video
		if ( aChn.nm_last_vid ) {
			NSFetchRequest * request = [[NSFetchRequest alloc] init];
			[request setEntity:[NSEntityDescription entityForName:NMVideoEntityName inManagedObjectContext:self.managedObjectContext]];
			[request setPredicate:[NSPredicate predicateWithFormat:@"nm_id == %@ AND nm_error == 0", aChn.nm_last_vid]];
			[request setReturnsObjectsAsFaults:NO];
			NSArray * result = [self.managedObjectContext executeFetchRequest:request error:nil];
			[request release];
			if ( result && [result count] ) {
				// we can find the last watched video.
				self.currentIndexPath = [self.fetchedResultsController indexPathForObject:[result objectAtIndex:0]];
				self.currentVideo = [result objectAtIndex:0];
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
		} else {
			[self initializePlayHead];
		}
	} else {
		self.previousVideo = nil;
		self.previousIndexPath = nil;
		self.currentIndexPath = nil;
		self.currentVideo = nil;
		self.nextIndexPath = nil;
		self.nextVideo = nil;
		self.nextNextIndexPath = nil;
		self.nextNextVideo = nil;
	}
	// check if we need to download more. Or, in the case where there's no video, download
	if ( numberOfVideos == 0 || currentIndexPath.row + NM_NMVIDEO_CACHE_SIZE > numberOfVideos) {
		// download more video from Nowmov
		[nowmovTaskController issueGetVideoListForChannel:channel];
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
	
	// untether NMVideo object from movie detail view object
	if ( previousVideo ) {
		previousVideo.nm_movie_detail_view.video = nil;
		previousVideo.nm_movie_detail_view = nil;
	}
	if ( currentVideo ) {
		currentVideo.nm_movie_detail_view.video = nil;
		currentVideo.nm_movie_detail_view = nil;
	}
	if ( nextVideo ) {
		nextVideo.nm_movie_detail_view.video = nil;
		nextVideo.nm_movie_detail_view = nil;
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
		[nowmovTaskController issueGetVideoListForChannel:channel];
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
	
	// we can advance forward
	NMMovieDetailView * detailView = self.previousVideo.nm_movie_detail_view;
	detailView.video = nil;
	self.previousVideo.nm_movie_detail_view = nil;
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
		[nowmovTaskController issueGetVideoListForChannel:channel];
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
	NMMovieDetailView * detailView = nil;
	if ( nextVideo ) {
		detailView = nextVideo.nm_movie_detail_view;
		detailView.video = nil;
		nextVideo.nm_movie_detail_view = nil;
	}
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


#pragma mark Notification handlers

- (void)handleErrorNotification:(NSNotification *)aNotification {
	if ( [[aNotification name] isEqualToString:NMURLConnectionErrorNotification] ) {
		// general network error. 
#ifdef DEBUG_PLAYER_DEBUG_MESSAGE
		debugMessageView.text = [debugMessageView.text stringByAppendingFormat:@"\n%@", [[aNotification userInfo] objectForKey:@"message"]];
		NSLog(@"general connection error: %@", [[aNotification userInfo] objectForKey:@"message"]);
#endif
	} else if ( [[aNotification name] isEqualToString:AVPlayerItemFailedToPlayToEndTimeNotification] ) {
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

- (void)handleDidGetVideoListNotification:(NSNotification *)aNotification {
	// MOC changes were made where notification is received
	NSDictionary * userInfo = [aNotification userInfo];
	NMChannel * srcChannel = [userInfo objectForKey:@"channel"];
	NSInteger numVideo = [[userInfo objectForKey:@"num_video_added"] integerValue];
	if ( srcChannel == channel && numVideo == 0 ) {
		// we can't get any new video from the server. try getting by doubling the count
		NSUInteger vidReq = [[userInfo objectForKey:@"num_video_requested"] unsignedIntegerValue];
		if ( vidReq < 41 ) {
			[nowmovTaskController issueGetVideoListForChannel:channel numberOfVideos:vidReq * 2];
		} else {
			// we have finish up this channel
		}
	} 
}

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
	
	// Make sure the condition here - predicate and sort order is EXACTLY the same as in deleteVideoInChannel:afterVideo: in data controller!!!
	// set predicate
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"channel == %@ AND nm_error == 0", channel]];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:10];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:YES];
	NSSortDescriptor * timestampDesc = [[NSSortDescriptor alloc] initWithKey:@"nm_fetch_timestamp" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:timestampDesc, sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"VideoPlaybackModel"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [fetchRequest release];
    [sortDescriptor release];
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
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	static NSUInteger theCount = 0;
	if ( changeSessionUpdateCount ) {
		// just get the count once is enough
		changeSessionUpdateCount = NO;
		id <NSFetchedResultsSectionInfo> sectionInfo = [[controller sections] objectAtIndex:0];
		theCount = [sectionInfo numberOfObjects];
	}
	switch (type) {
		case NSFetchedResultsChangeDelete:
		{
			rowCountHasChanged = YES;
			NMVideo * fetchedVideo;
			if ( [indexPath isEqual:currentIndexPath] ) {
				if ( indexPath.row < theCount ) {
					// reset the movie detail view
					currentVideo.nm_movie_detail_view.video = nil;
					self.currentVideo = [controller objectAtIndexPath:indexPath];
					// info the delegate about the current video change
					[dataDelegate didLoadCurrentVideoManagedObjectForController:self];
					
					// do NOT use nextIndexPath to check the condition
					if ( indexPath.row + 1 < theCount ) {
						self.nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:0];
						fetchedVideo = [controller objectAtIndexPath:nextIndexPath];
						if ( nextVideo != fetchedVideo ) {
							self.nextVideo = fetchedVideo;
							// do not reset nextVideo's detail view. cos we don't have enough info here to determine nextVideo is invalid
							[dataDelegate didLoadNextVideoManagedObjectForController:self];
						}
						
						// do NOT use nextNextIndexPath to check the condition
						if ( indexPath.row + 2 < theCount ) {
							self.nextNextIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 2 inSection:0];
							fetchedVideo = [controller objectAtIndexPath:nextNextIndexPath];
							if ( nextNextVideo != fetchedVideo ) {
								self.nextNextVideo = fetchedVideo;
								[dataDelegate didLoadNextNextVideoManagedObjectForController:self];
							}
						} else {
							self.nextNextVideo = nil;
							self.nextNextIndexPath = nil;
						}
					} else {
						self.nextVideo = nil;
						self.nextIndexPath = nil;
						
						self.nextNextVideo = nil;
						self.nextNextIndexPath = nil;
					}
				} else {
					self.currentVideo = nil;
					self.currentIndexPath = nil;
					
					self.nextVideo = nil;
					self.nextIndexPath = nil;
					
					self.nextNextVideo = nil;
					self.nextNextIndexPath = nil;
				}
			} else if ( [indexPath isEqual:nextIndexPath] ) {
				if ( nextIndexPath.row < theCount ) {
					nextVideo.nm_movie_detail_view.video = nil;
					self.nextVideo = [controller objectAtIndexPath:nextIndexPath];
					[dataDelegate didLoadNextVideoManagedObjectForController:self];
					if ( indexPath.row + 1 < theCount ) {
						self.nextNextIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:0];
						fetchedVideo = [controller objectAtIndexPath:nextNextIndexPath];
						if ( fetchedVideo != nextNextVideo ) {
							self.nextNextVideo = [controller objectAtIndexPath:nextNextIndexPath];
							[dataDelegate didLoadNextNextVideoManagedObjectForController:self];
						}
					} else {
						self.nextNextVideo = nil;
						self.nextNextIndexPath = nil;
					}
				} else {
					self.nextVideo = nil;
					self.nextIndexPath = nil;
					
					self.nextNextVideo = nil;
					self.nextNextIndexPath = nil;
				}
			} else if ( [indexPath isEqual:nextNextIndexPath] ) {
				if ( nextNextIndexPath.row < theCount ) {
					self.nextNextVideo = [controller objectAtIndexPath:nextNextIndexPath];
					[dataDelegate didLoadNextNextVideoManagedObjectForController:self];
					// no need to set movie detail view for next next video
				} else {
					self.nextNextVideo = nil;
					self.nextNextIndexPath = nil;
				}
			}
			// issue reset Movie detail view
			break;
		}
		case NSFetchedResultsChangeUpdate:
		case NSFetchedResultsChangeMove:
			rowCountHasChanged = NO;
			break;
			
		case NSFetchedResultsChangeInsert:
		{
			rowCountHasChanged = YES;
			NMVideo * vid = (NMVideo *)anObject;
			vid.nm_sort_order = [NSNumber numberWithInteger:newIndexPath.row];
			if ( currentIndexPath == nil && newIndexPath.row == 0 ) {
				// inserting the first video
				self.currentIndexPath = newIndexPath;
				self.currentVideo = (NMVideo *)anObject;
				[dataDelegate didLoadCurrentVideoManagedObjectForController:self];
				
				// insert the next and next next video in this call too. If subsequent call for indexPath of next or next next video happens, we will not insert the same video again. 
				if ( nextIndexPath == nil && newIndexPath.row + 1 < theCount ) {
					// check if we should add tne next video too
					self.nextIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row + 1 inSection:0];
					self.nextVideo = [controller objectAtIndexPath:nextIndexPath];
					[dataDelegate didLoadNextVideoManagedObjectForController:self];
				}
				
				if ( nextNextIndexPath == nil && newIndexPath.row + 2 < theCount ) {
					self.nextNextIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row + 2 inSection:0];
					self.nextNextVideo = [controller objectAtIndexPath:nextNextIndexPath];
					[dataDelegate didLoadNextNextVideoManagedObjectForController:self];
					// no need to set movie detail view for "next next video". 
				}
			} else if ( nextIndexPath == nil && currentIndexPath && newIndexPath.row == currentIndexPath.row + 1) {
				self.nextIndexPath = newIndexPath;
				self.nextVideo = (NMVideo *)anObject;
				[dataDelegate didLoadNextVideoManagedObjectForController:self];
				
 				if ( nextNextIndexPath == nil && newIndexPath.row + 1 < theCount ) {
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
		id <NSFetchedResultsSectionInfo> sectionInfo = [[controller sections] objectAtIndex:0];
		numberOfVideos = [sectionInfo numberOfObjects];
		[dataDelegate controller:self didUpdateVideoListWithTotalNumberOfVideo:numberOfVideos];
		//TODO: do we need to update the caching variables - currentIndexPath, currentVideo, etc
		if ( numberOfVideos < 5 ) {
			// fetch more video
			[nowmovTaskController issueGetVideoListForChannel:channel numberOfVideos:5];
		}
	}
	changeSessionUpdateCount = NO;
}

#pragma mark Debug message
- (void)printDebugMessage:(NSString *)str {
	debugMessageView.text = [debugMessageView.text stringByAppendingFormat:@"\n%@", str];
	[debugMessageView scrollRangeToVisible:NSMakeRange([debugMessageView.text length], 0)];
}

@end
