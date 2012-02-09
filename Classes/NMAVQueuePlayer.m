//
//  NMAVQueuePlayer.m
//  ipad
//
//  Created by Bill So on 6/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMAVQueuePlayer.h"
#import "NMAVPlayerItem.h"

#define NM_PLAYER_DELAY_REQUEST_DURATION	0.75

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
	
	nowboxTaskController = [NMTaskQueueController sharedTaskQueueController];
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
		vid.video.nm_playback_status = NMVideoQueueStatusQueued;
	}
}

- (void)insertVideo:(NMVideo *)vid afterItem:(NMAVPlayerItem *)anItem {
	// insert the video and delete the item
	NMAVPlayerItem * targetItem = vid.video.nm_player_item;
	if ( targetItem == nil ) {
		targetItem = [vid createPlayerItem];
		if ( targetItem == nil ) return;
	}
	if ( [self canInsertItem:targetItem afterItem:anItem] ) {
		// insert after anItem
		[playbackDelegate player:self stopObservingPlayerItem:anItem];
		[playbackDelegate player:self observePlayerItem:targetItem];
		[self insertItem:targetItem afterItem:anItem];
		[self removeItem:anItem];
	} else {
		[playbackDelegate player:self stopObservingPlayerItem:anItem];
		[self removeItem:anItem];
	}
}

- (void)removeAllItems {
	// stop observing all items
	[self pause];
	NSArray * allItems = self.items;
	for (NMAVPlayerItem * anItem in allItems) {
		[playbackDelegate player:self stopObservingPlayerItem:anItem];
	}
	[super removeAllItems];
}

#pragma mark Public interface
- (void)advanceToVideo:(NMVideo *)aVideo {
	NMConcreteVideo * realVideo = aVideo.video;
#ifdef DEBUG_PLAYER_NAVIGATION
	NSLog(@"advanceToVideo: %@ %d %d - will delay call", realVideo.title, realVideo.nm_playback_status, self.currentItem == nil);
#endif
//	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	NMAVPlayerItem * curItem = (NMAVPlayerItem *)self.currentItem;
	if ( curItem == nil ) {
		// queue this item
		if ( realVideo.nm_playback_status > NMVideoQueueStatusResolvingDirectURL ) {
			[self insertVideoToEndOfQueue:aVideo];
		} else {
			[self performSelector:@selector(requestResolveVideo:) withObject:realVideo afterDelay:NM_PLAYER_DELAY_REQUEST_DURATION];
		}
	} else {
		[playbackDelegate player:self stopObservingPlayerItem:curItem];
		curItem.nmVideo.video.nm_player_item = nil;
		curItem.nmVideo = nil;
		[self advanceToNextItem];
		if ( realVideo.nm_playback_status > NMVideoQueueStatusResolvingDirectURL ) {
			[self play];
		} else {
			[self performSelector:@selector(requestResolveVideo:) withObject:realVideo afterDelay:NM_PLAYER_DELAY_REQUEST_DURATION];
		}
//		[playbackDelegate player:self stopObservingPlayerItem:curItem];
//		curItem.nmVideo.nm_player_item = nil;
//		curItem.nmVideo = nil;
//		[self advanceToNextItem];
//		[self play];
	}
	if ( [playbackDelegate nextVideoForPlayer:self] ) [self performSelector:@selector(requestResolveVideo:) withObject:[playbackDelegate nextVideoForPlayer:self] afterDelay:NM_PLAYER_DELAY_REQUEST_DURATION];
	if ( [playbackDelegate nextNextVideoForPlayer:self] ) [self performSelector:@selector(requestResolveVideo:) withObject:[playbackDelegate nextNextVideoForPlayer:self] afterDelay:NM_PLAYER_DELAY_REQUEST_DURATION];
}

- (void)revertToVideo:(NMVideo *)aVideo {
//	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if ( aVideo.video.nm_playback_status <= NMVideoQueueStatusResolvingDirectURL ) {
#ifdef DEBUG_PLAYER_NAVIGATION
		NSLog(@"revertToVideo: %@ - cancel and delay call", aVideo.video.title);
#endif
		// we need to resolve the direct URL
		[self performSelector:@selector(requestResolveVideo:) withObject:aVideo afterDelay:NM_PLAYER_DELAY_REQUEST_DURATION];
	} else {
#ifdef DEBUG_PLAYER_NAVIGATION
		NSLog(@"revertToVideo: %@ - delay revert to video", aVideo.video.title);
#endif
		[self performSelector:@selector(delayedRevertToVideo:) withObject:aVideo afterDelay:NM_PLAYER_DELAY_REQUEST_DURATION];
	}
}

- (void)resolveAndQueueVideos:(NSArray *)vidAy {
	for (NMVideo * theVideo in vidAy) {
		[self requestResolveVideo:theVideo];
	}
}

- (void)resolveAndQueueVideo:(NMVideo *)vid {
#ifdef DEBUG_PLAYER_NAVIGATION
	NSLog(@"resolveAndQueueVideo: %@ - no delay call", vid.video.title);
#endif
	[self performSelector:@selector(requestResolveVideo:) withObject:vid afterDelay:NM_PLAYER_DELAY_REQUEST_DURATION];
}

