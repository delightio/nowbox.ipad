//
//  VideoPlaybackBaseViewController.m
//  ipad
//
//  Created by Bill So on 11/2/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "VideoPlaybackBaseViewController.h"

@implementation VideoPlaybackBaseViewController
@synthesize currentChannel;
@synthesize currentVideo;
@synthesize launchModeActive;

- (NSArray *)markPlaybackCheckpoint {
	return nil;
}

- (void)showPlaybackView {
}

- (void)setCurrentChannel:(NMChannel *)chnObj startPlaying:(BOOL)aPlayFlag {
	
}

@end
