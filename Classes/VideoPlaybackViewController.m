//
//  VideoPlaybackViewController.m
//  Nowmov
//
//  Created by Bill So on 03/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "VideoPlaybackViewController.h"
#import "NMMovieView.h"
#import "ChannelPanelController.h"
#import "ShareViewController.h"
#import "ipadAppDelegate.h"
#import "LaunchController.h"
#import "Analytics.h"
#import "UIView+InteractiveAnimation.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>

#define NM_PLAYER_STATUS_CONTEXT				100
#define NM_PLAYER_CURRENT_ITEM_CONTEXT			101
#define NM_PLAYBACK_BUFFER_EMPTY_CONTEXT		102
#define NM_PLAYBACK_LIKELY_TO_KEEP_UP_CONTEXT	103
#define NM_VIDEO_READY_FOR_DISPLAY_CONTEXT		105
#define NM_PLAYER_ITEM_STATUS_CONTEXT			106
#define NM_PLAYER_RATE_CONTEXT					107
#define NM_AIR_PLAY_VIDEO_ACTIVE_CONTEXT		108
#define NM_PLAYBACK_LOADED_TIME_RANGES_CONTEXT	109

#define NM_MAX_VIDEO_IN_QUEUE				3
#define NM_INDEX_PATH_CACHE_SIZE			4

#define NM_CONTROL_VIEW_AUTO_HIDE_INTERVAL		4
//#define NM_ANIMATION_HIDE_CONTROL_VIEW_FOR_USER			10001
#define NM_ANIMATION_RIBBON_FADE_OUT_CONTEXT			10002
#define NM_ANIMATION_RIBBON_FADE_IN_CONTEXT				10003
#define NM_ANIMATION_FAVORITE_BUTTON_ACTIVE_CONTEXT		10004
#define NM_ANIMATION_WATCH_LATER_BUTTON_ACTIVE_CONTEXT	10005
#define NM_ANIMATION_FULL_PLAYBACK_SCREEN_CONTEXT		10006
#define NM_ANIMATION_SPLIT_VIEW_CONTEXT					10007
#define NM_ANIMATION_VIDEO_THUMBNAIL_CONTEXT			10008
#define NM_ANIMATION_FULL_SCREEN_CHANNEL_CONTEXT		10009

#define NM_SHOULD_TRANSIT_SPLIT_VIEW					1
#define NM_SHOULD_TRANSIT_FULL_SCREEN_VIEW				2
#define NM_IPAD_SCREEN_WIDTH									1044.0f
#define NM_IPAD_SCREEN_WIDTH_INT								1044

#define NM_RATE_US_REMINDER_MINIMUM_TIME_ON_APP         (60.0f * 40)

BOOL NM_VIDEO_CONTENT_CELL_ALPHA_ZERO = NO;

@interface VideoPlaybackViewController (PrivateMethods)

- (void)controlsViewTouchUp:(id)sender;
- (void)configureControlViewForVideo:(NMVideo *)aVideo;
- (void)configureDetailViewForContext:(NSInteger)ctx;
- (void)showNextVideo:(BOOL)didPlayToEnd;
- (void)playCurrentVideo;
- (void)stopVideo;
- (void)setupPlayer;

- (NMVideo *)playerCurrentVideo;
- (void)showLaunchView;

// Movie detail view management
- (void)resetAllMovieDetailViews;
- (NMMovieDetailView *)dequeueReusableMovieDetailView;
- (void)reclaimMovieDetailViewForVideo:(NMVideo *)vdo;
- (void)cleanUpBadVideosMovieDetailView;

// debug message
- (void)printDebugMessage:(NSString *)str;

@end


@implementation VideoPlaybackViewController
@synthesize managedObjectContext=managedObjectContext_;
@synthesize currentChannel;
@synthesize currentVideo;
@synthesize channelController;
@synthesize loadedControlView;
@synthesize controlScrollView;
@synthesize movieView;
@synthesize loadedMovieDetailView;
@synthesize appDelegate;
@synthesize launchModeActive;
@synthesize playbackModelController;
@synthesize ratingsURL;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	styleUtility = [NMStyleUtility sharedStyleUtility];
//	[[UIApplication sharedApplication] setStatusBarHidden:NO];
//	self.wantsFullScreenLayout = YES;
	isAspectFill = YES;
	currentXOffset = 0.0f;
	showMovieControlTimestamp = -1;
	fullScreenRect = CGRectMake(0.0f, 0.0f, NM_IPAD_SCREEN_WIDTH, 768.0f);
	splitViewRect = CGRectMake(0.0f, 0.0f, NM_IPAD_SCREEN_WIDTH, 380.0f);
	topLeftRect = CGRectMake(0.0f, 0.0f, 200.0f, 200.0f);
	
	// ribbon view
	ribbonView.layer.contents = (id)[UIImage imageNamed:@"ribbon"].CGImage;
	ribbonView.layer.shouldRasterize = YES;
	
	// playback data model controller
	nowboxTaskController = [NMTaskQueueController sharedTaskQueueController];
	playbackModelController = [VideoPlaybackModelController sharedVideoPlaybackModelController];
	playbackModelController.managedObjectContext = self.managedObjectContext;
	playbackModelController.dataDelegate = self;

#ifndef DEBUG_NO_VIDEO_PLAYBACK_VIEW
	// === don't change the sequence in this block ===
	// create movie view
	movieView = [[NMMovieView alloc] initWithFrame:CGRectMake(0.0f, 20.0f, 640.0f, 360.0f)];
	movieView.alpha = 0.0f;
	// set target-action methods
	UITapGestureRecognizer * dblTapRcgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(movieViewDoubleTap:)];
	dblTapRcgr.numberOfTapsRequired = 2;
	[movieView addGestureRecognizer:dblTapRcgr];
	
	UITapGestureRecognizer * tapRcgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(movieViewTouchUp:)];
	tapRcgr.numberOfTapsRequired = 1;
	[tapRcgr requireGestureRecognizerToFail:dblTapRcgr];
	[movieView addGestureRecognizer:tapRcgr];
	[tapRcgr release];
	[dblTapRcgr release];
	
	[controlScrollView addSubview:movieView];
	controlScrollView.frame = splitViewRect;
	
	// pre-load control view
	// load the nib
	[[NSBundle mainBundle] loadNibNamed:@"VideoControlView" owner:self options:nil];
//	// top left corner gesture recognizer
//	UITapGestureRecognizer * topLeftRcgr = [[UITapGestureRecognizer alloc] initWithTarget:@selector() action:self];
//	topLeftRcgr.
	// double-tap handling
	dblTapRcgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(movieViewDoubleTap:)];
	dblTapRcgr.numberOfTapsRequired = 2;
	dblTapRcgr.delegate = loadedControlView;
	[loadedControlView addGestureRecognizer:dblTapRcgr];
	// single-tap handling
	tapRcgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(controlsViewTouchUp:)];
	tapRcgr.numberOfTapsRequired = 1;
	tapRcgr.delegate = loadedControlView;
	[tapRcgr requireGestureRecognizerToFail:dblTapRcgr];
	[loadedControlView addGestureRecognizer:tapRcgr];
	[tapRcgr release];
	[dblTapRcgr release];
	 
	loadedControlView.frame = movieView.frame;
	loadedControlView.controlDelegate = self;
	[loadedControlView setPlaybackMode:NMHalfScreenMode animated:NO];
	[loadedControlView setTopBarHidden:YES animated:NO];
	
	// put the view to scroll view
	[controlScrollView addSubview:loadedControlView];
	controlScrollView.decelerationRate = UIScrollViewDecelerationRateNormal / 2.0f;
	
	// set up player
	[self setupPlayer];
	
	// ======
#endif
	
	// load channel view
#ifndef DEBUG_NO_CHANNEL_VIEW
	[[NSBundle mainBundle] loadNibNamed:@"ChannelPanelView" owner:self options:nil];
	CGRect theFrame = channelController.panelView.frame;
	theFrame.origin.y = splitViewRect.size.height;
	channelController.panelView.frame = theFrame;
	channelController.videoViewController = self;
	[topLevelContainerView addSubview:channelController.panelView];
