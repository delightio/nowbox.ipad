//
//  VideoPlaybackBaseViewController.h
//  ipad
//
//  Created by Bill So on 11/2/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NMChannel;
@class NMVideo;

@interface VideoPlaybackBaseViewController : UIViewController {
	NMChannel * currentChannel;
	BOOL launchModeActive;
}

@property (nonatomic, retain) NMChannel * currentChannel;
@property (nonatomic, readonly) NMVideo * currentVideo;
@property (nonatomic) BOOL launchModeActive;

// setting channel
- (void)setCurrentChannel:(NMChannel *)chnObj startPlaying:(BOOL)aPlayFlag;
// playback view update
- (NSArray *)markPlaybackCheckpoint;
// launch view / onboard process
- (void)showPlaybackView;

@end
