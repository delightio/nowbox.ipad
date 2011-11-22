//
//  LaunchController.h
//  ipad
//
//  Created by Bill So on 27/9/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMLibrary.h"
#import "OnBoardProcessViewController.h"

@class VideoPlaybackViewController;

@interface LaunchController : NSObject <OnBoardProcessViewControllerDelegate> {
	UIView * view;
    IBOutlet UIButton * progressLabel;
	IBOutlet UIImageView * logoImageView;
	BOOL appFirstLaunch;
	BOOL launchProcessStuck;
	BOOL ignoreThumbnailDownloadIndex;
	NSString * lastFailNotificationName;
	VideoPlaybackViewController * viewController;
    OnBoardProcessViewController * onBoardProcessController;
    
	NSMutableIndexSet * thumbnailVideoIndex, * resolutionVideoIndex;
	NMChannel * channel;
	NMTaskQueueController * taskQueueController;
}

@property (nonatomic, assign) VideoPlaybackViewController * viewController;
@property (nonatomic, retain) IBOutlet UIView * view;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView * activityIndicator;
@property (nonatomic, retain) NSString * lastFailNotificationName;
@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NSURL * updateURL;

- (void)checkUpdateChannels;
- (void)loadView;

@end
