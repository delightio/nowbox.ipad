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
#define NM_NMVIDEO_CACHE_SIZE				4

static VideoPlaybackModelController * sharedVideoPlaybackModelController_ = nil;

@interface VideoPlaybackModelController (PrivateMethods)

- (void)initializePlayHead;
- (void)requestResolveVideo:(NMVideo *)vid;
	
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
	[nc addObserver:self selector:@selector(handleDidGetDirectURLNotification:) name:NMDidGetYouTubeDirectURLNotification object:nil];
	[nc addObserver:self selector:@selector(handleDidGetVideoListNotification:) name:NMDidGetChannelVideoListNotification object:nil];
	[nc addObserver:self selector:@selector(handleDidGetVideoListNotification:) name:NMDidRefreshChannelVideoListNotification object:nil];
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
		return;
		// return
	}
	
	// 3 possible cases:
	// check if videos exists
	// check if last video exists
	// check if we need to get video list
	
	numberOfVideos = [channel.videos count];
	// check if there's video to play
	if ( numberOfVideos ) {
		// check if we need to go back to the last video
		if ( aChn.nm_last_vid ) {
			NSFetchRequest * request = [[NSFetchRequest alloc] init];
			[request setEntity:[NSEntityDescription entityForName:NMVideoEntityName inManagedObjectContext:self.managedObjectContext]];
			[request setPredicate:[NSPredicate predicateWithFormat:@"vid = %@", aChn.nm_last_vid]];
			[request setReturnsObjectsAsFaults:NO];
			NSArray * result = [self.managedObjectContext executeFetchRequest:request error:nil];
			[request release];
			if ( result && [result count] ) {
				// we can find the last watched video.
				self.currentIndexPath = [self.fetchedResultsController indexPathForObject:[result objectAtIndex:0]];
				self.currentVideo = [result objectAtIndex:0];
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
				NSLog(@"last viewed title: %@", self.currentVideo.title);
#endif
				[self requestResolveVideo:currentVideo];
				// init the playhead. sth similar to initializePlayHead
				if ( currentIndexPath.row + 1 < numberOfVideos ) {
					self.nextIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row + 1 inSection:0];
					self.nextVideo = [self.fetchedResultsController objectAtIndexPath:nextIndexPath];
					[self requestResolveVideo:nextVideo];
				}
				if ( currentIndexPath.row + 2 < numberOfVideos ) {
					self.nextNextIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row + 2 inSection:0];
					self.nextNextVideo = [self.fetchedResultsController objectAtIndexPath:nextNextIndexPath];
					[self requestResolveVideo:nextNextVideo];
				}
				if ( currentIndexPath.row - 1 > -1 ) {
					self.previousIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row - 1 inSection:0];
					self.previousVideo = [self.fetchedResultsController objectAtIndexPath:self.previousIndexPath];
					[self requestResolveVideo:previousVideo];
				}
			} else {
				// we can't find the video from the vid stored. Start playing from the first video in the channel
				[self initializePlayHead];
				[self requestResolveVideo:previousVideo];
				[self requestResolveVideo:currentVideo];
				[self requestResolveVideo:nextVideo];
				[self requestResolveVideo:nextNextVideo];
			}
		} else {
			[self initializePlayHead];
			[self requestResolveVideo:previousVideo];
			[self requestResolveVideo:currentVideo];
			[self requestResolveVideo:nextVideo];
			[self requestResolveVideo:nextNextVideo];
		}
	}
	// check if we need to download more. Or, in the case where there's no video, download
	if ( numberOfVideos == 0 || numberOfVideos < NM_NMVIDEO_CACHE_SIZE ) {
		// download more video from Nowmov
		[nowmovTaskController issueGetVideoListForChannel:channel];
	}
	[dataDelegate controller:self didUpdateVideoListWithTotalNumberOfVideo:numberOfVideos];
}

#pragma mark Video list management

