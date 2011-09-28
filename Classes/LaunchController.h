//
//  LaunchController.h
//  ipad
//
//  Created by Bill So on 27/9/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMLibrary.h"

@class VideoPlaybackViewController;

@interface LaunchController : NSObject {
	UIView * view;
	UIView * progressContainerView;
    IBOutlet UIButton * progressLabel;
	IBOutlet UIImageView * logoImageView;
	BOOL appFirstLaunch;
	VideoPlaybackViewController * viewController;
	
	NSMutableIndexSet * thumbnailVideoIndex, * resolutionVideoIndex;
	NMChannel * channel;
}

@property (nonatomic, assign) VideoPlaybackViewController * viewController;
@property (nonatomic, retain) IBOutlet UIView * view;
@property (nonatomic, retain) IBOutlet UIView * progressContainerView;
@property (nonatomic, retain) NMChannel * channel;

- (void)checkUpdateChannels;
- (void)loadView;
- (void)showSwipeInstruction;
- (void)dimProgressLabel;
- (void)restoreProgressLabel;

@end
