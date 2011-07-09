//
//  NMAVQueuePlayer.m
//  ipad
//
//  Created by Bill So on 6/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMAVQueuePlayer.h"

#define NM_PLAYER_DELAY_REQUEST_DURATION	0.75f

@interface NMAVQueuePlayer (PrivateMethods)

- (void)requestResolveVideo:(NMVideo *)vid;
/*!
 Insert the video to the end of the playback queue. It does NOT trigger URL resolution request.
 */
- (void)insertVideoToEndOfQueue:(NMVideo *)vid;
- (void)revertPreviousItem:(AVPlayerItem *)item;
- (void)queueVideo:(NMVideo *)vid;

@end

@implementation NMAVQueuePlayer
@synthesize playbackDelegate;

- (id)init {
	self = [super init];
	
	nowmovTaskController = [NMTaskQueueController sharedTaskQueueController];
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleDidGetDirectURLNotification:) name:NMDidGetYouTubeDirectURLNotification object:nil];
	[nc addObserver:self selector:@selector(handleErrorNotification:) name:NMDidFailGetYouTubeDirectURLNotification object:nil];
	
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
		[playbackDelegate observePlayerItem:item];
		
		[self insertItem:item afterItem:nil];
		vid.nm_playback_status = NMVideoQueueStatusQueued;
	}
	[item release];
}

- (NMAVPlayerItem *)advanceToVideo:(NMVideo *)aVideo {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	AVPlayerItem * curItem = self.currentItem;
	NMAVPlayerItem * item = nil;
	if ( curItem == nil ) {
		// queue this item
		item = [aVideo createPlayerItem];
		if ( item ) {
			// start observing the previous playback item. But do NOT remove the current item from being observed.
			if ( [self canInsertItem:item afterItem:curItem] ) {
				// set the video status
				aVideo.nm_playback_status = NMVideoQueueStatusQueued;
				[self insertItem:item afterItem:curItem];
				if ( curItem ) {
					[self advanceToNextItem];
				}
				[self play];
			}
			[item release];
		} else {
			// we need to resolve the direct URL
			[self performSelector:@selector(requestResolveVideo:) withObject:aVideo afterDelay:NM_PLAYER_DELAY_REQUEST_DURATION];
		}
	} else {
		[self advanceToNextItem];
		[self play];
	}
	[self performSelector:@selector(requestResolveVideo:) withObject:[playbackDelegate nextVideoForPlayer:self] afterDelay:NM_PLAYER_DELAY_REQUEST_DURATION];
	[self performSelector:@selector(requestResolveVideo:) withObject:[playbackDelegate nextNextVideoForPlayer:self] afterDelay:NM_PLAYER_DELAY_REQUEST_DURATION];
	return item;
}

- (NMAVPlayerItem *)revertToVideo:(NMVideo *)aVideo {
	aVideo.nm_playback_status = NMVideoQueueStatusQueued;
	return nil;
}

- (void)resolveAndQueueVideos:(NSArray *)vidAy {
	for (NMVideo * theVideo in vidAy) {
		[self requestResolveVideo:theVideo];
	}
}

- (void)resolveAndQueueVideo:(NMVideo *)vid {
	[self requestResolveVideo:vid];
}

#pragma Video Switching
- (void)revertPreviousItem:(AVPlayerItem *)anItem {
	// move back to the previous item
	AVPlayerItem * cItem = [self.currentItem retain];
	if ( [self canInsertItem:anItem afterItem:cItem] ) {
		[self insertItem:anItem afterItem:cItem];
		[self advanceToNextItem];
		if ( [self canInsertItem:cItem afterItem:self.currentItem] ) {
#ifdef DEBUG_PLAYER_NAVIGATION
			NSLog(@"re-insert original item back to the queue player");
#endif
			[self insertItem:cItem afterItem:self.currentItem];
		} else {
#ifdef DEBUG_PLAYER_NAVIGATION
			NSLog(@"CANNOT insert back");
#endif
		}
	}
	[cItem release];
}

- (void)requestResolveVideo:(NMVideo *)vid {
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
	NSUInteger c = [[self items] count];
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
			// there's already a video in the queue. That's the current item. We will queue next and next next video into the queue if available
			if ( vid == [playbackDelegate nextVideoForPlayer:self] ) {
				[self insertVideoToEndOfQueue:vid];
				
				otherVideo = [playbackDelegate nextNextVideoForPlayer:self];
				if ( otherVideo.nm_playback_status > NMVideoQueueStatusResolvingDirectURL ) {
					[self insertVideoToEndOfQueue:otherVideo];
				}
			}
		}
		case 2:
		{
			// there are 2 videos queued. Queue the next next video
			if ( vid == [playbackDelegate nextNextVideoForPlayer:self] ) {
				[self insertVideoToEndOfQueue:vid];
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
#ifdef DEBUG_PLAYER_DEBUG_MESSAGE
	[self performSelectorOnMainThread:@selector(printDebugMessage:) withObject:[NSString stringWithFormat:@"resolved URL: %@", vid.title] waitUntilDone:NO];
#endif
	[self queueVideo:vid];
	if ( vid == [playbackDelegate currentVideoForPlayer:self] ) {
		[playbackDelegate player:self willBeginPlayingVideo:vid];
	}
}

- (void)handleErrorNotification:(NSNotification *)aNotification {
	NSDictionary * userInfo = [aNotification userInfo];
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
}

@end