#endif
    [channelController postAnimationChangeForDisplayMode:NMHalfScreenMode];
    
	defaultNotificationCenter = [NSNotificationCenter defaultCenter];
	// listen to item finish up playing notificaiton
	[defaultNotificationCenter addObserver:self selector:@selector(handleDidPlayItemNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
	// listen to system notification
	[defaultNotificationCenter addObserver:self selector:@selector(handleApplicationDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
	[defaultNotificationCenter addObserver:self selector:@selector(handleApplicationDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
	// 2nd display support
//	[defaultNotificationCenter addObserver:self selector:@selector(handleDisplayConnectedNotification:) name:UIScreenDidConnectNotification object:nil];
//	[defaultNotificationCenter addObserver:self selector:@selector(handleDisplayDisconnectedNotification:) name:UIScreenDidDisconnectNotification object:nil];
	
	// channel management view notification
	[defaultNotificationCenter addObserver:self selector:@selector(handleChannelManagementNotification:) name:NMChannelManagementWillAppearNotification object:nil];
	[defaultNotificationCenter addObserver:self selector:@selector(handleChannelManagementNotification:) name:NMChannelManagementDidDisappearNotification object:nil];
	// event
	[defaultNotificationCenter addObserver:self selector:@selector(handleVideoEventNotification:) name:NMDidShareVideoNotification object:nil];
    [defaultNotificationCenter addObserver:self selector:@selector(handleVideoEventNotification:) name:NMDidPostSharingNotification object:nil];
	[defaultNotificationCenter addObserver:self selector:@selector(handleVideoEventNotification:) name:NMDidUnfavoriteVideoNotification object:nil];
	[defaultNotificationCenter addObserver:self selector:@selector(handleVideoEventNotification:) name:NMDidEnqueueVideoNotification object:nil];
	[defaultNotificationCenter addObserver:self selector:@selector(handleVideoEventNotification:) name:NMDidDequeueVideoNotification object:nil];
	[defaultNotificationCenter addObserver:self selector:@selector(handleVideoEventNotification:) name:NMDidFailShareVideoNotification object:nil];
    [defaultNotificationCenter addObserver:self selector:@selector(handleVideoEventNotification:) name:NMDidFailPostSharingNotification object:nil];    
	[defaultNotificationCenter addObserver:self selector:@selector(handleVideoEventNotification:) name:NMDidFailUnfavoriteVideoNotification object:nil];
	[defaultNotificationCenter addObserver:self selector:@selector(handleVideoEventNotification:) name:NMDidFailEnqueueVideoNotification object:nil];
	[defaultNotificationCenter addObserver:self selector:@selector(handleVideoEventNotification:) name:NMDidFailDequeueVideoNotification object:nil];
	// channel
	[defaultNotificationCenter addObserver:self selector:@selector(handleGetChannelsNotification:) name:NMDidGetChannelsNotification object:nil];
	[defaultNotificationCenter addObserver:self selector:@selector(handleDidGetInfoNotification:) name:NMDidCheckUpdateNotification object:nil];

	// setup gesture recognizer
	UIPinchGestureRecognizer * pinRcr = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleMovieViewPinched:)];
    pinRcr.delegate = self;
	[controlScrollView addGestureRecognizer:pinRcr];
	[pinRcr release];
	
	// create the launch view
	launchController = [[LaunchController alloc] init];
	launchController.viewController = self;
	[[NSBundle mainBundle] loadNibNamed:@"LaunchView" owner:launchController options:nil];
	[self showLaunchView];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self playCurrentVideo];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)didReceiveMemoryWarning {
    // FIXME: Can't call super since it may unload all our views (e.g. if memory warning occurs during onboard process).
    // This view controller assumes viewDidLoad will only be called once and breaks otherwise.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[launchController release];
	[managedObjectContext_ release];
	
	[loadedControlView release];
	[movieDetailViewArray release];
	[currentChannel release];
	[channelController release];
	// get rid of time observer of video player
 	[movieView.player removeTimeObserver:timeObserver];
	[timeObserver release];
	// remove movie view. only allow this to happen after we have removed the time observer
	[movieView release];
//    [temporaryDisabledGestures release];
    [ratingsURL release];
    
	[super dealloc];
}

#pragma mark Launch / onboard process

- (void)showLaunchView {
	[launchController loadView];
	[self.view addSubview:launchController.view];
}

- (void)showPlaybackView {
	if ( launchModeActive ) {
//		controlScrollView.scrollEnabled = NO;
		// reset the alpha value
		playbackModelController.currentVideo.nm_movie_detail_view.thumbnailContainerView.alpha = 1.0f;
		movieView.alpha = 0.0f; // delayRestoreDetailView is called in controller:didUpdateVideoListWithTotalNumberOfVideo: when the channel is updated. The delay method will reset the alpha value of the views.

		shouldFadeOutVideoThumbnail = YES;
        [launchController.view removeFromSuperview];
        [launchController release];
        launchController = nil;
        launchModeActive = NO;
        playFirstVideoOnLaunchWhenReady = YES;
        
/*		[UIView transitionFromView:launchController.view toView:topLevelContainerView duration:0.5f options:(NM_RUNNING_IOS_5 ? UIViewAnimationOptionTransitionCrossDissolve : UIViewAnimationOptionTransitionNone) completion:^(BOOL finished) {
			// remove launch view
			[launchController.view removeFromSuperview];
			[launchController release];
			launchController = nil;
			launchModeActive = NO;
			playFirstVideoOnLaunchWhenReady = YES;
		}];*/

	} else {
		// cross fade
#if __IPHONE_4_3 < __IPHONE_OS_VERSION_MAX_ALLOWED
		[UIView transitionFromView:launchController.view toView:topLevelContainerView duration:0.5f options:(NM_RUNNING_IOS_5 ? UIViewAnimationOptionTransitionCrossDissolve : UIViewAnimationOptionTransitionNone) completion:^(BOOL finished) {
			// remove launch view
			[launchController.view removeFromSuperview];
			[launchController release];
			launchController = nil;
		}];
#else
		[UIView transitionFromView:launchController.view toView:topLevelContainerView duration:0.5f options:0 completion:^(BOOL finished) {
			// remove launch view
			[launchController.view removeFromSuperview];
			[launchController release];
			launchController = nil;
		}];
#endif
		playFirstVideoOnLaunchWhenReady = YES;
	}
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    // Start monitoring for tooltips
    [[ToolTipController sharedToolTipController] startTimer];
    [[ToolTipController sharedToolTipController] setDelegate:self];
}

#pragma mark Playback data structure

- (NSArray *)markPlaybackCheckpoint {
	NMVideo * theVideo = [self playerCurrentVideo];
	// theVideo is null if there's no video playing (say, when there's no network connection)
	if ( theVideo == nil ) return nil;
	CMTime aTime = movieView.player.currentTime;
	if ( aTime.flags & kCMTimeFlags_Valid ) {
		currentChannel.nm_time_elapsed_value = [NSNumber numberWithLongLong:aTime.value];
		currentChannel.nm_time_elapsed_timescale = [NSNumber numberWithInteger:aTime.timescale];
	}
	// send event back to nowmov server
	currentChannel.nm_last_vid = theVideo.nm_id;
	NSMutableArray * vdoAy = [NSMutableArray arrayWithCapacity:4];
	[vdoAy addObject:theVideo.nm_id];
	theVideo = playbackModelController.previousVideo;
	if ( theVideo ) {
		[vdoAy addObject:theVideo.nm_id];
	}
	theVideo = playbackModelController.nextVideo;
	if ( theVideo ) {
		[vdoAy addObject:theVideo.nm_id];
	}
	theVideo = playbackModelController.nextNextVideo;
	if ( theVideo ) {
		[vdoAy addObject:theVideo.nm_id];
	}
	// send event back to nowmov server
	[nowboxTaskController issueSendViewEventForVideo:playbackModelController.currentVideo elapsedSeconds:loadedControlView.timeElapsed playedToEnd:NO];
	return vdoAy;
}


- (void)setCurrentChannel:(NMChannel *)chnObj {
	[self setCurrentChannel:chnObj startPlaying:YES];
}

- (void)setCurrentChannel:(NMChannel *)chnObj startPlaying:(BOOL)aPlayFlag {
	if ( currentChannel ) {
		if ( currentChannel != chnObj ) {
			// report event
			[nowboxTaskController issueSendViewEventForVideo:playbackModelController.currentVideo start:lastStartTime elapsedSeconds:loadedControlView.timeElapsed - lastStartTime];
			// clear all task related to the previous channel
			[nowboxTaskController cancelAllPlaybackTasksForChannel:currentChannel];
			[currentChannel release];
			currentChannel = [chnObj retain];
		} else {
			return;
		}
	} else {
		currentChannel = [chnObj retain];
	}
	if ( chnObj == nil ) {
		[self resetAllMovieDetailViews];
		
		[loadedControlView resetView];
		return;	// return if the channel object is nil
	}
	
	[loadedControlView resetView];
	// flush video player
	[movieView.player removeAllItems];
	// save the channel ID to user defaults
	[appDelegate saveChannelID:chnObj.nm_id];
	
	playFirstVideoOnLaunchWhenReady = aPlayFlag;
    forceStopByUser = NO;	// reset the flag
	currentXOffset = 0.0f;
	ribbonView.alpha = 0.15;	// set alpha before calling "setVideo" method
	ribbonView.userInteractionEnabled = NO;

	// playbackModelController is responsible for loading the channel managed objects and set up the playback data structure.
	playbackModelController.channel = chnObj;
	chnObj.nm_is_new = (NSNumber *)kCFBooleanFalse;
//	NSArray * vidAy = [playbackModelController videosForBuffering];
//	if ( vidAy ) {
//		[movieView.player resolveAndQueueVideos:vidAy];
//	}
	
	// update the interface if necessary
	//	[movieView setActivityIndicationHidden:NO animated:NO];
//	[self updateRibbonButtons];
    
    [[MixpanelAPI sharedAPI] track:AnalyticsEventPlayVideo properties:[NSDictionary dictionaryWithObjectsAndKeys:playbackModelController.channel.title, AnalyticsPropertyChannelName, 
                                                                       playbackModelController.currentVideo.title, AnalyticsPropertyVideoName, 
                                                                       playbackModelController.currentVideo.nm_id, AnalyticsPropertyVideoId,
                                                                       @"player", AnalyticsPropertySender, 
                                                                       @"auto", AnalyticsPropertyAction, 
                                                                       [NSNumber numberWithBool:NM_AIRPLAY_ACTIVE], AnalyticsPropertyAirPlayActive, nil]];
}

- (NMVideo *)currentVideo {
	return playbackModelController.currentVideo;
}

#pragma mark Playback Control

- (NMVideo *)playerCurrentVideo {
	NMAVPlayerItem * item = (NMAVPlayerItem *)movieView.player.currentItem;
	return item.nmVideo;
}

- (void)stopVideo {
	[movieView.player pause];
}

- (void)playCurrentVideo {
	if ( !forceStopByUser && movieView.player.rate == 0.0 ) {
		[movieView.player play];
	}
}

- (IBAction)playStopVideo:(id)sender {
	if ( movieView.player.rate == 0.0 ) {
		forceStopByUser = NO;
		showMovieControlTimestamp = loadedControlView.timeElapsed;
		[movieView.player play];
	} else {
		forceStopByUser = YES;
		[movieView.player pause];
	}
}

- (void)showActivityLoader {
	[self.currentVideo.nm_movie_detail_view setActivityViewHidden:NO];
}

#pragma mark NMControlsView delegate methods

- (void)didTapAirPlayContainerView:(NMAirPlayContainerView *)ctnView {
	// display the timer
	showMovieControlTimestamp = -1;
}

#pragma mark Movie View Management
- (void)setupPlayer {
	NMAVQueuePlayer * player = [[NMAVQueuePlayer alloc] init];
	player.playbackDelegate = self;
	// actionAtItemEnd MUST be set to AVPlayerActionAtItemEndPause. When the player plays to the end of the video, the controller needs to remove the AVPlayerItem from oberver list. We do this in the notification handler
	if ( kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_4_0 ) {
		player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
//		player.usesAirPlayVideoWhileAirPlayScreenIsActive = NO;
	}
	movieView.player = player;
	// observe status change in player
	[player addObserver:self forKeyPath:@"status" options:0 context:(void *)NM_PLAYER_STATUS_CONTEXT];
	[player addObserver:self forKeyPath:@"currentItem" options:0 context:(void *)NM_PLAYER_CURRENT_ITEM_CONTEXT];
	[player addObserver:self forKeyPath:@"airPlayVideoActive" options:0 context:(void *)NM_AIR_PLAY_VIDEO_ACTIVE_CONTEXT];
//	[movieView.layer addObserver:self forKeyPath:@"readyForDisplay" options:0 context:(void *)NM_VIDEO_READY_FOR_DISPLAY_CONTEXT];
	// all control view should observe to player changes
	[player addObserver:self forKeyPath:@"rate" options:0 context:(void *)NM_PLAYER_RATE_CONTEXT];
	timeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMake(600, 600) queue:NULL usingBlock:^(CMTime aTime){
		// print the time
		CMTime t = [movieView.player currentTime];
		NSInteger sec = 0;
		if ( t.flags & kCMTimeFlags_Valid ) {
			sec = t.value / t.timescale;
			loadedControlView.timeElapsed = sec;
		}
		if ( didSkippedVideo ) {
			didSkippedVideo = NO;
//			[movieView setActivityIndicationHidden:YES animated:YES];
		}
		if ( showMovieControlTimestamp > 0 ) {
			// check if it's time to auto hide control
			if ( showMovieControlTimestamp + NM_CONTROL_VIEW_AUTO_HIDE_INTERVAL < sec ) {
				// we should hide
				showMovieControlTimestamp = -1;
//				[self hideControlView];
				[loadedControlView setControlsHidden:YES animated:YES];
			}
		}
	}];
	// retain the time observer
	[timeObserver retain];
}

#pragma mark Control Views Management
- (void)configureControlViewForVideo:(NMVideo *)aVideo {
#ifdef DEBUG_PLAYER_NAVIGATION
	NSLog(@"configure control view for: %@, %@, %f", aVideo.title, aVideo.nm_id, currentXOffset);
#endif
	[loadedControlView resetView];
	if ( aVideo ) {
		[loadedControlView updateViewForVideo:aVideo];
	}
	// update the position
	CGRect theFrame = loadedControlView.frame;
	theFrame.origin.x = currentXOffset;
	loadedControlView.frame = theFrame;
	// update the movie view too
	movieView.frame = theFrame;
	[UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone animations:^{
                         movieView.alpha = 1.0f;
                     } completion:^(BOOL finished) {
                         [loadedControlView setControlsHidden:NO animated:YES];
                     }];
}

//- (void)hideControlView {
//	if ( loadedControlView.alpha > 0.0f ) {
//		[UIView animateWithInteractiveDuration:0.25f animations:^{
//			loadedControlView.alpha = 0.0f;
//		}];
//	}
//}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	NSInteger ctxInt = (NSInteger)context;
	switch (ctxInt) {
		case NM_ANIMATION_RIBBON_FADE_OUT_CONTEXT:
		case NM_ANIMATION_RIBBON_FADE_IN_CONTEXT:
			break;
			
		case NM_ANIMATION_FAVORITE_BUTTON_ACTIVE_CONTEXT:
			[self updateFavoriteButton];
			break;
			
		case NM_ANIMATION_WATCH_LATER_BUTTON_ACTIVE_CONTEXT:
			[self updateWatchLaterButton];
			break;
			
		case NM_ANIMATION_FULL_PLAYBACK_SCREEN_CONTEXT:
			// show the top bar with animation
			[loadedControlView setTopBarHidden:NO animated:NO];
			[self configureDetailViewForContext:ctxInt];
			ribbonView.hidden = YES;
			break;
			
		case NM_ANIMATION_FULL_SCREEN_CHANNEL_CONTEXT:
			// animation done. Rest flag.
			NM_VIDEO_CONTENT_CELL_ALPHA_ZERO = NO;
            [channelController.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rowIndexToCenterOn inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
			break;
			
		case NM_ANIMATION_SPLIT_VIEW_CONTEXT:
			controlScrollView.frame = splitViewRect;
            [channelController.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rowIndexToCenterOn inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
//            if ( launchModeActive ) {
//				// remove the view
//				[launchController.progressContainerView removeFromSuperview];
//				[launchController.view removeFromSuperview];
//				[launchController release];
//				launchController = nil;
//				launchModeActive = NO;
//			}
			break;
		case NM_ANIMATION_VIDEO_THUMBNAIL_CONTEXT:
//			controlScrollView.scrollEnabled = YES;
			[self configureControlViewForVideo:[self playerCurrentVideo]];
			[self playCurrentVideo];
			break;
		default:
			break;
	}
}

#pragma mark Movie detail view management
- (void)resetAllMovieDetailViews {
	for (NMMovieDetailView * theView in movieDetailViewArray) {
		if ( theView.video ) {
			[self reclaimMovieDetailViewForVideo:theView.video];
		}
	}
}

- (NMMovieDetailView *)dequeueReusableMovieDetailView {
	// obtain a free view
	CGRect theFrame;
	NSBundle * mb = [NSBundle mainBundle];
	if ( movieDetailViewArray == nil ) {
		// we need to load a few detail view
		// pre-load the movie detail view. we need to cache 3 of them so that user can see the current, next and previous movie detail with smooth scrolling transition
		movieDetailViewArray = [[NSMutableArray alloc] initWithCapacity:3];
		for (NSInteger i = 0; i < 3; i++) {
			[mb loadNibNamed:@"MovieDetailInfoView" owner:self options:nil];
			[movieDetailViewArray addObject:self.loadedMovieDetailView];
			theFrame = loadedMovieDetailView.frame;
			theFrame.origin.y = 0.0f;
			theFrame.origin.x = -NM_IPAD_SCREEN_WIDTH;
			loadedMovieDetailView.frame = theFrame;
			[controlScrollView insertSubview:loadedMovieDetailView belowSubview:movieView];
			self.loadedMovieDetailView = nil;
			// movie detail view doesn't need to respond to autoresize
		}
	}
	// get a free view
	for ( NMMovieDetailView * theView in movieDetailViewArray ) {
		if ( theView.video == nil ) {
			theView.alpha = 1.0f;
			return theView;
		}
	}
	// check if any of the video is marked as error
	// this for-loop does NOT guarantee to run. Sometimes, we can get free movie detail view even if there's movie detail view occupied by bad videos.
	for ( NMMovieDetailView * theView in movieDetailViewArray ) {
		if ( theView.video.nm_playback_status == NMVideoQueueStatusError ) {
			[self reclaimMovieDetailViewForVideo:theView.video];
			theView.alpha = 1.0f;
			return theView;
		}
	}
	NSLog(@"Problem!! can't get a free movie detail view");
	return nil;
}

- (void)reclaimMovieDetailViewForVideo:(NMVideo *)vdo {
	if ( vdo == nil ) return;
	NMMovieDetailView * theView = vdo.nm_movie_detail_view;
	if ( theView == nil ) return;
	vdo.nm_movie_detail_view = nil;
	theView.video = nil;
	[theView restoreThumbnailView];
	[theView setActivityViewHidden:YES];
	theView.alpha = 0.0f;
}

- (void)cleanUpBadVideosMovieDetailView {
	// it's possible that some bad videos still occupy a movie detail view. We need to make sure all movie detail views are not associated to any bad videos.
	for ( NMMovieDetailView * theView in movieDetailViewArray ) {
		if ( theView.video && theView.video.nm_playback_status == NMVideoQueueStatusError ) {
			[self reclaimMovieDetailViewForVideo:theView.video];
		}
	}
}

#pragma mark Ribbon management

- (void)updateRibbonButtons {
	[self updateFavoriteButton];
	if ( favoriteButton.alpha < 1.0f ) {
		favoriteButton.alpha = 1.0f;
	}
	[self updateWatchLaterButton];
	if ( watchLaterButton.alpha < 1.0f ) {
		watchLaterButton.alpha = 1.0f;
	}
}

- (void)updateFavoriteButton {
	// configure ribbon views in Full Screen control view and the ribbon view
	NMVideo * vdo = playbackModelController.currentVideo;
	
	// make the buttons respond to tapping
	favoriteButton.userInteractionEnabled = YES;
	loadedControlView.favoriteButton.userInteractionEnabled = YES;
	
	if ( [vdo.nm_favorite boolValue] ) {
		// update image
		[favoriteButton setImage:styleUtility.favoriteActiveImage forState:UIControlStateNormal];
		[favoriteButton setImage:styleUtility.favoriteImage forState:UIControlStateHighlighted];
		[favoriteButton setImage:styleUtility.favoriteImage forState:UIControlStateSelected];
		[loadedControlView.favoriteButton setImage:styleUtility.favoriteActiveImage forState:UIControlStateNormal];
		[loadedControlView.favoriteButton setImage:styleUtility.favoriteImage forState:UIControlStateHighlighted];
		[loadedControlView.favoriteButton setImage:styleUtility.favoriteImage forState:UIControlStateSelected];
	} else {
		// update image
		[favoriteButton setImage:styleUtility.favoriteImage forState:UIControlStateNormal];
		[favoriteButton setImage:styleUtility.favoriteActiveImage forState:UIControlStateHighlighted];
		[favoriteButton setImage:styleUtility.favoriteActiveImage forState:UIControlStateSelected];
		[loadedControlView.favoriteButton setImage:styleUtility.favoriteImage forState:UIControlStateNormal];
		[loadedControlView.favoriteButton setImage:styleUtility.favoriteActiveImage forState:UIControlStateHighlighted];
		[loadedControlView.favoriteButton setImage:styleUtility.favoriteActiveImage forState:UIControlStateSelected];
	}
	if ( favoriteButton.selected ) {
		favoriteButton.selected = NO;
		loadedControlView.favoriteButton.selected = NO;
	}
}

- (void)updateWatchLaterButton {
	// configure ribbon views in Full Screen control view and the ribbon view
	NMVideo * vdo = playbackModelController.currentVideo;
	
	// make the buttons respond to tapping
	watchLaterButton.userInteractionEnabled = YES;
	loadedControlView.watchLaterButton.userInteractionEnabled = YES;
	
	if ( [vdo.nm_watch_later boolValue] ) {
		// update image
		[watchLaterButton setImage:styleUtility.watchLaterActiveImage forState:UIControlStateNormal];
		[watchLaterButton setImage:styleUtility.watchLaterImage forState:UIControlStateHighlighted];
		[watchLaterButton setImage:styleUtility.watchLaterImage forState:UIControlStateSelected];
		[loadedControlView.watchLaterButton setImage:styleUtility.watchLaterActiveImage forState:UIControlStateNormal];
		[loadedControlView.watchLaterButton setImage:styleUtility.watchLaterImage forState:UIControlStateHighlighted];
		[loadedControlView.watchLaterButton setImage:styleUtility.watchLaterImage forState:UIControlStateSelected];
	} else {
		// update image
		[watchLaterButton setImage:styleUtility.watchLaterImage forState:UIControlStateNormal];
		[watchLaterButton setImage:styleUtility.watchLaterActiveImage forState:UIControlStateHighlighted];
		[watchLaterButton setImage:styleUtility.watchLaterActiveImage forState:UIControlStateSelected];
		[loadedControlView.watchLaterButton setImage:styleUtility.watchLaterImage forState:UIControlStateNormal];
		[loadedControlView.watchLaterButton setImage:styleUtility.watchLaterActiveImage forState:UIControlStateHighlighted];
		[loadedControlView.watchLaterButton setImage:styleUtility.watchLaterActiveImage forState:UIControlStateSelected];
	}
	if ( watchLaterButton.selected ) {
		watchLaterButton.selected = NO;
		loadedControlView.watchLaterButton.selected = NO;
	}
}

- (void)animateFavoriteButtonsToInactive {
	favoriteButton.selected = YES;
	favoriteButton.userInteractionEnabled = NO;
	loadedControlView.favoriteButton.selected = YES;
	loadedControlView.favoriteButton.userInteractionEnabled = NO;
	
	[UIView beginAnimations:nil context:nil];
	favoriteButton.alpha = 0.25f;
	loadedControlView.favoriteButton.alpha = 0.25f;
	[UIView commitAnimations];
}

- (void)animateWatchLaterButtonsToInactive {
	watchLaterButton.selected = YES;
	watchLaterButton.userInteractionEnabled = NO;
	loadedControlView.watchLaterButton.selected = YES;
	loadedControlView.watchLaterButton.userInteractionEnabled = NO;
	
	[UIView beginAnimations:nil context:nil];
	watchLaterButton.alpha = 0.25f;
	loadedControlView.watchLaterButton.alpha = 0.25f;
	[UIView commitAnimations];
}

- (void)animateFavoriteButtonsToActive {
	[UIView beginAnimations:nil context:(void *)NM_ANIMATION_FAVORITE_BUTTON_ACTIVE_CONTEXT];
	favoriteButton.alpha = 1.0f;
	loadedControlView.favoriteButton.alpha = 1.0f;
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView commitAnimations];
}

- (void)animateWatchLaterButtonsToActive {
	[UIView beginAnimations:nil context:(void *)NM_ANIMATION_WATCH_LATER_BUTTON_ACTIVE_CONTEXT];
	watchLaterButton.alpha = 1.0f;
	loadedControlView.watchLaterButton.alpha = 1.0f;
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView commitAnimations];
}

