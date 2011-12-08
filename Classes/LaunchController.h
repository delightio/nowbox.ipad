//
//  LaunchController.h
//  ipad
//
//  Created by Bill So on 27/9/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMLibrary.h"
#import "OnBoardProcessViewController.h"

@class VideoPlaybackBaseViewController;

@interface LaunchController : NSObject <OnBoardProcessViewControllerDelegate> {
	UIView * view;
    IBOutlet UIButton * progressLabel;
	BOOL appFirstLaunch;
	BOOL launchProcessStuck;
	BOOL ignoreThumbnailDownloadIndex;
	NSString * lastFailNotificationName;
	VideoPlaybackBaseViewController * viewController;
    OnBoardProcessViewController * onBoardProcessController;
	NSMutableIndexSet * thumbnailVideoIndex, * resolutionVideoIndex;
	NMChannel * channel;
	NMTaskQueueController * taskQueueController;
    NSMutableSet * subscribingChannels;
}

@property (nonatomic, assign) VideoPlaybackBaseViewController * viewController;
@property (nonatomic, retain) IBOutlet UIView * view;
@property (nonatomic, retain) IBOutlet UIImageView * logoImageView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView * activityIndicator;
@property (nonatomic, retain) NSString * lastFailNotificationName;
@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NSURL * updateURL;

- (void)checkUpdateChannels;
- (void)loadView;

@end