#pragma mark Video Switching
- (void)delayedRevertToVideo:(NMVideo *)aVideo {
	NMAVPlayerItem * item = [aVideo createPlayerItem];
	if ( item && [self revertPreviousItem:item] ) {
		aVideo.video.nm_playback_status = NMVideoQueueStatusQueued;
	}
}

- (BOOL)revertPreviousItem:(AVPlayerItem *)anItem {
	// move back to the previous item
	AVPlayerItem * cItem = [self.currentItem retain];
	BOOL insertStatus = NO;
	if ( [self canInsertItem:anItem afterItem:cItem] ) {
		[playbackDelegate player:self observePlayerItem:anItem];
		[self insertItem:anItem afterItem:cItem];
		if ( cItem ) {
			[self advanceToNextItem];
		}
		[self play];
		if ( cItem && [self canInsertItem:cItem afterItem:self.currentItem] ) {
#ifdef DEBUG_PLAYER_NAVIGATION
			NMAVPlayerItem * vidItem = (NMAVPlayerItem *)anItem;
			NSLog(@"revertPreviousItem: re-insert original item back to the queue player: %@", vidItem.nmVideo.video.title);
#endif
			[self insertItem:cItem afterItem:self.currentItem];
			insertStatus = YES;
			// remove the last item
			NSArray * allItems = self.items;
			if ( [allItems count] == 4 ) {
				[self removeItem:[allItems objectAtIndex:3]];
			}
		} 
	}
	[cItem release];
	return insertStatus;
}

- (void)requestResolveVideo:(NMVideo *)vid {
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"issue resolution request - %@, status - %d %@", vid.video.title, vid.video.nm_playback_status, [vid.video objectID]);
	if ( vid.video.title == nil ) {
		NSLog(@"null video title?");
	}
#endif
	if ( vid == nil ) return;
	// request to resolve the direct URL of this video
//	if ( vid.nm_playback_status == NMVideoQueueStatusNone ) {
//		vid.nm_playback_status = NMVideoQueueStatusResolvingDirectURL;
//		[nowboxTaskController issueGetDirectURLForVideo:vid];
//	} 
	NMVideoQueueStatusType vidType = vid.video.nm_playback_status;
	if ( vidType > NMVideoQueueStatusResolvingDirectURL ) {
		[self queueVideo:vid];
		if ( [vid isEqual:[playbackDelegate currentVideoForPlayer:self]] ) {
			[playbackDelegate player:self willBeginPlayingVideo:vid];
		}
	} else if ( vidType >= 0 ) {
		vid.video.nm_playback_status = NMVideoQueueStatusResolvingDirectURL;
		[nowboxTaskController issueGetDirectURLForVideo:vid];
	}
	// task queue controller will check if there's an existing task for this
	
}

- (void)refreshPlayerItems:(NSArray *)items {
	NMVideo * vdo;
	for (NMAVPlayerItem * theItem in items) {
		vdo = [theItem.nmVideo retain];
		[self removeItem:theItem];
		// when removing a video item from the queue player, queue player will change the "current item". i.e. triggering the KVO method.
		// We need to reset the status of the video object again here.
		vdo.video.nm_playback_status  = NMVideoQueueStatusNone;
		[self performSelector:@selector(requestResolveVideo:) withObject:vdo afterDelay:0.25];
		[vdo release];
	}
}