#pragma mark Video queuing
- (void)showNextVideo:(BOOL)aEndOfVideo {
	// called when we need to switch to next video triggered by finished playing the current video or 
	if ( playbackModelController.nextVideo == nil ) {
		// there's no more video available
		//TODO: get more video here. issue fetch video list request
		
		return;
	}
	// send tracking event
	NMVideo * theVideo = [self playerCurrentVideo];
	[nowboxTaskController issueSendViewEventForVideo:theVideo start:lastStartTime elapsedSeconds:loadedControlView.timeElapsed - lastStartTime];
	// visually transit to next video just like the user has tapped next button
	//if ( aEndOfVideo ) {
	// disable interface scrolling
	// will activate again on "currentItem" change kvo notification
//	controlScrollView.scrollEnabled = NO;
	// fade out the view
	[UIView animateWithInteractiveDuration:0.75f animations:^(void) {
		movieView.alpha = 0.0f;
	} completion:^(BOOL finished) {
		currentXOffset += NM_IPAD_SCREEN_WIDTH;
		// scroll to next video
		// translate the movie view
		[UIView animateWithInteractiveDuration:0.5f animations:^{
			controlScrollView.contentOffset = CGPointMake(currentXOffset, 0.0f);
		}];
		[self reclaimMovieDetailViewForVideo:playbackModelController.previousVideo];
		if ( [playbackModelController moveToNextVideo] ) {
			playbackModelController.previousVideo.nm_did_play = [NSNumber numberWithBool:YES];
			[movieView.player advanceToVideo:playbackModelController.currentVideo];
            
            [self updateRibbonButtons];
            
            [[MixpanelAPI sharedAPI] track:AnalyticsEventPlayVideo properties:[NSDictionary dictionaryWithObjectsAndKeys:playbackModelController.channel.title, AnalyticsPropertyChannelName, 
                                                                               playbackModelController.currentVideo.title, AnalyticsPropertyVideoName, 
                                                                               playbackModelController.currentVideo.nm_id, AnalyticsPropertyVideoId,
                                                                               @"player", AnalyticsPropertySender, 
                                                                               @"auto", AnalyticsPropertyAction, 
                                                                               [NSNumber numberWithBool:NM_AIRPLAY_ACTIVE], AnalyticsPropertyAirPlayActive, nil]];
		}
	}];
	// when traisition is done. move shift the scroll view and reveals the video player again
	// this method does not handle the layout (position) of the movie control. that should be handled in scroll view delegate method
}