- (void)initializePlayHead {
	self.currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	self.currentVideo = [self.fetchedResultsController objectAtIndexPath:currentIndexPath];
	if ( numberOfVideos > 1 ) {
		self.nextIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
		self.nextVideo = [self.fetchedResultsController objectAtIndexPath:nextIndexPath];
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
	if ( currentIndexPath.row < numberOfVideos ) {
		// we can advance forward
		// purge next video path
		self.previousIndexPath = currentIndexPath;
		self.currentIndexPath = nextIndexPath;
		// video
		self.previousVideo = currentVideo;
		self.currentVideo = nextVideo;
		if ( nextIndexPath.row < numberOfVideos ) {
			self.nextIndexPath = [NSIndexPath indexPathForRow:nextIndexPath.row + 1 inSection:0];
			self.nextVideo = [self.fetchedResultsController objectAtIndexPath:nextIndexPath];
		} else {
			self.nextIndexPath = nil;
			self.nextVideo = nil;
		}
		if ( nextNextIndexPath.row < numberOfVideos ) {
			self.nextNextIndexPath = [NSIndexPath indexPathForRow:nextNextIndexPath.row + 1 inSection:0];
			self.nextNextVideo = [self.fetchedResultsController objectAtIndexPath:nextNextIndexPath];
			[self requestResolveVideo:nextNextVideo];
		} else {
			self.nextNextIndexPath = nil;
			self.nextNextVideo = nil;
			// fetch more video
			[nowmovTaskController issueGetVideoListForChannel:channel];
		}
		
		return YES;
	}
	return NO;
}

- (BOOL)moveToPreviousVideo {
	if ( currentIndexPath.row ) {
		// purge the next video
		self.nextIndexPath = currentIndexPath;
		self.currentIndexPath = previousIndexPath;
		// videos
		self.nextVideo = currentVideo;
		self.currentVideo = previousVideo;
		if ( previousIndexPath.row ) {
			self.previousIndexPath = [NSIndexPath indexPathForRow:previousIndexPath.row - 1 inSection:0];
			// we can set the previous video
			self.previousVideo = [self.fetchedResultsController objectAtIndexPath:previousIndexPath];
			[self requestResolveVideo:previousVideo];
		} else {
			self.previousIndexPath = nil;
			self.previousVideo = nil;
		}
		return YES;
	}
	return NO;
}

#pragma mark Video queuing

- (void)requestResolveVideo:(NMVideo *)vid {
	if ( vid == nil ) return;
	// request to resolve the direct URL of this video
	if ( vid.nm_playback_status == NMVideoQueueStatusNone ) {
		vid.nm_playback_status = NMVideoQueueStatusResolvingDirectURL;
		[nowmovTaskController issueGetDirectURLForVideo:vid];
	} else if ( vid.nm_playback_status > NMVideoQueueStatusResolvingDirectURL ) {
		[dataDelegate controller:self didResolvedURLOfVideo:vid];
		if ( vid == currentVideo ) {
			[dataDelegate controller:self shouldBeginPlayingVideo:vid];
		}
	}
	// task queue controller will check if there's an existing task for this
	
}

#pragma mark Network related notifications
- (void)handleDidGetDirectURLNotification:(NSNotification *)aNotification {
	NMVideo * vid = [[aNotification userInfo] objectForKey:@"target_object"];
	vid.nm_playback_status = NMVideoQueueStatusDirectURLReady;
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"resolved: %@", vid.title);
#endif
#ifdef DEBUG_PLAYER_DEBUG_MESSAGE
	[self performSelectorOnMainThread:@selector(printDebugMessage:) withObject:[NSString stringWithFormat:@"resolved URL: %@", vid.title] waitUntilDone:NO];
#endif
	[dataDelegate controller:self didResolvedURLOfVideo:vid];
	if ( vid == currentVideo ) {
		[dataDelegate controller:self shouldBeginPlayingVideo:vid];
	}
}

