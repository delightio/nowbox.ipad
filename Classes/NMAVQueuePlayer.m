//
//  NMAVQueuePlayer.m
//  ipad
//
//  Created by Bill So on 6/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMAVQueuePlayer.h"
#import "NMAVPlayerItem.h"

#define NM_PLAYER_DELAY_REQUEST_DURATION	0.75f

@interface NMAVQueuePlayer (PrivateMethods)

- (void)requestResolveVideo:(NMVideo *)vid;
/*!
 Insert the video to the end of the playback queue. It does NOT trigger URL resolution request.
 */
- (void)insertVideoToEndOfQueue:(NMVideo *)vid;
- (BOOL)revertPreviousItem:(AVPlayerItem *)item;
- (void)queueVideo:(NMVideo *)vid;

@end

@implementation NMAVQueuePlayer
@synthesize playbackDelegate;

- (id)init {
	self = [super init];
	
	nowmovTaskController = [NMTaskQueueController sharedTaskQueueController];
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleDidGetDirectURLNotification:) name:NMDidGetYouTubeDirectURLNotification object:nil];
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void)insertVideoToEndOfQueue:(NMVideo *)vid {
	NMAVPlayerItem * item = [vid createPlayerItem];
	if ( item && [self canInsertItem:item afterItem:nil] ) {
		[playbackDelegate player:self observePlayerItem:item];
		
		[self insertItem:item afterItem:nil];
		vid.nm_playback_status = NMVideoQueueStatusQueued;
	}
	[item release];
}

#pragma mark Public interface
- (void)advanceToVideo:(NMVideo *)aVideo {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	AVPlayerItem * curItem = self.currentItem;
	if ( curItem == nil ) {
		// queue this item
		if ( aVideo.nm_playback_status > NMVideoQueueStatusResolvingDirectURL ) {
			[self insertVideoToEndOfQueue:aVideo];
		} else {
			[self performSelector:@selector(requestResolveVideo:) withObject:aVideo afterDelay:NM_PLAYER_DELAY_REQUEST_DURATION];
		}
	} else {
		[playbackDelegate player:self stopObservingPlayerItem:curItem];
		[self advanceToNextItem];
		[self play];
	}
	if ( [playbackDelegate nextVideoForPlayer:self] ) [self performSelector:@selector(requestResolveVideo:) withObject:[playbackDelegate nextVideoForPlayer:self] afterDelay:NM_PLAYER_DELAY_REQUEST_DURATION];
	if ( [playbackDelegate nextNextVideoForPlayer:self] ) [self performSelector:@selector(requestResolveVideo:) withObject:[playbackDelegate nextNextVideoForPlayer:self] afterDelay:NM_PLAYER_DELAY_REQUEST_DURATION];
}

- (void)revertToVideo:(NMVideo *)aVideo {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
		if ( aVideo.nm_playback_status < NMVideoQueueStatusResolvingDirectURL ) {
			// we need to resolve the direct URL
			[self performSelector:@selector(requestResolveVideo:) withObject:aVideo afterDelay:NM_PLAYER_DELAY_REQUEST_DURATION];
		} else {
			[self performSelector:@selector(delayedRevertToVideo:) withObject:aVideo afterDelay:NM_PLAYER_DELAY_REQUEST_DURATION];
		}
}

- (void)resolveAndQueueVideos:(NSArray *)vidAy {
	for (NMVideo * theVideo in vidAy) {
		[self requestResolveVideo:theVideo];
	}
}

- (void)resolveAndQueueVideo:(NMVideo *)vid {
	[self performSelector:@selector(requestResolveVideo:) withObject:vid afterDelay:NM_PLAYER_DELAY_REQUEST_DURATION];
}

#pragma mark Video Switching
- (void)delayedRevertToVideo:(NMVideo *)aVideo {
	NMAVPlayerItem * item = [aVideo createPlayerItem];
	if ( [self revertPreviousItem:item] ) {
		aVideo.nm_playback_status = NMVideoQueueStatusQueued;
	}
}

- (BOOL)revertPreviousItem:(AVPlayerItem *)anItem {
	// move back to the previous item
	AVPlayerItem * cItem = [self.currentItem retain];
	BOOL insertStatus = NO;
	if ( [self canInsertItem:anItem afterItem:cItem] ) {
		[playbackDelegate player:self observePlayerItem:anItem];
		[self insertItem:anItem afterItem:cItem];
		[self advanceToNextItem];
		[self play];
		if ( [self canInsertItem:cItem afterItem:self.currentItem] ) {
#ifdef DEBUG_PLAYER_NAVIGATION
			NSLog(@"re-insert original item back to the queue player");
#endif
			[self insertItem:cItem afterItem:self.currentItem];
			insertStatus = YES;
		} else {
#ifdef DEBUG_PLAYER_NAVIGATION
			NSLog(@"CANNOT insert back");
#endif
		}
	}
	[cItem release];
	return insertStatus;
}

- (void)requestResolveVideo:(NMVideo *)vid {
	NSLog(@"issue resolution request - %@", vid.title);
	if ( vid == nil ) return;
	// request to resolve the direct URL of this video
	if ( vid.nm_playback_status == NMVideoQueueStatusNone ) {
		vid.nm_playback_status = NMVideoQueueStatusResolvingDirectURL;
		[nowmovTaskController issueGetDirectURLForVideo:vid];
	} else if ( vid.nm_playback_status > NMVideoQueueStatusResolvingDirectURL ) {
		[self queueVideo:vid];
		if ( vid == [playbackDelegate currentVideoForPlayer:self] ) {
			[playbackDelegate player:self willBeginPlayingVideo:vid];
		}
	}
	// task queue controller will check if there's an existing task for this
	
}