- (void)playVideo:(NMVideo *)aVideo {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	// report event
	[nowboxTaskController issueSendViewEventForVideo:playbackModelController.currentVideo start:lastStartTime elapsedSeconds:loadedControlView.timeElapsed - lastStartTime];

	// Channel View calls this method when user taps a video from the table
	// stop video
	[self stopVideo];
	// flush the video player
	[movieView.player removeAllItems];	// optimize for skipping to next or next-next video. Do not call this method those case
	// removeAllItems cannot always remove all items. This happens when there's bad videos during resolution. To avoid movie detail view problem, we reclaim the view again
	[self resetAllMovieDetailViews];
	didSkippedVideo = YES;

	// save the channel ID to user defaults
	[appDelegate saveChannelID:aVideo.channel.nm_id];
	// play the specified video
	ribbonView.alpha = 0.15;	// set alpha before calling "setVideo" method
	ribbonView.userInteractionEnabled = NO;
	NMChannel * chnObj = aVideo.channel;
	if ( ![currentChannel isEqual:chnObj] ) {
		if ( currentChannel ) [currentChannel release];
		currentChannel = [chnObj retain];
		chnObj.nm_is_new = (NSNumber *)kCFBooleanFalse;
	}
	[playbackModelController setVideo:aVideo];
	forceStopByUser = NO;
	[loadedControlView resetView];
	[pool release];
}

- (void)launchPlayVideo:(NMVideo *)aVideo {
	// a dedicated method for setting video to play when the app is being launched. This method avoids calling AVQueuePlayer removeAllItems.
	// show progress indicator
//	[movieView setActivityIndicationHidden:NO animated:NO];
	// save the channel ID to user defaults
	[appDelegate saveChannelID:aVideo.channel.nm_id];
	// play the specified video
	[playbackModelController setVideo:aVideo];
}

#pragma mark VideoPlaybackModelController delegate methods

- (void)didLoadNextNextVideoManagedObjectForController:(VideoPlaybackModelController *)ctrl {
	// queue this video
	if ( !NMVideoPlaybackViewIsScrolling ) [movieView.player resolveAndQueueVideo:ctrl.nextNextVideo];
}

- (void)didLoadNextVideoManagedObjectForController:(VideoPlaybackModelController *)ctrl {
	// update the movie detail view frame
	NMMovieDetailView * theDetailView = ctrl.nextVideo.nm_movie_detail_view;
	if ( theDetailView == nil ) {
		theDetailView = [self dequeueReusableMovieDetailView];
		ctrl.nextVideo.nm_movie_detail_view = theDetailView;
	}
	theDetailView.video = ctrl.nextVideo;
	
	CGFloat xOffset = (CGFloat)(ctrl.nextIndexPath.row * NM_IPAD_SCREEN_WIDTH_INT);
#ifdef DEBUG_PLAYER_NAVIGATION
	NSLog(@"offset of next MDV: %f ptr: %p", xOffset, theDetailView);
#endif
	CGRect theFrame = theDetailView.frame;
	if ( theFrame.origin.x != xOffset ) {
		theFrame.origin.x = xOffset;
		theDetailView.frame = theFrame;
	}
	// resolve the URL
	if ( !NMVideoPlaybackViewIsScrolling ) [movieView.player resolveAndQueueVideo:ctrl.nextVideo];
}

- (void)didLoadPreviousVideoManagedObjectForController:(VideoPlaybackModelController *)ctrl {
	NMMovieDetailView * theDetailView = ctrl.previousVideo.nm_movie_detail_view;
	if ( theDetailView == nil ) {
		theDetailView = [self dequeueReusableMovieDetailView];
		ctrl.previousVideo.nm_movie_detail_view = theDetailView;
	}
	theDetailView.video = ctrl.previousVideo;
	
	CGFloat xOffset = (CGFloat)(ctrl.previousIndexPath.row * NM_IPAD_SCREEN_WIDTH_INT);
#ifdef DEBUG_PLAYER_NAVIGATION
	NSLog(@"offset of previous MDV: %f ptr: %p", xOffset, theDetailView);
#endif
	CGRect theFrame = theDetailView.frame;
	if ( theFrame.origin.x != xOffset ) {
		theFrame.origin.x = xOffset;
		theDetailView.frame = theFrame;
	}
	// resolve the URL
	if ( !NMVideoPlaybackViewIsScrolling ) [movieView.player resolveAndQueueVideo:ctrl.previousVideo];
}

- (void)didLoadCurrentVideoManagedObjectForController:(VideoPlaybackModelController *)ctrl {
	NMMovieDetailView * theDetailView = ctrl.currentVideo.nm_movie_detail_view;
	if ( theDetailView == nil ) {
		theDetailView = [self dequeueReusableMovieDetailView];
		ctrl.currentVideo.nm_movie_detail_view = theDetailView;
	}
	theDetailView.video = ctrl.currentVideo;
	
	CGFloat xOffset = (CGFloat)(ctrl.currentIndexPath.row * NM_IPAD_SCREEN_WIDTH_INT);
#ifdef DEBUG_PLAYER_NAVIGATION
	NSLog(@"offset of current MDV: %f actual: %f ptr: %p, %@", xOffset, theDetailView.frame.origin.x, theDetailView, ctrl.currentVideo.title);
#endif
	CGRect theFrame = theDetailView.frame;
	if ( theFrame.origin.x != xOffset ) {
		theFrame.origin.x = xOffset;
		theDetailView.frame = theFrame;
	}
	// when scrolling is inflight, do not issue the URL resolution request. Playback View Controller will call "advanceToNextVideo" later on which will trigger sending of resolution request.
	if ( !NMVideoPlaybackViewIsScrolling ) [movieView.player resolveAndQueueVideo:ctrl.currentVideo];
}

- (void)controller:(VideoPlaybackModelController *)ctrl didUpdateVideoListWithTotalNumberOfVideo:(NSUInteger)totalNum {
#ifdef DEBUG_PLAYBACK_QUEUE
	NSLog(@"current total num videos: %d", totalNum);
#endif

	controlScrollView.contentSize = CGSizeMake((CGFloat)(NM_IPAD_SCREEN_WIDTH_INT * totalNum), 380.0f);
	CGFloat newOffset = (CGFloat)(playbackModelController.currentIndexPath.row * NM_IPAD_SCREEN_WIDTH_INT);
	if ( totalNum ) {
		if ( currentXOffset != newOffset ) {
#ifdef DEBUG_PLAYBACK_QUEUE
			NSLog(@"current idx: %d video: %@", playbackModelController.currentIndexPath.row, playbackModelController.currentVideo.title);
#endif
			// update offset
			currentXOffset = newOffset;
			// move over to the new location
//			[UIView animateWithInteractiveDuration:0.5f animations:^{
				controlScrollView.contentOffset = CGPointMake(currentXOffset, 0.0f);
			CGRect theFrame = movieView.frame;
			theFrame.origin.x = currentXOffset;
			movieView.frame = theFrame;
			loadedControlView.frame = theFrame;
//			} completion:^(BOOL finished) {
				[self performSelector:@selector(delayRestoreDetailView) withObject:nil afterDelay:0.5];
//			}];
		} else {
			[self performSelector:@selector(delayRestoreDetailView) withObject:nil afterDelay:0.5];
		}
		[self cleanUpBadVideosMovieDetailView];
	}
}

