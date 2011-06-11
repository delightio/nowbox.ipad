//
//  VideoPlaybackModelController.m
//  ipad
//
//  Created by Bill So on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "VideoPlaybackModelController.h"
#import "NMVideo.h"
#import "NMChannel.h"

static VideoPlaybackModelController * sharedVideoPlaybackModelController_ = nil;

@interface VideoPlaybackModelController (PrivateMethods)

- (void)initializePlayHead;
- (void)requestResolveVideo:(NMVideo *)vid;
	
@end

@implementation VideoPlaybackModelController

@synthesize currentIndexPath, previousIndexPath, nextIndexPath, nextNextIndexPath;
@synthesize currentVideo, nextVideo, nextNextVideo, previousVideo;
@synthesize channel, dataDelegate;
@synthesize fetchedResultsController, managedObjectContext;
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
	[fetchedResultsController release];
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
	// 1. NO video at all
	// 2. Just video list, haven't yet resolved the direct URL
	// 3. All info ready
	
	// case 1
	if ( channel.videos == nil || [channel.videos count] == 0 ) {
		
	} else {
		[self initializePlayHead];
		// case 2
		// case 3
	}
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
		self.nextIndexPath = [NSIndexPath indexPathForRow:2 inSection:0];
		self.nextVideo = [self.fetchedResultsController objectAtIndexPath:nextNextIndexPath];
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
		} else {
			self.nextNextIndexPath = nil;
			self.nextNextVideo = nil;
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
	if ( vid.nm_direct_url == nil || [vid.nm_direct_url isEqualToString:@""] ) {
		if ( vid.nm_playback_status == NMVideoQueueStatusNone ) {
			vid.nm_playback_status = NMVideoQueueStatusResolvingDirectURL;
			[nowmovTaskController issueGetDirectURLForVideo:vid];
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

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	switch (type) {
		case NSFetchedResultsChangeDelete:
			rowCountHasChanged = YES;
			//MARK: code below seems useless base on findings studying FRCDeleteTest sample code
			//			NMVideo * vid = (NMVideo *)anObject;
			//			// setting nm_sort_order will trigger another call to the FRC's delegate method
			//			vid.nm_sort_order = [NSNumber numberWithInteger:newIndexPath.row];
			//			// check if the new position makes the video become ready to be queued
			//			if ( currentIndex + 2 >= indexPath.row ) {
			//				[self configureControlViewAtIndex:indexPath.row];
			//				[self requestAddVideoAtIndex:indexPath.row];
			//				if ( currentIndex == 0 && vid.nm_playback_status == NMVideoQueueStatusDirectURLReady && movieView.player == nil ) {
			//					// we should start playing the video
			//					[self preparePlayer];
			//				}
			//			}
			break;
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
		//TODO: do we need to update the caching variables - currentIndexPath, currentVideo, etc
	}
	
//	if ( freshStart ) {
//		if ( numberOfVideos == 0 ) {
//			return;
//		}
//		
//		// launching the app with empty video list.
//		[nowmovTaskController issueGetVideoListForChannel:channel];
//		// now, get the direct url for some videos
//		[self requestAddVideoAtIndex:currentIndex];
//		// purposely don't queue fetch direct URL for other video in the list to avoid too much network traffic. Delay this till the video starts playing
//		freshStart = NO;
//		//		isReloadWithData = YES;
//		[self configureControlViewAtIndex:currentIndex];
//	}
}


@end
