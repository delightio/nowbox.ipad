//
//  PhoneVideoPlaybackViewController.h
//  Nowmov
//
//  Created by Bill So on 11/02/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "NMLibrary.h"
#import "NMMovieView.h"
#import "NMMovieDetailView.h"
#import "NMControlsView.h"
#import "VideoPlaybackModelController.h"
#import "NMAVQueuePlayer.h"
#import "NMAVPlayerItem.h"
#import "ToolTipController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "NMStyleUtility.h"
#import "VideoPlaybackBaseViewController.h"

@class NMVideo;
@class NMTaskQueueController;
@class ipadAppDelegate;
@class LaunchController;


/*!
 Things begin with "setCurrentChannel". This is where the app initialize the data structure for playback.
 
 The viewDidLoad and class init methods are places where we create view objects for display purpose.
 */
@interface PhoneVideoPlaybackViewController : VideoPlaybackBaseViewController <UIPopoverControllerDelegate, UIScrollViewDelegate, VideoPlaybackModelControllerDelegate, NMAVQueuePlayerPlaybackDelegate, UIGestureRecognizerDelegate, NMControlsViewDelegate> {
	IBOutlet UIView * topLevelContainerView;
	IBOutlet UIScrollView * controlScrollView;
	IBOutlet UIView * ribbonView;
	IBOutlet UIButton * favoriteButton;
	IBOutlet UIButton * watchLaterButton;
	NMMovieView * movieView;
	
	NSMutableArray * movieDetailViewArray;
	
	NMControlsView * loadedControlView;
	
	UILabel * currentTimeLabel, * totalDurationLabel;
	BOOL isAspectFill;
//	BOOL scrollBeyondThreshold;
	CGFloat movieXOffset;
	CGFloat screenWidth;
	CGRect fullScreenRect, splitViewRect;
//	CGRect topLeftRect;
	
	CGFloat currentXOffset;
	NSUInteger numberOfVideos;
	NMTaskQueueController * nowboxTaskController;
	VideoPlaybackModelController * playbackModelController;
	
	BOOL didSkippedVideo;
//	BOOL videoDurationInvalid;
	BOOL bufferEmpty;
	BOOL didPlayToEnd;
	BOOL playFirstVideoOnLaunchWhenReady;
	LaunchController * launchController;
    BOOL shouldResumePlayingVideoAfterTransition;
	BOOL shouldFadeOutVideoThumbnail;
	BOOL forceStopByUser;
	NSInteger detectedPinchAction;
    int rowIndexToCenterOn;
    
	id timeObserver;
	
	NSInteger showMovieControlTimestamp;
	// for posting seek event
	NSInteger lastTimeElapsed, lastStartTime;
		
	@private
    NSManagedObjectContext *managedObjectContext_;
	NSNotificationCenter * defaultNotificationCenter;

	ipadAppDelegate * appDelegate;
	NMStyleUtility * styleUtility;
    
    ToolTip *pendingToolTip;
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) IBOutlet NMControlsView * loadedControlView;	// it's a proxy. it does not retain the view loaded.
@property (nonatomic, readonly) UIScrollView * controlScrollView;
@property (nonatomic, assign) ipadAppDelegate * appDelegate;

- (IBAction)playStopVideo:(id)sender;
//- (IBAction)toggleChannelPanel:(id)sender;
//- (IBAction)toggleChannelPanelFullScreen:(id)sender;
//- (void)channelPanelToggleToFullScreen:(BOOL)shouldToggleToFullScreen resumePlaying:(BOOL)shouldResume centerToRow:(NSInteger)indexInTable;
// movie detail view actions
- (IBAction)addVideoToFavorite:(id)sender;
- (IBAction)addVideoToQueue:(id)sender;
// seeking
- (IBAction)seekPlaybackProgress:(id)sender;
- (IBAction)touchDownProgressBar:(id)sender;
- (IBAction)touchUpProgressBar:(id)sender;

// interface for Channel List View
- (void)playVideo:(NMVideo *)aVideo;
- (void)launchPlayVideo:(NMVideo *)aVideo;

// launch view / onboard process
//- (void)showPlaybackViewWithTransitionStyle:(NSString *)aniStyle;
- (void)showPlaybackView;

#ifdef DEBUG_PLAYER_NAVIGATION
- (NMAVQueuePlayer *)getQueuePlayer;
#endif

@end