- (void)shouldRevertNextNextVideoToNewStateForController:(VideoPlaybackModelController *)ctrl {
	[movieView.player refreshItemFromIndex:2];
	[playbackModelController.nextNextVideo.nm_movie_detail_view restoreThumbnailView];
}

- (void)shouldRevertNextVideoToNewStateForController:(VideoPlaybackModelController *)ctrl {
	[movieView.player refreshItemFromIndex:1];
	[playbackModelController.nextVideo.nm_movie_detail_view restoreThumbnailView];
}

- (void)shouldRevertCurrentVideoToNewStateForController:(VideoPlaybackModelController *)ctrl {
	[self stopVideo];
	// request the player to resolve the video again
	[movieView.player refreshItemFromIndex:0];
	// lock the playback view?
//	controlScrollView.scrollEnabled = NO;
	// show thumbnail and loading indicator
	shouldFadeOutVideoThumbnail = YES;
	[self showActivityLoader];
	[self.currentVideo.nm_movie_detail_view restoreThumbnailView];
	movieView.alpha = 0.0f;
}

#pragma mark NMAVQueuePlayerPlaybackDelegate methods

- (void)player:(NMAVQueuePlayer *)aPlayer observePlayerItem:(AVPlayerItem *)anItem {
#ifdef DEBUG_PLAYBACK_QUEUE
	NMAVPlayerItem * theItem = (NMAVPlayerItem *)anItem;
	NSLog(@"KVO observing: %@", theItem.nmVideo.title);
#endif
	// observe property of the current item
	[anItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:0 context:(void *)NM_PLAYBACK_LIKELY_TO_KEEP_UP_CONTEXT];
	[anItem addObserver:self forKeyPath:@"loadedTimeRanges" options:0 context:(void *)NM_PLAYBACK_LOADED_TIME_RANGES_CONTEXT];
//	[anItem addObserver:self forKeyPath:@"status" options:0 context:(void *)NM_PLAYER_ITEM_STATUS_CONTEXT];
	// no need to update status of NMVideo. "Queued" status is updated in "queueVideo" method
}

