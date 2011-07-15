//
//  NMAVQueuePlayer.h
//  ipad
//
//  Created by Bill So on 6/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "NMAVPlayerItem.h"
#import "NMLibrary.h"

@class NMAVQueuePlayer;

@protocol NMAVQueuePlayerPlaybackDelegate <NSObject>

- (void)player:(NMAVQueuePlayer *)aPlayer willBeginPlayingVideo:(NMVideo *)vid;
- (NMVideo *)currentVideoForPlayer:(NMAVQueuePlayer *)aPlayer;
- (NMVideo *)nextVideoForPlayer:(NMAVQueuePlayer *)aPlayer;
- (NMVideo *)nextNextVideoForPlayer:(NMAVQueuePlayer *)aPlayer;

- (void)player:(NMAVQueuePlayer *)aPlayer observePlayerItem:(AVPlayerItem *)anItem;
- (void)player:(NMAVQueuePlayer *)aPlayer stopObservingPlayerItem:(AVPlayerItem *)anItem;

@end

/*!
 It maintains, in all time, at most 3 pending queue item
 */

@interface NMAVQueuePlayer : AVQueuePlayer {
	NMTaskQueueController * nowmovTaskController;
	id<NMAVQueuePlayerPlaybackDelegate> playbackDelegate;
}

@property (nonatomic, assign) id<NMAVQueuePlayerPlaybackDelegate> playbackDelegate;

- (void)advanceToVideo:(NMVideo *)aVideo;
- (void)revertToVideo:(NMVideo *)aVideo;
/*!
 When channel content already exists, we can just set the list of videos to be resolved and queue in the player
 */
- (void)resolveAndQueueVideos:(NSArray *)vidAy;
- (void)resolveAndQueueVideo:(NMVideo *)vid;

@end
