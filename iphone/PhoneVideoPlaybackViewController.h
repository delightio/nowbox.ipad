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
#import "PhoneMovieDetailView.h"

@class NMVideo;
@class NMTaskQueueController;
@class ipadAppDelegate;
@class PhoneLaunchController;

enum {
	ChannelSwitchNone,
	ChannelSwitchNext,
	ChannelSwitchPrevious,
};

/*!
 Things begin with "setCurrentChannel". This is where the app initialize the data structure for playback.
 
 The viewDidLoad and class init methods are places where we create view objects for display purpose.
 */
@interface PhoneVideoPlaybackViewController : VideoPlaybackBaseViewController <UIPopoverControllerDelegate, UIScrollViewDelegate, VideoPlaybackModelControllerDelegate, NMAVQueuePlayerPlaybackDelegate, UIGestureRecognizerDelegate, PhoneMovieDetailViewDelegate, ToolTipControllerDelegate> {
	IBOutlet UIView * topLevelContainerView;
	IBOutlet UIScrollView * controlScrollView;
	IBOutlet UIScrollView * channelSwitchingScrollView;
	IBOutlet UIButton * favoriteButton;
	IBOutlet UIButton * watchLaterButton;
	IBOutlet UILabel * previousChannelSwitchingLabel;
	IBOutlet UILabel * nextChannelSwitchingLabel;
	IBOutlet UIActivityIndicatorView * previousChannelActivityView;
	IBOutlet UIActivityIndicatorView * nextChannelActivityView;
    UIView *movieBackgroundView;
	NMMovieView * movieView;
	
	NSMutableArray * movieDetailViewArray;
		
	UILabel * currentTimeLabel, * totalDurationLabel;
	BOOL isAspectFill;
	CGFloat movieXOffset;
	
	CGFloat currentXOffset;
	NSUInteger numberOfVideos;
	NMTaskQueueController * nowboxTaskController;
	VideoPlaybackModelController * playbackModelController;
	
	BOOL didSkippedVideo;
	BOOL bufferEmpty;
	BOOL didPlayToEnd;
	BOOL playFirstVideoOnLaunchWhenReady;
    BOOL videoWasPaused;
	PhoneLaunchController * launchController;
    
    BOOL shouldResumePlayingVideoAfterTransition;
	BOOL shouldFadeOutVideoThumbnail;
	BOOL forceStopByUser;
	NSInteger detectedPinchAction;
    int rowIndexToCenterOn;
	NSInteger channelSwitchStatus;
    
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
    void (^alertCompletion)(void);

    BOOL scrollingNotFromUser;        
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) IBOutlet PhoneMovieDetailView * loadedMovieDetailView;
@property (nonatomic, retain) NMControlsView * loadedControlView;
@property (nonatomic, retain) IBOutlet UIImageView * backgroundImage;
@property (nonatomic, retain) UIView *movieBackgroundView;
@property (nonatomic, readonly) UIScrollView * controlScrollView;
@property (nonatomic, assign) ipadAppDelegate * appDelegate;
@property (nonatomic, readonly) VideoPlaybackModelController * playbackModelController;
@property (nonatomic, retain) NSURL *ratingsURL;
@property (retain, nonatomic) IBOutlet UIView *previousChannelHeaderView;
@property (retain, nonatomic) IBOutlet UIView *nextChannelHeaderView;

- (IBAction)playStopVideo:(id)sender;
- (IBAction)addVideoToFavorite:(id)sender;
- (IBAction)addVideoToQueue:(id)sender;

// interface for Channel List View
- (void)playVideo:(NMVideo *)aVideo;
- (void)launchPlayVideo:(NMVideo *)aVideo;
- (void)updateViewsForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;

- (BOOL)shouldShowRateUsReminder;
- (void)showRateUsReminderCompletion:(void (^)(void))completion;

@end