- (void)player:(NMAVQueuePlayer *)aPlayer stopObservingPlayerItem:(AVPlayerItem *)anItem {
#ifdef DEBUG_PLAYBACK_QUEUE
	NMAVPlayerItem * theItem = (NMAVPlayerItem *)anItem;
	if ( theItem.nmVideo ) {
		NSLog(@"KVO stop observing: %@", theItem.nmVideo.title);
	} else {
		NSLog(@"KVO observing object is nil");
	}
#endif
	NMVideo * vdo = ((NMAVPlayerItem *)anItem).nmVideo;
	if ( vdo == nil ) return;
	if ( [vdo.nm_error integerValue] == NMErrorNone ) {
		vdo.nm_playback_status = NMVideoQueueStatusPlayed;
	} else {
		vdo.nm_playback_status = NMVideoQueueStatusError;
	}
	[anItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
	[anItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
//	[anItem removeObserver:self forKeyPath:@"status"];
}

//- (void)player:(NMAVQueuePlayer *)aPlayer directURLResolutionErrorForVideo:(NMVideo *)aVideo {
//	[playbackModelController ]
//}

- (void)player:(NMAVQueuePlayer *)aPlayer willBeginPlayingVideo:(NMVideo *)vid {
    if (pendingToolTip) {
        [[ToolTipController sharedToolTipController] presentToolTip:pendingToolTip inView:self.view];
        pendingToolTip = nil;
    }
}

- (NMVideo *)currentVideoForPlayer:(NMAVQueuePlayer *)aPlayer {
	return playbackModelController.currentVideo;
}

- (NMVideo *)nextVideoForPlayer:(NMAVQueuePlayer *)aPlayer {
	return playbackModelController.nextVideo;
}

- (NMVideo *)nextNextVideoForPlayer:(NMAVQueuePlayer *)aPlayer {
	return playbackModelController.nextNextVideo;
}

#pragma mark Notification handling
//- (void)delayHandleDidPlayItem:(NMAVPlayerItem *)anItem {
//	if ( playbackModelController.nextVideo == nil ) {
//		// finish up playing the whole channel
//		[self dismissModalViewControllerAnimated:YES];
//	} else {
//		[self showNextVideo:YES];
//	}
//}

- (void)handleDidPlayItemNotification:(NSNotification *)aNotification {
	// For unknown reason, AVPlayerItemDidPlayToEndTimeNotification is sent twice sometimes. Don't know why. This delay execution mechanism tries to solve this problem
#ifdef DEBUG_PLAYBACK_QUEUE
	NSLog(@"did play notification: %p", [aNotification object]);
#endif
	didPlayToEnd = YES;
    
    void (^completion)(void) = ^{
        if (playbackModelController.nextVideo) {
			[self showNextVideo:YES];
		}
    };
    
	// according to documentation, AVPlayerItemDidPlayToEndTimeNotification is not guaranteed to be fired from the main thread.
	dispatch_async(dispatch_get_main_queue(), ^{
        if ([self shouldShowRateUsReminder] && [(ipadAppDelegate *)appDelegate timeOnAppSinceInstall] > NM_RATE_US_REMINDER_MINIMUM_TIME_ON_APP * (NM_RATE_US_REMINDER_DEFER_COUNT + 1)) {
            [self showRateUsReminderCompletion:completion];
        } else {
            completion();
        }
	});
}

- (void)handleApplicationDidBecomeActiveNotification:(NSNotification *)aNotification {
	if (launchModeActive) {
        return;
    }
    
	// resume playing the video
	[self playCurrentVideo];
	NMAVPlayerItem * item = (NMAVPlayerItem *)movieView.player.currentItem;
	// send event back to server
	if ( item ) {
		[nowboxTaskController issueSendViewEventForVideo:item.nmVideo elapsedSeconds:loadedControlView.timeElapsed playedToEnd:NO];
	}
}

- (void)handleApplicationDidEnterBackgroundNotification:(NSNotification *)aNotification {
	if ( !NM_AIRPLAY_ACTIVE ) {
		[self stopVideo];
	}
	//Debug: set the video link to expire
//	playbackModelController.currentVideo.nm_direct_url_expiry = (NSInteger)[[NSDate dateWithTimeIntervalSinceNow:-1000.0] timeIntervalSince1970];
}

- (void)handleChannelManagementNotification:(NSNotification *)aNotification {
	if ( NM_RUNNING_IOS_5 ) {
		if ( [[aNotification name] isEqualToString:NMChannelManagementWillAppearNotification] ) {
            videoWasPaused = (movieView.player.rate == 0.0);

			// stop video from playing
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_4_3
			if ( !movieView.player.airPlayVideoActive ) {
				forceStopByUser = YES;
				[self stopVideo];	
			}
#endif
		} else {
			// resume video playing
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_4_3
			if ( !movieView.player.airPlayVideoActive && !videoWasPaused ) {
				forceStopByUser = NO;
				[self playCurrentVideo];
			}
#endif
		}
	} else {
		if ( [[aNotification name] isEqualToString:NMChannelManagementWillAppearNotification] ) { 
            videoWasPaused = (movieView.player.rate == 0.0);

			// stop video from playing
			[self stopVideo];
		} else {
            if (!videoWasPaused) {
                forceStopByUser = NO;
                // resume video playing
                [self playCurrentVideo];
            }
		}
	}
}

- (void)handleGetChannelsNotification:(NSNotification *)aNotification {
	NSDictionary * info = [aNotification userInfo];
	if ( [[info objectForKey:@"total_channel"] unsignedIntegerValue] == 0 && NM_USER_YOUTUBE_SYNC_ACTIVE ) {
		// there's no channels from the server
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"It appears that you have all YouTube channels unsubscribed. NOWBOX will preserve all your channels. You can manage your channels through Channel Management View" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        [alertView release];
	}
}

- (void)handleVideoEventNotification:(NSNotification *)aNotification {
	// check it's the current, previous or next video
	NMVideo * vidObj = [[aNotification userInfo] objectForKey:@"video"];
	NSString * name = [aNotification name];
    
	if ( [name isEqualToString:NMDidShareVideoNotification] ) {
		// favorited a video successfully, animate the icon to appropriate state
		[self animateFavoriteButtonsToActive];
        [[ToolTipController sharedToolTipController] notifyEvent:ToolTipEventFavoriteTap sender:nil];        
    } else if ( [name isEqualToString:NMDidUnfavoriteVideoNotification] ) {
        // unfavorited a video
        [self animateFavoriteButtonsToActive];
    } else if ( [name isEqualToString:NMDidPostSharingNotification] && [playbackModelController.currentVideo isEqual:vidObj] ) {
        // shared a video
        [self animateFavoriteButtonsToActive];
    } else if ( [name isEqualToString:NMDidEnqueueVideoNotification] && [playbackModelController.currentVideo isEqual:vidObj] ) {
		// queued a video successfully, animate the icon to appropriate state
		[self animateWatchLaterButtonsToActive];
        [[ToolTipController sharedToolTipController] notifyEvent:ToolTipEventWatchLaterTap sender:nil];
	} else if ( [name isEqualToString:NMDidDequeueVideoNotification] && [playbackModelController.currentVideo isEqual:vidObj] ) {
		// dequeued a video successfully
		[self animateWatchLaterButtonsToActive];
	}
}

- (void)handleDidGetInfoNotification:(NSNotification *)aNotification {
    NSDictionary *userInfo = [aNotification userInfo];    
    NSArray *links = [userInfo objectForKey:@"links"];
    for (NSDictionary *link in links) {
        if ([[link objectForKey:@"rel"] isEqualToString:@"ratings"]) {
            self.ratingsURL = [NSURL URLWithString:[link objectForKey:@"url"]];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	NSInteger c = (NSInteger)context;
//	CMTime t;
	if ( c == NM_PLAYER_STATUS_CONTEXT ) {
		switch (movieView.player.status) {
			case AVPlayerStatusReadyToPlay:
			{
				shouldFadeOutVideoThumbnail = YES;
				break;
			}
			case AVPlayerStatusFailed:
			{
				controlScrollView.scrollEnabled = YES;
				break;
			}
			default:
				break;
		}
	} else if ( c == NM_PLAYER_CURRENT_ITEM_CONTEXT ) {
		shouldFadeOutVideoThumbnail = YES;
		lastTimeElapsed = 0, lastStartTime = 0;
		// update video status
		NMAVPlayerItem * curItem = (NMAVPlayerItem *)movieView.player.currentItem;
		curItem.nmVideo.nm_playback_status = NMVideoQueueStatusCurrentVideo;
		// never change currentIndex here!!
		// ====== update interface ======
//		[self configureControlViewForVideo:[self playerCurrentVideo]]; moved to animation delegate
		// update the time

		// show the control view
		// fix ticket https://pipely.lighthouseapp.com/projects/77614/tickets/468
//		[loadedControlView setControlsHidden:NO animated:YES];
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showActivityLoader) object:nil];
		
		showMovieControlTimestamp = 1;
		
		[self performSelector:@selector(showActivityLoader) withObject:nil afterDelay:1.25];
		
		if ( didPlayToEnd ) {
//			controlScrollView.scrollEnabled = YES;
			didPlayToEnd = NO;
		}
		if ( playbackModelController.currentVideo ) {
#ifdef DEBUG_SESSION
			NSLog(@"Session ID of current video: %@", playbackModelController.currentVideo.nm_session_id);
#endif
			[defaultNotificationCenter postNotificationName:NMWillBeginPlayingVideoNotification object:self userInfo:[NSDictionary dictionaryWithObject:playbackModelController.currentVideo forKey:@"video"]];
		}
		// set the initial buffering progress. this is important. It's possible that a video is fully buffered. In this case, player will not post any KVO on loadedTimeRanges.
	} else if ( c == NM_AIR_PLAY_VIDEO_ACTIVE_CONTEXT ) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_4_3
		if ( movieView.player.airPlayVideoActive ) {
			// update the player interface to indicate that Airplay has been enabled
			[movieView hideAirPlayIndicatorView:NO];
			NM_AIRPLAY_ACTIVE = YES;
            
            // Disable idle timer so that the app doesn't go to sleep
            [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
            
			// Apple TV does not send remote event back to app. No need to implement for now.
			// receive remote event
//			[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
//			[self becomeFirstResponder];
		} else {
			// remove the interface indication
			[movieView hideAirPlayIndicatorView:YES];
			NM_AIRPLAY_ACTIVE = NO;
            
            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];

			// Apple TV does not send remote event back to app. No need to implement for now.
//			[[UIApplication sharedApplication] endReceivingRemoteControlEvents];
//			[self resignFirstResponder];
		}
#endif
	}
	// refer to https://pipely.lighthouseapp.com/projects/77614/tickets/93-study-video-switching-behavior-how-to-show-loading-ui-state
	else if ( c == NM_PLAYBACK_LIKELY_TO_KEEP_UP_CONTEXT ) {
		// ignore buffer condition when user explicity mean to stop video or when we play to the end of a video and in transition to the next one
		if ( !forceStopByUser && !didPlayToEnd ) {
			NMAVPlayerItem * theItem = (NMAVPlayerItem *)object;
			if ( theItem.playbackLikelyToKeepUp && movieView.player.rate == 0.0f && !self.modalViewController ) {
				[self playCurrentVideo];
			}
		}
//		NSLog(@"%@ buffer status - keep up: %d full: %d", theItem.nmVideo.title, theItem.playbackLikelyToKeepUp, theItem.playbackBufferFull);
//	} else if ( c == NM_PLAYER_ITEM_STATUS_CONTEXT ) {
//		NMAVPlayerItem * theItem = (NMAVPlayerItem *)object;
//		NSLog(@"%@ status: %d", theItem.nmVideo.title, theItem.status);
	} else if ( c == NM_PLAYER_RATE_CONTEXT ) {
		// NOTE:
		// AVQueuePlayer may not post any KVO notification to us on "rate" change.
		CGFloat theRate = movieView.player.rate;
		if ( (!playFirstVideoOnLaunchWhenReady || forceStopByUser) && theRate > 0.0 ) {
			[self stopVideo];
			[loadedControlView setPlayButtonStateForRate:0.0f];
		} else if ( !didPlayToEnd ) {
			[loadedControlView setPlayButtonStateForRate:theRate];
		}
	} else if ( c == NM_PLAYBACK_LOADED_TIME_RANGES_CONTEXT ) {
		if ( object == movieView.player.currentItem ) {
			// buffering progress
			NMAVPlayerItem * theItem = (NMAVPlayerItem *)object;
			NSValue * theRangeValue = [theItem.loadedTimeRanges lastObject];
			if ( theRangeValue ) {
				loadedControlView.timeRangeBuffered = [theRangeValue CMTimeRangeValue];
				if ( shouldFadeOutVideoThumbnail ) {
					shouldFadeOutVideoThumbnail = NO;
					[theItem.nmVideo.nm_movie_detail_view fadeOutThumbnailView:self context:(void *)NM_ANIMATION_VIDEO_THUMBNAIL_CONTEXT];
				}
			}
		}
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark Playback view UI update
- (void)delayRestoreDetailView {
	// update which video the buttons hook up to
	[self updateRibbonButtons];
	[UIView animateWithInteractiveDuration:0.25f animations:^{
		ribbonView.alpha = 1.0f;
	}];
	ribbonView.userInteractionEnabled = YES;
}

- (void)configureDetailViewForContext:(NSInteger)ctx {
	NMMovieDetailView * curDetailView = playbackModelController.currentVideo.nm_movie_detail_view;
	switch (ctx) {
		case NM_ANIMATION_SPLIT_VIEW_CONTEXT:
			for (NMMovieDetailView * dtlView in movieDetailViewArray) {
				// hide everything except the thumbnail view
				if ( dtlView != curDetailView ) {
					[dtlView configureMovieThumbnailForFullScreen:NO];
				}
			}
			[curDetailView resetLayoutAfterPinchedForFullScreen:NO];
			break;
			
		case NM_ANIMATION_FULL_PLAYBACK_SCREEN_CONTEXT:
			for (NMMovieDetailView * dtlView in movieDetailViewArray) {
				if ( dtlView != curDetailView ) {
					[dtlView configureMovieThumbnailForFullScreen:YES];
				}
			}
			[curDetailView resetLayoutAfterPinchedForFullScreen:YES];
			break;
			
		default:
			break;
	}
}
#pragma mark Popover delegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self playCurrentVideo];
}

#pragma mark Scroll View Delegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	forceStopByUser = NO;	// reset force stop variable when scrolling begins
	NMVideoPlaybackViewIsScrolling = YES;
	if ( NM_RUNNING_IOS_5 ) {
		[UIView animateWithInteractiveDuration:0.25f animations:^{
			ribbonView.alpha = 0.15;
		}];
		ribbonView.userInteractionEnabled = NO;
	} else {
		ribbonView.alpha = 0.15;
	}
	[loadedControlView setControlsHidden:YES animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	CGFloat dx;
	dx = ABS(currentXOffset - scrollView.contentOffset.x);
	// reduce alpha of the playback view
	movieView.alpha = (NM_IPAD_SCREEN_WIDTH - dx) / NM_IPAD_SCREEN_WIDTH;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	// this is for preventing user from flicking continuous. user has to flick through video one by one. scrolling will enable again in "scrollViewDidEndDecelerating"
#ifndef DEBUG_NO_VIDEO_PLAYBACK_VIEW
	scrollView.scrollEnabled = NO;
#endif
	// If user scrolls too fast, "scrollViewDidEndDecelerating:" may not be called. This happens when "decelerate" argument in this method is NO.
	if ( decelerate == NO ) {
		[self scrollViewDidEndDecelerating:scrollView];
//		scrollView.scrollEnabled = YES;
//		NMVideoPlaybackViewIsScrolling = NO;
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	// switch to the next/prev video
//	scrollView.scrollEnabled = YES; move to animation handler
	[nowboxTaskController issueSendViewEventForVideo:playbackModelController.currentVideo elapsedSeconds:loadedControlView.timeElapsed playedToEnd:NO];
	if ( scrollView.contentOffset.x > currentXOffset ) {
		// stop playing the video if user has scrolled to another video. This avoids the weird UX where there's sound of the previous video playing but the view is showing the thumbnail of the next video
		[self stopVideo];
		didSkippedVideo = YES;
		currentXOffset += NM_IPAD_SCREEN_WIDTH;
		// return the movie detail view
		[self reclaimMovieDetailViewForVideo:playbackModelController.previousVideo];
		if ( [playbackModelController moveToNextVideo] ) {
			playbackModelController.previousVideo.nm_did_play = [NSNumber numberWithBool:YES];
			[movieView.player advanceToVideo:playbackModelController.currentVideo];
			[self updateRibbonButtons];
			
            [[MixpanelAPI sharedAPI] track:AnalyticsEventPlayVideo properties:[NSDictionary dictionaryWithObjectsAndKeys:playbackModelController.channel.title, AnalyticsPropertyChannelName, playbackModelController.currentVideo.title, AnalyticsPropertyVideoName, playbackModelController.currentVideo.nm_id, AnalyticsPropertyVideoId, @"player", AnalyticsPropertySender, @"swipe", AnalyticsPropertyAction, [NSNumber numberWithBool:NM_AIRPLAY_ACTIVE], AnalyticsPropertyAirPlayActive, nil]];
		}
#ifdef DEBUG_PLAYER_NAVIGATION
		else
			NSLog(@"can't move to next video. no video!!");
#endif
	} else if ( scrollView.contentOffset.x < currentXOffset ) {
		[self stopVideo];
		didSkippedVideo = YES;
		currentXOffset -= NM_IPAD_SCREEN_WIDTH;
		[self reclaimMovieDetailViewForVideo:playbackModelController.nextVideo];
		if ( playbackModelController.previousVideo ) {
			// instruct the data model to rearrange itself
			[playbackModelController moveToPreviousVideo];
			playbackModelController.nextVideo.nm_did_play = [NSNumber numberWithBool:YES];
			// update the queue player
			[movieView.player revertToVideo:playbackModelController.currentVideo];
			[self updateRibbonButtons];
            
            [[MixpanelAPI sharedAPI] track:AnalyticsEventPlayVideo properties:[NSDictionary dictionaryWithObjectsAndKeys:playbackModelController.channel.title, AnalyticsPropertyChannelName, playbackModelController.currentVideo.title, AnalyticsPropertyVideoName, playbackModelController.currentVideo.nm_id, AnalyticsPropertyVideoId, @"player", AnalyticsPropertySender, @"swipe", AnalyticsPropertyAction, [NSNumber numberWithBool:NM_AIRPLAY_ACTIVE], AnalyticsPropertyAirPlayActive, nil]];
		}
	}
	scrollView.scrollEnabled = YES;
	NMVideoPlaybackViewIsScrolling = NO;
	// ribbon fade in transition
	[UIView animateWithInteractiveDuration:0.25f animations:^{
		ribbonView.alpha = 1.0f;
	}];
	ribbonView.userInteractionEnabled = YES;
}

#pragma mark Gesture delegate methods
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	controlScrollView.scrollEnabled = NO;
	return YES;
}

#pragma mark Target-action methods

- (IBAction)toggleChannelPanel:(id)sender {
	CGRect theFrame;
	theFrame = channelController.panelView.frame;
	BOOL panelHidden = YES;
	if ( theFrame.origin.y < 768.0 ) {
		// assume the panel is visible
		panelHidden = NO;
	}
    
    NSString *senderStr;
    if ([sender isKindOfClass:[UIButton class]]) {
        senderStr = @"button";
    } else {
        senderStr = @"pinch";
    }

	CGRect viewRect;
	
	[UIView beginAnimations:nil context:(panelHidden ? (void *)NM_ANIMATION_SPLIT_VIEW_CONTEXT : (void *)NM_ANIMATION_FULL_PLAYBACK_SCREEN_CONTEXT)];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:0.5f];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView setAnimationDelegate:self];
	if ( panelHidden ) {
		// slide in the channel view with animation
//		movieXOffset = 0.0f;
		//MARK: not sure if we still need to show/hide status bar
		[[UIApplication sharedApplication] setStatusBarHidden:NO];
		viewRect = CGRectMake(movieView.frame.origin.x, 20.0f, 640.0f, 360.0f);
		movieView.frame = viewRect;
		// fade in detail view
		[playbackModelController.currentVideo.nm_movie_detail_view setLayoutWhenPinchedForFullScreen:NO];
		// slide in
		theFrame.origin.y = splitViewRect.size.height;
		channelController.panelView.frame = theFrame;
//		if ( launchModeActive ) {
//			// hide the progress label
//			launchController.progressContainerView.alpha = 0.0f;
//		}
        
        [[MixpanelAPI sharedAPI] registerSuperProperties:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AnalyticsPropertyFullScreenVideo]];
        [[MixpanelAPI sharedAPI] track:AnalyticsEventExitFullScreenVideo properties:[NSDictionary dictionaryWithObjectsAndKeys:currentChannel.title, AnalyticsPropertyChannelName,
                                                                                     playbackModelController.currentVideo.title, AnalyticsPropertyVideoName, 
                                                                                     senderStr, AnalyticsPropertySender, nil]];                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     


	} else {
		// slide out the channel view
		[[UIApplication sharedApplication] setStatusBarHidden:YES];
		viewRect = CGRectMake(movieView.frame.origin.x, 0.0f, 1024.0f, 768.0f);
		movieView.frame = viewRect;
		// fade out detail view
		[playbackModelController.currentVideo.nm_movie_detail_view setLayoutWhenPinchedForFullScreen:YES];
		// reset offset value
//		movieXOffset = 0.0f;
		ribbonView.alpha = 0.0f;
		// slide out
		theFrame.origin.y = 768.0;
		channelController.panelView.frame = theFrame;
        
        rowIndexToCenterOn = [channelController highlightedChannelIndex];

        [[MixpanelAPI sharedAPI] registerSuperProperties:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AnalyticsPropertyFullScreenVideo]];
        [[MixpanelAPI sharedAPI] track:AnalyticsEventEnterFullScreenVideo properties:[NSDictionary dictionaryWithObjectsAndKeys:currentChannel.title, AnalyticsPropertyChannelName,
                                                                                      playbackModelController.currentVideo.title, AnalyticsPropertyVideoName, 
                                                                                      senderStr, AnalyticsPropertySender, nil]];                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     

	}
	[UIView commitAnimations];
	if ( panelHidden ) {
		[loadedControlView setPlaybackMode:NMHalfScreenMode animated:NO];
		// unhide the ribbon view
		ribbonView.hidden = NO;
		// hide the top bar (no animation is needed)
		[loadedControlView setTopBarHidden:YES animated:NO];
		// animate showing of the ribbon
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDelay:0.2f];
		[UIView setAnimationDuration:0.3f];
		ribbonView.alpha = 1.0f;
		[UIView commitAnimations];
		// unhide all movie detail view