- (void)handleErrorNotification:(NSNotification *)aNotification {
	NSDictionary * userInfo = [aNotification userInfo];
	if ( [[aNotification name] isEqualToString:NMDidFailGetYouTubeDirectURLNotification] ) {
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
		NSLog(@"direct URL resolution failed: %@", [userInfo objectForKey:@"error"]);
#endif
		// skip the video by marking the resolution status
		if ( userInfo ) {
			NMVideo * vid = [userInfo objectForKey:@"target_object"];
			vid.nm_error = [userInfo objectForKey:@"errorNum"];
			vid.nm_playback_status = NMVideoQueueStatusError;
			[nowmovTaskController issueReexamineVideo:vid errorCode:[vid.nm_error integerValue]];
#ifdef DEBUG_PLAYER_DEBUG_MESSAGE
			debugMessageView.text = [debugMessageView.text stringByAppendingFormat:@"\ndirect URL resolution failed: %@ %@", [[aNotification userInfo] objectForKey:@"error"], vid.title];
#endif
		}
	} else if ( [[aNotification name] isEqualToString:NMURLConnectionErrorNotification] ) {
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
	NSInteger numVideo = [[userInfo objectForKey:@"num_video_added"] integerValue];
	if ( numVideo == 0 ) {
		// we can't get any new video from the server. try getting by doubling the count
		NSUInteger vidReq = [[userInfo objectForKey:@"num_video_requested"] unsignedIntegerValue];
		if ( vidReq < 41 ) {
			[nowmovTaskController issueGetVideoListForChannel:channel numberOfVideos:vidReq * 2];
		} else {
			// we have finish up this channel
		}
	} else {
		// check if the new videos are in the play window. If so, get their direct URL
		if ( currentVideo == nil ) {
			// initial case
			[self initializePlayHead];
			[self requestResolveVideo:self.currentVideo];
			[self requestResolveVideo:self.nextVideo];
			[self requestResolveVideo:self.nextNextVideo];
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
    [fetchRequest setFetchBatchSize:5];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:YES];
	NSSortDescriptor * timestampDesc = [[NSSortDescriptor alloc] initWithKey:@"nm_fetch_timestamp" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:timestampDesc, sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
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
			if ( [indexPath isEqual:currentIndexPath] ) {
				if ( currentIndexPath.row + 1 < theCount ) {
					self.currentVideo = [controller objectAtIndexPath:indexPath];
					if ( nextIndexPath.row + 1 < theCount ) {
						self.nextVideo = [controller objectAtIndexPath:nextIndexPath];
						if ( nextNextIndexPath.row + 1 < theCount ) {
							self.nextNextVideo = [controller objectAtIndexPath:nextNextIndexPath];
						} else {
							self.nextNextVideo = nil;
							self.nextNextIndexPath = nil;
						}
					} else {
						self.nextVideo = nil;
						self.nextNextVideo = nil;
						self.nextIndexPath = nil;
						self.nextNextIndexPath = nil;
					}
				} else {
					// there's literally no need to do anything. no video is worth playing in this channel
					//MARK: fatal channel error?
					self.currentVideo = nil;
					self.nextVideo = nil;
					self.nextNextVideo = nil;
					self.currentIndexPath = nil;
					self.nextIndexPath = nil;
					self.nextNextIndexPath = nil;
				}
				[self requestResolveVideo:currentVideo];
				[self requestResolveVideo:nextVideo];
				[self requestResolveVideo:nextNextVideo];
			} else if ( [indexPath isEqual:nextIndexPath] ) {
				if ( nextIndexPath.row + 1 < theCount ) {
					self.nextVideo = [controller objectAtIndexPath:nextIndexPath];
					if ( nextNextIndexPath.row + 1 < theCount ) {
						self.nextNextVideo = [controller objectAtIndexPath:nextNextIndexPath];
					} else {
						self.nextNextVideo = nil;
						self.nextNextIndexPath = nil;
					}
				} else {
					self.nextVideo = nil;
					self.nextNextVideo = nil;
					self.nextIndexPath = nil;
					self.nextNextIndexPath = nil;
				}
				[self requestResolveVideo:nextVideo];
				[self requestResolveVideo:nextNextVideo];
			} else if ( [indexPath isEqual:nextNextIndexPath] ) {
				if ( nextNextIndexPath.row + 1 < theCount ) {
					self.nextNextVideo = [controller objectAtIndexPath:nextNextIndexPath];
				} else {
					self.nextNextVideo = nil;
					self.nextNextIndexPath = nil;
				}
				[self requestResolveVideo:nextNextVideo];
			}
			break;
		}
		case NSFetchedResultsChangeUpdate:
		case NSFetchedResultsChangeMove:
			rowCountHasChanged = NO;
			break;
			
		default:
		{
			rowCountHasChanged = YES;
			NMVideo * vid = (NMVideo *)anObject;
			vid.nm_sort_order = [NSNumber numberWithInteger:newIndexPath.row];
			break;
		}
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	if ( rowCountHasChanged ) {
		id <NSFetchedResultsSectionInfo> sectionInfo = [[controller sections] objectAtIndex:0];
		numberOfVideos = [sectionInfo numberOfObjects];
		[dataDelegate controller:self didUpdateVideoListWithTotalNumberOfVideo:numberOfVideos];
		//TODO: do we need to update the caching variables - currentIndexPath, currentVideo, etc
	}
	changeSessionUpdateCount = NO;
}

#pragma mark Debug message
- (void)printDebugMessage:(NSString *)str {
	debugMessageView.text = [debugMessageView.text stringByAppendingFormat:@"\n%@", str];
	[debugMessageView scrollRangeToVisible:NSMakeRange([debugMessageView.text length], 0)];
}

@end