- (void)queueVideo:(NMVideo *)vid {
	/*!
	 check if we should queue video when we model controller informs about direct URL resolved. Similar operation is carried when user flick the screen.
	 */
	//	if ( movieView.player == nil ) {
	//		return;
	//		// return immediately. the "shouldBeginPlayingVideo" delegate method will be called.
	//	}
	NSArray * queuedItems = [self items];
	NSUInteger c = [queuedItems count];
	NMVideo * otherVideo;
	
	switch (c) {
		case 0:
		{
			// the queue player is currently empty. we should queue the current video and start playing it.
			if ( vid == [playbackDelegate currentVideoForPlayer:self] ) {
				// play the video
				[self insertVideoToEndOfQueue:vid];
				[self play];
				// insert other videos
				otherVideo = [playbackDelegate nextVideoForPlayer:self];
				if ( otherVideo.nm_playback_status > NMVideoQueueStatusResolvingDirectURL ) {
					[self insertVideoToEndOfQueue:otherVideo];
					
					otherVideo = [playbackDelegate nextNextVideoForPlayer:self];
					if ( otherVideo.nm_playback_status > NMVideoQueueStatusResolvingDirectURL ) {
						[self insertVideoToEndOfQueue:otherVideo];
					}
				}
			}
			break;
		}
		case 1:
		{
			if ( vid == [playbackDelegate currentVideoForPlayer:self] ) {
				if ( [self revertPreviousItem:[vid createPlayerItem]] ) {
					vid.nm_playback_status = NMVideoQueueStatusQueued;
				}
				// check if we need to dequeue other items
				NMAVPlayerItem * otherItem = [queuedItems objectAtIndex:0];
				if ( otherItem.nmVideo != [playbackDelegate nextVideoForPlayer:self] ) {
					// remove
					[playbackDelegate player:self stopObservingPlayerItem:otherItem];
					[self removeItem:otherItem];
				}
			} else if ( vid == [playbackDelegate nextVideoForPlayer:self] ) {
				// there's already a video in the queue. That's the current item. We will queue next and next next video into the queue if available
				[self insertVideoToEndOfQueue:vid];
				
				otherVideo = [playbackDelegate nextNextVideoForPlayer:self];
				if ( otherVideo.nm_playback_status > NMVideoQueueStatusResolvingDirectURL ) {
					[self insertVideoToEndOfQueue:otherVideo];
				}
			}
			break;
		}
		case 2:
		{
			if ( vid == [playbackDelegate currentVideoForPlayer:self] ) {
				// we wanna play the current video while there's already videos in the queue. This indicates user has scrolled back to the previous video
				if ( [self revertPreviousItem:[vid createPlayerItem]] ) {
					vid.nm_playback_status = NMVideoQueueStatusQueued;
				}
				// check if we need to dequeue other items
				NMAVPlayerItem * otherItem = [queuedItems objectAtIndex:0];
				if ( otherItem.nmVideo != [playbackDelegate nextVideoForPlayer:self] ) {
					// remove
					[playbackDelegate player:self stopObservingPlayerItem:otherItem];
					[self removeItem:otherItem];
				}
				otherItem = [queuedItems objectAtIndex:1];
				if ( otherItem.nmVideo != [playbackDelegate nextNextVideoForPlayer:self] ) {
					// remove
					[playbackDelegate player:self stopObservingPlayerItem:otherItem];
					[self removeItem:otherItem];
				}
			} else if ( vid == [playbackDelegate nextNextVideoForPlayer:self] ) {
				// there are 2 videos queued. Queue the next next video
				[self insertVideoToEndOfQueue:vid];
			}
			break;
		}
		case 3:
		{
			// check if the video is before or after the current set of video. Only queue video to the front of the player for this case
			if ( vid == [playbackDelegate currentVideoForPlayer:self] ) {
//				NMVideo * nVid = ((NMAVPlayerItem *)self.currentItem).nmVideo;
//				NSComparisonResult crs = [nVid.nm_fetch_timestamp compare:vid.nm_fetch_timestamp];
//				if ( crs == NSOrderedDescending || (crs == NSOrderedSame && [nVid.nm_sort_order compare:vid.nm_sort_order] == NSOrderedDescending) ) {
				// vid is before the nVid
				if ( [self revertPreviousItem:[vid createPlayerItem]] ) {
					vid.nm_playback_status = NMVideoQueueStatusQueued;
					// remove the last item in the queue player
					
				}
				// check if we need to remove any item
				NMAVPlayerItem * otherItem = [queuedItems objectAtIndex:0];
				if ( otherItem.nmVideo != [playbackDelegate nextVideoForPlayer:self] ) {
					// remove
					[playbackDelegate player:self stopObservingPlayerItem:otherItem];
					[self removeItem:otherItem];
				}
				otherItem = [queuedItems objectAtIndex:1];
				if ( otherItem.nmVideo != [playbackDelegate nextNextVideoForPlayer:self] ) {
					// remove
					[playbackDelegate player:self stopObservingPlayerItem:otherItem];
					[self removeItem:otherItem];
				}
				otherItem = [queuedItems objectAtIndex:2];
				[playbackDelegate player:self stopObservingPlayerItem:otherItem];
				[self removeItem:otherItem];
//				}
			}
			break;
		}
		default:
			break;
	}
}

#pragma mark Notification Handler
- (void)handleDidGetDirectURLNotification:(NSNotification *)aNotification {
	NMVideo * vid = [[aNotification userInfo] objectForKey:@"target_object"];
	vid.nm_playback_status = NMVideoQueueStatusDirectURLReady;
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"resolved: %@", vid.title);
#endif
	[self queueVideo:vid];
	if ( vid == [playbackDelegate currentVideoForPlayer:self] ) {
		[playbackDelegate player:self willBeginPlayingVideo:vid];
		[self play];
	}
}

@end