//		for (NMMovieDetailView * theDetailView in movieDetailViewArray) {
//			theDetailView.hidden = NO;
//			theDetailView.alpha = 1.0f;
//		}
		[self configureDetailViewForContext:NM_ANIMATION_SPLIT_VIEW_CONTEXT];
	} else {
		[loadedControlView setPlaybackMode:NMFullScreenPlaybackMode animated:NO];
		// panel is showing. i.e. we animate to Full Screen Playback Mode. We need to make sure the scrollview is occupying the full screen before animation begins.
		controlScrollView.frame = fullScreenRect;
	}
	// for the case of hiding the Channel View, we take the movie detail view away after the animation has finished.
//    pinchTemporarilyDisabled = NO;
}

- (IBAction)toggleChannelPanelFullScreen:(id)sender {
    CGRect theFrame;
	theFrame = channelController.panelView.frame;
    
	BOOL panelIsFullScreen = NO;
	if ( theFrame.origin.y < 380.0 ) {
		// assume the panel is full screen
		panelIsFullScreen = YES;
	}
    
    [self channelPanelToggleToFullScreen:!panelIsFullScreen resumePlaying:panelIsFullScreen centerToRow:[channelController highlightedChannelIndex]];
}

- (void)channelPanelToggleToFullScreen:(BOOL)shouldToggleToFullScreen resumePlaying:(BOOL)shouldResume centerToRow:(NSInteger)indexInTable {
    
    
    shouldResumePlayingVideoAfterTransition = shouldResume;
    rowIndexToCenterOn = indexInTable;
    
//    if (shouldToggleToFullScreen) {
//        [self stopVideo];
//    }
    
	CGRect theFrame = channelController.panelView.frame;
	CGRect scrollFrame = controlScrollView.frame;
	CGPoint rvPosition = ribbonView.center;
	
	[UIView beginAnimations:nil context:(void*)(shouldToggleToFullScreen ? NM_ANIMATION_FULL_SCREEN_CHANNEL_CONTEXT : NM_ANIMATION_SPLIT_VIEW_CONTEXT)];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:0.5f];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView setAnimationDelegate:self];
	if ( shouldToggleToFullScreen && channelController.displayMode != NMFullScreenChannelMode ) {
		NM_VIDEO_CONTENT_CELL_ALPHA_ZERO = YES;
		// move the channel panel up
		theFrame.origin.y = 20.0f;
		[channelController setDisplayMode:NMFullScreenChannelMode];
		scrollFrame.origin.y -= scrollFrame.size.height;
		rvPosition.y -= splitViewRect.size.height;
		ribbonView.center = rvPosition;
		[channelController postAnimationChangeForDisplayMode:NMFullScreenChannelMode];
        
        [[MixpanelAPI sharedAPI] registerSuperProperties:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AnalyticsPropertyFullScreenChannelPanel]];
        [[MixpanelAPI sharedAPI] track:AnalyticsEventEnterFullScreenChannelPanel properties:[NSDictionary dictionaryWithObjectsAndKeys:currentChannel.title, AnalyticsPropertyChannelName,
                                                                                             playbackModelController.currentVideo.title, AnalyticsPropertyVideoName,
                                                                                             nil]];                                                                                                                                                                                                                                                                                                                                                                        

	} else if ( !shouldToggleToFullScreen && channelController.displayMode != NMHalfScreenMode ) {
		// move the panel down
		theFrame.origin.y = splitViewRect.size.height;
		[channelController setDisplayMode:NMHalfScreenMode];
		scrollFrame.origin.y = splitViewRect.origin.y;
		rvPosition.y += splitViewRect.size.height;
		ribbonView.center = rvPosition;
		[channelController postAnimationChangeForDisplayMode:NMHalfScreenMode];
        
        [[MixpanelAPI sharedAPI] registerSuperProperties:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AnalyticsPropertyFullScreenChannelPanel]];        
        [[MixpanelAPI sharedAPI] track:AnalyticsEventExitFullScreenChannelPanel properties:[NSDictionary dictionaryWithObjectsAndKeys:currentChannel.title, AnalyticsPropertyChannelName,
                                                                                            playbackModelController.currentVideo.title, AnalyticsPropertyVideoName, nil]];                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     

	}
	channelController.panelView.frame = theFrame;
	controlScrollView.frame = scrollFrame;
    
	[UIView commitAnimations];
}

- (void)movieViewTouchUp:(UITapGestureRecognizer *)sender {
	[UIView animateWithInteractiveDuration:0.25f animations:^{
		loadedControlView.alpha = 1.0f;
	} completion:^(BOOL finished) {
		showMovieControlTimestamp = loadedControlView.timeElapsed;
	}];
}

- (void)movieViewDoubleTap:(id)sender {
	if ( loadedControlView.hidden ) {
		[self movieViewTouchUp:sender];
	}
	[self playStopVideo:sender];
}

- (void)controlsViewTouchUp:(id)sender {
	[UIView animateWithInteractiveDuration:0.25f animations:^{
		loadedControlView.alpha = 0.0f;
	}];
}

- (IBAction)shareVideo:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Share Video" 
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Email", @"Twitter", @"Facebook", nil];
        
    CGPoint point = [ribbonView convertPoint:shareButton.center toView:self.view];
    [actionSheet showFromRect:CGRectMake(point.x, ribbonView.frame.origin.y + ribbonView.frame.size.height + 1, 0, 0)
                       inView:self.view animated:YES];
}

- (IBAction)addVideoToFavorite:(id)sender {
    NMVideo *video = playbackModelController.currentVideo;

    showMovieControlTimestamp = loadedControlView.timeElapsed;
    
    [nowboxTaskController issueShare:![video.nm_favorite boolValue] video:video duration:loadedControlView.duration elapsedSeconds:loadedControlView.timeElapsed];
    [self animateFavoriteButtonsToInactive];

    [[MixpanelAPI sharedAPI] track:([video.nm_favorite boolValue] ? AnalyticsEventUnfavoriteVideo : AnalyticsEventFavoriteVideo)
                        properties:[NSDictionary dictionaryWithObjectsAndKeys:playbackModelController.channel.title, AnalyticsPropertyChannelName, 
                                    video.title, AnalyticsPropertyVideoName, 
                                    video.nm_id, AnalyticsPropertyVideoId,
                                    nil]];        
}