- (void)refreshItemFromIndex:(NSUInteger)idx {
	NSArray * allItems = [self items];
	NSUInteger c = [allItems count];
	if ( idx >= c ) {
		return;
	}
	if ( idx == 0 ) {
		[self refreshPlayerItems:allItems];
	} else {
		[self refreshPlayerItems:[allItems subarrayWithRange:NSMakeRange(idx, c - idx)]];
	}
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
	NMAVPlayerItem * thePlayerItem = nil;
	
	switch (c) {
		case 0:
		{
			// the queue player is currently empty. we should queue the current video and start playing it.
			if ( [vid isEqual:[playbackDelegate currentVideoForPlayer:self]] ) {
				// play the video
				[self insertVideoToEndOfQueue:vid];
				[self play];
				// insert other videos
				otherVideo = [playbackDelegate nextVideoForPlayer:self];
				if ( otherVideo && otherVideo.video.nm_playback_status > NMVideoQueueStatusResolvingDirectURL ) {
					[self insertVideoToEndOfQueue:otherVideo];
					
					otherVideo = [playbackDelegate nextNextVideoForPlayer:self];
					if ( otherVideo && otherVideo.video.nm_playback_status > NMVideoQueueStatusResolvingDirectURL ) {
						[self insertVideoToEndOfQueue:otherVideo];
					}
				}
			}
			break;
		}
		case 1:
		{
			// target video is current video
			if ( [vid isEqual:[playbackDelegate currentVideoForPlayer:self]] ) {
				// check if the currently playing video is the video we wanna play
				thePlayerItem = [queuedItems objectAtIndex:0];
				if ( ![thePlayerItem.nmVideo isEqual:vid] ) {
					// we need to queue this video
					[self insertVideoToEndOfQueue:vid];
					[self advanceToVideo:vid];
				}
			} else if ( [vid isEqual:[playbackDelegate nextVideoForPlayer:self]] ) {
				// there's already a video in the queue. That's the current item. We will queue next and next next video into the queue if available
				[self insertVideoToEndOfQueue:vid];
				
				otherVideo = [playbackDelegate nextNextVideoForPlayer:self];
				if ( otherVideo && otherVideo.video.nm_playback_status > NMVideoQueueStatusResolvingDirectURL ) {
					[self insertVideoToEndOfQueue:otherVideo];
				}
			}
			break;
		}
		case 2:
		{
			if ( [vid isEqual:[playbackDelegate currentVideoForPlayer:self]] ) {
				// check if the current video is currently playing
				thePlayerItem = [queuedItems objectAtIndex:0];
				if ( ![thePlayerItem.nmVideo isEqual:vid] ) {
					// we need to queue this video
					[self insertVideo:vid afterItem:thePlayerItem];
//					[self advanceToVideo:vid];
					// check if other videos make sense of not.
					thePlayerItem = [queuedItems objectAtIndex:1];
					otherVideo = [playbackDelegate nextVideoForPlayer:self];
					if ( otherVideo && ![thePlayerItem.nmVideo isEqual:[playbackDelegate nextVideoForPlayer:self]] ) {
//						[playbackDelegate player:self stopObservingPlayerItem:thePlayerItem];
//						[self removeItem:thePlayerItem];
						[self insertVideo:otherVideo afterItem:thePlayerItem];
					}
				} else {

				// we wanna play the current video while there's already videos in the queue. This indicates user has scrolled back to the previous video
					NMAVPlayerItem * otherItem = [queuedItems objectAtIndex:1];
					if ( ![otherItem.nmVideo isEqual:[playbackDelegate nextNextVideoForPlayer:self]] ) {
						// remove
						[playbackDelegate player:self stopObservingPlayerItem:otherItem];
						[self removeItem:otherItem];
					}
				}
			} else if ( [vid isEqual:[playbackDelegate nextNextVideoForPlayer:self]] ) {
				// there are 2 videos queued. Queue the next next video
				[self insertVideoToEndOfQueue:vid];
			}
			break;
		}
		case 3:
		{
			// check if the video is before or after the current set of video. Only queue video to the front of the player for this case
			if ( [vid isEqual:[playbackDelegate currentVideoForPlayer:self]] ) {
				thePlayerItem = [queuedItems objectAtIndex:0];
				if ( ![thePlayerItem.nmVideo isEqual:vid] ) {
					// we need to queue this video
					[self insertVideo:vid afterItem:thePlayerItem];
//					[self advanceToVideo:vid];
					// check if other videos make sense of not.
					thePlayerItem = [queuedItems objectAtIndex:1];
					if ( ![thePlayerItem.nmVideo isEqual:[playbackDelegate nextVideoForPlayer:self]] ) {
//						[playbackDelegate player:self stopObservingPlayerItem:thePlayerItem];
//						[self removeItem:thePlayerItem];
						[self insertVideo:[playbackDelegate nextVideoForPlayer:self] afterItem:thePlayerItem];
						thePlayerItem = [queuedItems objectAtIndex:2];
						if ( ![thePlayerItem.nmVideo isEqual:[playbackDelegate nextNextVideoForPlayer:self]] ) {
//							[playbackDelegate player:self stopObservingPlayerItem:thePlayerItem];
//							[self removeItem:thePlayerItem];
							[self insertVideo:[playbackDelegate nextNextVideoForPlayer:self] afterItem:thePlayerItem];
						}
					} else {
						thePlayerItem = [queuedItems objectAtIndex:2];
						if ( ![thePlayerItem.nmVideo isEqual:[playbackDelegate nextNextVideoForPlayer:self]] ) {
							[playbackDelegate player:self stopObservingPlayerItem:thePlayerItem];
							[self removeItem:thePlayerItem];
						}
					}
				} else {
					NMAVPlayerItem * otherItem = [queuedItems objectAtIndex:1];
					if ( ![otherItem.nmVideo isEqual:[playbackDelegate nextNextVideoForPlayer:self]] ) {
						// remove
						[playbackDelegate player:self stopObservingPlayerItem:otherItem];
						[self removeItem:otherItem];
					}
					otherItem = [queuedItems objectAtIndex:2];
					[playbackDelegate player:self stopObservingPlayerItem:otherItem];
					[self removeItem:otherItem];
				}
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
	vid.video.nm_playback_status = NMVideoQueueStatusDirectURLReady;
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"resolved: %@", vid.video.title);
#endif
	[self queueVideo:vid];
	if ( [vid isEqual:[playbackDelegate currentVideoForPlayer:self]] ) {
		[playbackDelegate player:self willBeginPlayingVideo:vid];
		[self play];
	}
}

@end
