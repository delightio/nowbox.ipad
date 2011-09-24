//
//  VideoPlaybackViewController.h
//  Nowmov
//
//  Created by Bill So on 03/03/2011.
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
#import <MediaPlayer/MediaPlayer.h>
#import "NMStyleUtility.h"

@class NMVideo;
@class NMChannel;
@class NMTaskQueueController;
@class ChannelPanelController;
@class ipadAppDelegate;


/*!
 Things begin with "setCurrentChannel". This is where the app initialize the data structure for playback.
 
 The viewDidLoad and class init methods are places where we create view objects for display purpose.
 */
@interface VideoPlaybackViewController : UIViewController <UIPopoverControllerDelegate, UIScrollViewDelegate, VideoPlaybackModelControllerDelegate, NMAVQueuePlayerPlaybackDelegate, UIGestureRecognizerDelegate, NMControlsViewDelegate> {
	IBOutlet UIScrollView * controlScrollView;
	IBOutlet UIView * ribbonView;
	IBOutlet UIButton * favoriteButton;
	IBOutlet UIButton * watchLaterButton;
	NMMovieView * movieView;
	
	NMMovieDetailView * loadedMovieDetailView;
	NSMutableArray * movieDetailViewArray;
	
	NMControlsView * loadedControlView;
	ChannelPanelController * channelController;
	
	UILabel * currentTimeLabel, * totalDurationLabel;
	BOOL isAspectFill;
	BOOL firstShowControlView;
	CGFloat movieXOffset;
	CGRect fullScreenRect, splitViewRect;
	
	CGFloat currentXOffset;
	NSUInteger numberOfVideos;
	NMChannel * currentChannel;
	NMTaskQueueController * nowmovTaskController;
	VideoPlaybackModelController * playbackModelController;
	
	BOOL didSkippedVideo;
//	BOOL videoDurationInvalid;
	BOOL bufferEmpty;
	BOOL didPlayToEnd;
	id timeObserver;
	
	NSInteger showMovieControlTimestamp;
	
	@private
    NSManagedObjectContext *managedObjectContext_;
	NSNotificationCenter * defaultNotificationCenter;

//    NSMutableArray *temporaryDisabledGestures;
//    BOOL pinchTemporarilyDisabled;
	ipadAppDelegate * appDelegate;
	NMStyleUtility * styleUtility;
}

@property (nonatomic, retain) NMChannel * currentChannel;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) IBOutlet NMMovieDetailView * loadedMovieDetailView;
@property (nonatomic, retain) IBOutlet NMControlsView * loadedControlView;	// it's a proxy. it does not retain the view loaded.
@property (nonatomic, retain) IBOutlet ChannelPanelController * channelController;
@property (nonatomic, assign) ipadAppDelegate * appDelegate;

- (IBAction)playStopVideo:(id)sender;
- (IBAction)skipCurrentVideo:(id)sender;
- (IBAction)toggleChannelPanel:(id)sender;
- (IBAction)toggleChannelPanelFullScreen:(id)sender;
- (void)channelPanelToggleToFullScreen:(BOOL)shouldToggleToFullScreen resumePlaying:(BOOL)shouldResume centerToRow:(NSInteger)indexInTable;
// movie detail view actions
- (IBAction)addVideoToFavorite:(id)sender;
- (IBAction)addVideoToQueue:(id)sender;
// seeking
- (IBAction)seekPlaybackProgress:(id)sender;
- (IBAction)touchDownProgressBar:(id)sender;
- (IBAction)touchUpProgressBar:(id)sender;

// playback view update
- (void)markPlaybackCheckpoint;
// buttons management
- (void)updateRibbonButtons;
- (void)updateFavoriteButton;
- (void)updateWatchLaterButton;
- (void)animateFavoriteButtonsToInactive;			// buttons deliberately has "s" because there are 2 favorite buttons
- (void)animateWatchLaterButtonsToInactive;
- (void)animateFavoriteButtonsToActive;
- (void)animateWatchLaterButtonsToActive;

// interface for Channel List View
- (void)playVideo:(NMVideo *)aVideo;
- (void)launchPlayVideo:(NMVideo *)aVideo;

#ifdef DEBUG_PLAYER_NAVIGATION
- (NMAVQueuePlayer *)getQueuePlayer;
#endif

@end