- (IBAction)addVideoToQueue:(id)sender {
	NMVideo * vdo = playbackModelController.currentVideo;
    
    showMovieControlTimestamp = loadedControlView.timeElapsed;

	[nowboxTaskController issueEnqueue:![vdo.nm_watch_later boolValue] video:playbackModelController.currentVideo];
	[self animateWatchLaterButtonsToInactive];
    
    [[MixpanelAPI sharedAPI] track:AnalyticsEventEnqueueVideo properties:[NSDictionary dictionaryWithObjectsAndKeys:playbackModelController.channel.title, AnalyticsPropertyChannelName, 
                                                                          playbackModelController.currentVideo.title, AnalyticsPropertyVideoName, 
                                                                          playbackModelController.currentVideo.nm_id, AnalyticsPropertyVideoId,
                                                                          nil]];
}

// seek bar
- (IBAction)seekPlaybackProgress:(id)sender {
	NMSeekBar * slider = (NMSeekBar *)sender;
	CMTime theTime = CMTimeMake((int64_t)slider.currentTime, 1);
	[movieView.player seekToTime:theTime];
	[loadedControlView updateSeekBubbleLocation];
}

- (IBAction)touchDownProgressBar:(id)sender {
	forceStopByUser = YES;
	[self stopVideo];
	showMovieControlTimestamp = -1;
	loadedControlView.isSeeking = YES;
	// get current control nub position
	[loadedControlView updateSeekBubbleLocation];
	// show seek bubble
	[UIView animateWithInteractiveDuration:0.25 animations:^{
		loadedControlView.seekBubbleButton.alpha = 1.0f;
		if ( NM_AIRPLAY_ACTIVE ) {
			// hide the airplay indicator
			movieView.airPlayIndicatorView.alpha = 0.0f;
		}
	}];
	lastTimeElapsed = loadedControlView.timeElapsed;
}

- (IBAction)touchUpProgressBar:(id)sender {
	forceStopByUser = NO;
	[self playCurrentVideo];
	loadedControlView.isSeeking = NO;
	showMovieControlTimestamp = loadedControlView.timeElapsed;
	[UIView animateWithInteractiveDuration:0.25 animations:^{
		loadedControlView.seekBubbleButton.alpha = 0.0f;
		if ( NM_AIRPLAY_ACTIVE ) {
			// show the airplay indicator
			movieView.airPlayIndicatorView.alpha = 1.0f;
		}
	}];
	// send the event
	[nowboxTaskController issueSendViewEventForVideo:playbackModelController.currentVideo start:lastStartTime elapsedSeconds:lastTimeElapsed - lastStartTime];
	lastStartTime = showMovieControlTimestamp;
}

# pragma mark Gestures
- (void)handleMovieViewPinched:(UIPinchGestureRecognizer *)sender {
	switch (sender.state) {
		case UIGestureRecognizerStateCancelled:
			controlScrollView.scrollEnabled = YES;
			break;
			
		case UIGestureRecognizerStateChanged:
		{
			if ( sender.velocity < -1.8 && sender.scale < 0.8 ) {
				detectedPinchAction = NM_SHOULD_TRANSIT_SPLIT_VIEW;
			} else if ( sender.velocity > 2.0 && sender.scale > 1.2 ) {
				detectedPinchAction = NM_SHOULD_TRANSIT_FULL_SCREEN_VIEW;
			}
			break;
		}
		case UIGestureRecognizerStateRecognized:
		{
			CGRect theFrame = channelController.panelView.frame;
			BOOL panelHidden = YES;
			if ( theFrame.origin.y < 768.0 ) {
				// assume the panel is visible
				panelHidden = NO;
			}
			
			if ( ( panelHidden && detectedPinchAction == NM_SHOULD_TRANSIT_SPLIT_VIEW ) || ( !panelHidden && detectedPinchAction == NM_SHOULD_TRANSIT_FULL_SCREEN_VIEW ) ) {
				[self toggleChannelPanel:sender.view];
			}
			controlScrollView.scrollEnabled = YES;
			break;
		}
			
		default:
			NSLog(@"Gesture state: %d", sender.state);
			break;
	}
}

#pragma mark - Rate Us reminder

- (BOOL)shouldShowRateUsReminder {
    return (!NM_RATE_US_REMINDER_SHOWN && !launchModeActive && ratingsURL);
}

- (void)showRateUsReminderCompletion:(void (^)(void))completion {
    [alertCompletion release];
    alertCompletion = [completion copy];
    
    NM_RATE_US_REMINDER_SHOWN = YES;
    [[NSUserDefaults standardUserDefaults] setBool:NM_RATE_US_REMINDER_SHOWN forKey:NM_RATE_US_REMINDER_SHOWN_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Rate NOWBOX" message:@"Thank you for using NOWBOX! We hope you're enjoying it. We'd love for you to rate us on the App Store--it will only take a minute." delegate:self cancelButtonTitle:@"No Thanks" otherButtonTitles:@"Rate NOWBOX", @"Remind Me Later", nil];
    [alertView show];
    [alertView release];
    
    [[MixpanelAPI sharedAPI] track:AnalyticsEventRateUsDialogShown];
}

#pragma mark - ToolTipControllerDelegate

- (BOOL)toolTipController:(ToolTipController *)controller shouldPresentToolTip:(ToolTip *)tooltip sender:(id)sender {
    if ([tooltip.name isEqualToString:@"WatchLaterTip"] || [tooltip.name isEqualToString:@"FavoriteTip"]) {
        return YES;
    }
    
    return loadedControlView.playbackMode == NMHalfScreenMode;
}

- (UIView *)toolTipController:(ToolTipController *)controller viewForPresentingToolTip:(ToolTip *)tooltip sender:(id)sender {
    
    if ([tooltip.name isEqualToString:@"BadVideoTip"]) {
        // We want to position this one relative to the cell
        UITableView *channelTable = channelController.tableView;
        
        tooltip.center = CGPointMake(floor([sender frame].size.height / 2), -24);
        tooltip.center = [sender convertPoint:tooltip.center toView:self.view];
        
        // Keep tooltip within screen bounds
        tooltip.center = CGPointMake(MAX(MIN(tooltip.center.x, channelTable.frame.size.width - 128), 196),
                                     MAX(channelController.panelView.frame.origin.y, tooltip.center.y));

    }
    
    return self.view;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertCompletion) {
        alertCompletion();
        [alertCompletion release]; alertCompletion = nil;
    }
    
    NSLog(@"%i %@", buttonIndex, [alertView buttonTitleAtIndex:buttonIndex]);
    switch (buttonIndex) {
        case 0: {
            // No thanks
            [[MixpanelAPI sharedAPI] track:AnalyticsEventRateUsDialogRejected];
            break;
        }
        case 1: {
            // Rate the app
            [[UIApplication sharedApplication] openURL:ratingsURL];
            [[MixpanelAPI sharedAPI] track:AnalyticsEventRateUsDialogAccepted];        
            break;
        }
        case 2: {
            // Remind me later
            [[MixpanelAPI sharedAPI] track:AnalyticsEventRateUsDialogDeferred];
            
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setBool:NO forKey:NM_RATE_US_REMINDER_SHOWN_KEY];
            [userDefaults setInteger:++NM_RATE_US_REMINDER_DEFER_COUNT forKey:NM_RATE_US_REMINDER_DEFER_COUNT_KEY];
            [userDefaults synchronize];
            break;
        }
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [actionSheet release];
    
    NMVideo *video = playbackModelController.currentVideo;
    
    if (buttonIndex == 0) {
        // Email share
        [[NSNotificationCenter defaultCenter] postNotificationName:NMChannelManagementWillAppearNotification object:self];

        MFMailComposeViewController *composeController = [[MFMailComposeViewController alloc] init];
		composeController.mailComposeDelegate = self;
		[composeController setSubject:video.title];
		[composeController setMessageBody:[NSString stringWithFormat:@"<a href=\"http://www.youtube.com/watch?v=%@\">http://www.youtube.com/watch?v=%@</a>", video.external_id, video.external_id] isHTML:YES];
        [composeController setModalPresentationStyle:UIModalPresentationFormSheet];
		[self presentModalViewController:composeController animated:YES];
		[composeController release];
    
    } else if (buttonIndex > 0) {
        // Twitter / Facebook share
        ShareViewController *shareController = [[ShareViewController alloc] initWithNibName:@"ShareView" 
                                                                                     bundle:[NSBundle mainBundle] 
                                                                                      video:video
                                                                                  shareMode:(buttonIndex == 1 ? ShareModeTwitter : ShareModeFacebook)
                                                                                   duration:loadedControlView.duration 
                                                                             elapsedSeconds:loadedControlView.timeElapsed];
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:shareController];
        navController.modalPresentationStyle = UIModalPresentationPageSheet;
        [navController.navigationBar setBarStyle:UIBarStyleBlack];
        [self presentModalViewController:navController animated:YES];

        // Hack to make the modal view controller bigger
        navController.view.superview.bounds = CGRectMake(0, 0, 500, 325);
        CGRect frame = navController.view.superview.frame;
        frame.origin.y = 40;
        navController.view.superview.frame = frame;
        
        [shareController release];
        [navController release];
    }
    
    NSString *shareType = nil;
    switch (buttonIndex) {
        case 0: shareType = @"Email"; break;
        case 1: shareType = @"Twitter"; break;
        case 2: shareType = @"Facebook"; break;
    }
    if (shareType) {
        [[MixpanelAPI sharedAPI] track:AnalyticsEventShowShareDialog properties:[NSDictionary dictionaryWithObjectsAndKeys:playbackModelController.channel.title, AnalyticsPropertyChannelName, 
                                                                                 video.title, AnalyticsPropertyVideoName, 
                                                                                 video.nm_id, AnalyticsPropertyVideoId,
                                                                                 shareType, AnalyticsPropertyShareType,
                                                                                 nil]];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error 
{
    NSString *eventName;
    if (result == MFMailComposeResultCancelled) {
        eventName = AnalyticsEventCancelShareDialog;
    } else if (result == MFMailComposeResultFailed) {
        eventName = AnalyticsEventShareFailed;
    } else {
        eventName = AnalyticsEventCompleteShareDialog;
    }

    NMVideo *video = playbackModelController.currentVideo;
    [[MixpanelAPI sharedAPI] track:eventName properties:[NSDictionary dictionaryWithObjectsAndKeys:playbackModelController.channel.title, AnalyticsPropertyChannelName, 
                                                                        video.title, AnalyticsPropertyVideoName, 
                                                                        video.nm_id, AnalyticsPropertyVideoId,
                                                                        @"Email", AnalyticsPropertyShareType,
                                                                        nil]];  
    
    [self dismissModalViewControllerAnimated:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:NMChannelManagementDidDisappearNotification object:self];
}

#pragma mark - Debug

#ifdef DEBUG_PLAYER_NAVIGATION
- (NMAVQueuePlayer *)getQueuePlayer {
	return movieView.player;
}

#endif

@end
