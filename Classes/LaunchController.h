//
//  LaunchController.h
//  ipad
//
//  Created by Bill So on 27/9/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMLibrary.h"
#import "OnBoardProcessViewController.h"

#ifdef DEBUG_ONBOARD_PROCESS
#define NM_ALWAYS_SHOW_ONBOARD_PROCESS	YES
#else
#define NM_ALWAYS_SHOW_ONBOARD_PROCESS	NO
#endif

#ifdef DEBUG_SKIP_ONBOARD_PROCESS
#define NM_SKIP_ONBOARD_PROCESS YES
#else
#define NM_SKIP_ONBOARD_PROCESS NO
#endif

@class VideoPlaybackBaseViewController;

@interface LaunchController : NSObject <OnBoardProcessViewControllerDelegate> {
	UIView * view;
    IBOutlet UIButton * progressLabel;
	BOOL appFirstLaunch;
	BOOL launchProcessStuck;
	BOOL ignoreThumbnailDownloadIndex;
	NSString * lastFailNotificationName;
    OnBoardProcessViewController * onBoardProcessController;
	NSMutableIndexSet * thumbnailVideoIndex, * resolutionVideoIndex;
	NMChannel * channel;
	NMTaskQueueController * taskQueueController;
    NSMutableSet * subscribingChannels;
}

@property (nonatomic, assign) UIViewController * viewController;
@property (nonatomic, assign) VideoPlaybackBaseViewController * playbackViewController;
@property (nonatomic, retain) IBOutlet UIView * view;
@property (nonatomic, retain) IBOutlet UIImageView * logoImageView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView * activityIndicator;
@property (nonatomic, retain) NSString * lastFailNotificationName;
@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NSURL * updateURL;

- (void)checkUpdateChannels;
- (void)loadView;
- (void)beginNewSession;

@end
