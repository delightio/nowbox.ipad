//
//  PhoneVideoPlaybackViewController.m
//  Nowmov
//
//  Created by Bill So on 11/02/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PhoneVideoPlaybackViewController.h"
#import "NMMovieView.h"
#import "ChannelPanelController.h"
#import "ipadAppDelegate.h"
#import "LaunchController.h"
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
#define NM_ANIMATION_FULL_PLAYBACK_SCREEN_CONTEXT		10006
#define NM_ANIMATION_VIDEO_THUMBNAIL_CONTEXT			10008

#define NM_SHOULD_TRANSIT_SPLIT_VIEW					1
#define NM_SHOULD_TRANSIT_FULL_SCREEN_VIEW				2

#define NM_MOVIE_VIEW_GAP								20
#define NM_MOVIE_VIEW_GAP_FLOAT							20.0f

#define REFRESH_HEADER_HEIGHT 80.0f

@interface PhoneVideoPlaybackViewController (PrivateMethods)

//- (void)insertVideoAtIndex:(NSUInteger)idx;
//- (void)queueVideoToPlayer:(NMVideo *)vid;
- (void)controlsViewTouchUp:(id)sender;
- (void)configureControlViewForVideo:(NMVideo *)aVideo;
- (void)configureDetailViewForContext:(NSInteger)ctx;
- (void)showNextVideo:(BOOL)didPlayToEnd;
- (void)playCurrentVideo;
- (void)stopVideo;
- (void)setupPlayer;
//- (void)hideControlView;

- (NMVideo *)playerCurrentVideo;
- (void)showLaunchView;

// channel switching method
- (void)resetChannelHeaderView:(BOOL)isPrev;
- (void)startLoadingChannel:(BOOL)isPrev;
- (void)stopLoadingChannel:(BOOL)isPrev;

// debug message
- (void)printDebugMessage:(NSString *)str;

@end


@implementation PhoneVideoPlaybackViewController
@synthesize managedObjectContext=managedObjectContext_;
@synthesize currentVideo;
@synthesize loadedControlView;
@synthesize controlScrollView;
@synthesize appDelegate;
@synthesize previousChannelHeaderView;
@synthesize nextChannelHeaderView;

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
	movieXOffset = 0.0f;
	showMovieControlTimestamp = -1;
	screenWidth = 480.0f;
	fullScreenRect = CGRectMake(0.0f, 0.0f, 480.0f, 320.0f);
	
	// channel switching header
	CGRect theFrame;
	theFrame = previousChannelHeaderView.frame;
	theFrame.origin.y = -theFrame.size.height;
	previousChannelHeaderView.frame = theFrame;
	[channelSwitchingScrollView addSubview:previousChannelHeaderView];
	[self resetChannelHeaderView:YES];
	
	theFrame = nextChannelHeaderView.frame;
	theFrame.origin.y = theFrame.size.height + fullScreenRect.size.height;
	nextChannelHeaderView.frame = theFrame;
	[channelSwitchingScrollView addSubview:nextChannelHeaderView];
	[self resetChannelHeaderView:NO];

	// ribbon view
//	ribbonView.layer.contents = (id)[UIImage imageNamed:@"ribbon"].CGImage;
//	ribbonView.layer.shouldRasterize = YES;
	
	// playback data model controller
	nowboxTaskController = [NMTaskQueueController sharedTaskQueueController];
	playbackModelController = [VideoPlaybackModelController sharedVideoPlaybackModelController];
	playbackModelController.managedObjectContext = self.managedObjectContext;
	playbackModelController.dataDelegate = self;

	// pre-load the movie detail view. we need to cache 3 of them so that user can see the current, next and previous movie detail with smooth scrolling transition
	NSBundle * mb = [NSBundle mainBundle];
	movieDetailViewArray = [[NSMutableArray alloc] initWithCapacity:3];
	for (NSInteger i = 0; i < 3; i++) {
		[mb loadNibNamed:@"MovieDetailInfoView" owner:self options:nil];
		[movieDetailViewArray addObject:self.loadedMovieDetailView];
		theFrame = loadedMovieDetailView.frame;
		theFrame.origin.y = 0.0f;
		theFrame.origin.x = -(screenWidth + NM_MOVIE_VIEW_GAP_FLOAT);
		theFrame.size.width = screenWidth;
		theFrame.size.height = 320.0f;
		loadedMovieDetailView.frame = theFrame;
		loadedMovieDetailView.alpha = 0.0f;
		[controlScrollView addSubview:loadedMovieDetailView];
		self.loadedMovieDetailView = nil;
		// movie detail view doesn't need to respond to autoresize
	}

#ifndef DEBUG_NO_VIDEO_PLAYBACK_VIEW
	// === don't change the sequence in this block ===
	// create movie view
	movieView = [[NMMovieView alloc] initWithFrame:CGRectMake(movieXOffset, 0.0f, screenWidth, 320.0f)];
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
	controlScrollView.frame = CGRectMake(0.0f, 0.0f, 480.0f + NM_MOVIE_VIEW_GAP_FLOAT, 320.0f);
	channelSwitchingScrollView.contentSize = channelSwitchingScrollView.bounds.size;
	[channelSwitchingScrollView setDecelerationRate:UIScrollViewDecelerationRateFast];

	// for unknown reason, setting "directional lock" in interface builder does NOT work. So, set programmatically.
//	controlScrollView.directionalLockEnabled = YES;
	
	// pre-load control view
	// load the nib
	[mb loadNibNamed:@"VideoControlView" owner:self options:nil];
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
	[nowboxTaskController issueGetFeaturedCategories];
	
	defaultNotificationCenter = [NSNotificationCenter defaultCenter];
	// listen to item finish up playing notificaiton
	[defaultNotificationCenter addObserver:self selector:@selector(handleDidPlayItemNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
	// listen to system notification
	[defaultNotificationCenter addObserver:self selector:@selector(handleApplicationDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
	// 2nd display support
//	[defaultNotificationCenter addObserver:self selector:@selector(handleDisplayConnectedNotification:) name:UIScreenDidConnectNotification object:nil];
//	[defaultNotificationCenter addObserver:self selector:@selector(handleDisplayDisconnectedNotification:) name:UIScreenDidDisconnectNotification object:nil];
	
	// channel management view notification
	[defaultNotificationCenter addObserver:self selector:@selector(handleChannelManagementNotification:) name:NMChannelManagementWillAppearNotification object:nil];
	[defaultNotificationCenter addObserver:self selector:@selector(handleChannelManagementNotification:) name:NMChannelManagementDidDisappearNotification object:nil];
	// event
	[defaultNotificationCenter addObserver:self selector:@selector(handleVideoEventNotification:) name:NMDidShareVideoNotification object:nil];
	[defaultNotificationCenter addObserver:self selector:@selector(handleVideoEventNotification:) name:NMDidUnfavoriteVideoNotification object:nil];
	[defaultNotificationCenter addObserver:self selector:@selector(handleVideoEventNotification:) name:NMDidEnqueueVideoNotification object:nil];
	[defaultNotificationCenter addObserver:self selector:@selector(handleVideoEventNotification:) name:NMDidDequeueVideoNotification object:nil];
	[defaultNotificationCenter addObserver:self selector:@selector(handleVideoEventNotification:) name:NMDidFailShareVideoNotification object:nil];
	[defaultNotificationCenter addObserver:self selector:@selector(handleVideoEventNotification:) name:NMDidFailUnfavoriteVideoNotification object:nil];
	[defaultNotificationCenter addObserver:self selector:@selector(handleVideoEventNotification:) name:NMDidFailEnqueueVideoNotification object:nil];
	[defaultNotificationCenter addObserver:self selector:@selector(handleVideoEventNotification:) name:NMDidFailDequeueVideoNotification object:nil];
    
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
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload {
    [self setPreviousChannelHeaderView:nil];
    [self setNextChannelHeaderView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[launchController release];
	
	[loadedControlView release];
	[movieDetailViewArray release];
	[currentChannel release];
	// get rid of time observer of video player
 	[movieView.player removeTimeObserver:timeObserver];
	[timeObserver release];
	// remove movie view. only allow this to happen after we have removed the time observer
	[movieView release];
//    [temporaryDisabledGestures release];
    [previousChannelHeaderView release];
    [nextChannelHeaderView release];
	[super dealloc];
}

#pragma mark Launch / onboard process
//- (void)setLaunchModeActive:(BOOL)flag {
//	if ( flag ) {
//		// set to full screen
//		[self toggleChannelPanel:nil];
//	}
//	launchModeActive = flag;
//}

- (void)showLaunchView {
	[launchController loadView];
//	UIView * theView = launchController.progressContainerView;
//	[theView removeFromSuperview];
	[self.view addSubview:launchController.view];
//	CGRect winRect = self.view.bounds;
//	CGRect theRect = theView.frame;
//	theRect.origin.x = winRect.size.width - theRect.size.width;
//	theRect.origin.y = floorf(( winRect.size.height - theRect.size.height ) / 2.0f);
//	theView.frame = theRect;
//	[self.view addSubview:launchController.progressContainerView];
}

//- (void)showPlaybackViewWithTransitionStyle:(NSString *)aniStyle {
- (void)showPlaybackView {
	if ( launchModeActive ) {
//		topLevelContainerView.center = CGPointMake(1536.0f, 384.0f);
		controlScrollView.scrollEnabled = NO;
		// reset the alpha value
		playbackModelController.currentVideo.nm_movie_detail_view.thumbnailContainerView.alpha = 1.0f;
		movieView.alpha = 0.0f; // delayRestoreDetailView is called in controller:didUpdateVideoListWithTotalNumberOfVideo: when the channel is updated. The delay method will reset the alpha value of the views.
		// bring the playback view to the front
//		[self.view bringSubviewToFront:topLevelContainerView];
		// cross fade the view
		shouldFadeOutVideoThumbnail = YES;
		[UIView transitionFromView:launchController.view toView:topLevelContainerView duration:0.5f options:(NM_RUNNING_IOS_5 ? UIViewAnimationOptionTransitionCrossDissolve : UIViewAnimationOptionTransitionNone) completion:^(BOOL finished) {
			// remove launch view
			[launchController.view removeFromSuperview];
			[launchController release];
			launchController = nil;
			launchModeActive = NO;
			playFirstVideoOnLaunchWhenReady = YES;
		}];
		// slide in the view
//		[UIView animateWithDuration:0.5f animations:^{
//			topLevelContainerView.center = launchController.view.center;
//			shouldFadeOutVideoThumbnail = YES;
//		} completion:^(BOOL finished) {
//			playFirstVideoOnLaunchWhenReady = YES;
//			// do NOT remove launch view here. Launch view will be removed in scroll view delegate method.
//		}];

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
	}
    
    // Start monitoring for tooltips
//    [[ToolTipController sharedToolTipController] startTimer];
//    [[ToolTipController sharedToolTipController] setDelegate:self];
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
		for (NMMovieDetailView * theDetailView in movieDetailViewArray) {
			theDetailView.video = nil;
		}
		
		[loadedControlView resetView];
		return;	// return if the channel object is nil
	}
	
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
//	NSArray * vidAy = [playbackModelController videosForBuffering];
//	if ( vidAy ) {
//		[movieView.player resolveAndQueueVideos:vidAy];
//	}
	
	// update the interface if necessary
	//	[movieView setActivityIndicationHidden:NO animated:NO];
//	[self updateRibbonButtons];
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

#pragma mark Channel Switching
- (void)resetChannelHeaderView:(BOOL)isPrev {
	if ( isPrev ) {
		previousChannelSwitchingLabel.text = @"Pull to switch channel";
		[previousChannelActivityView stopAnimating];
	} else {
		nextChannelSwitchingLabel.text = @"Pull to switch channel";
		[nextChannelActivityView stopAnimating];
	}
}

- (void)startLoadingChannel:(BOOL)isPrev {
	if ( isPrev ) {
		[previousChannelActivityView startAnimating];
		previousChannelSwitchingLabel.text = @"Switch to previous channel...";
	} else {
		[nextChannelActivityView startAnimating];
		nextChannelSwitchingLabel.text = @"Switching to next channel...";
	}
}

- (void)stopLoadingChannel:(BOOL)isPrev {
	// reset the view
	[self resetChannelHeaderView:isPrev];
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
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_4_3
	if ( NM_RUNNING_IOS_5 ) {
		player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
//		player.usesAirPlayVideoWhileAirPlayScreenIsActive = NO;
	}
#endif
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
		}
		loadedControlView.timeElapsed = sec;
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
	NSLog(@"configure control view for: %@, %@", aVideo.title, aVideo.nm_id);
#endif
	[loadedControlView resetView];
	if ( aVideo ) {
		[loadedControlView updateViewForVideo:aVideo];
	}
	// update the position
	CGRect theFrame = loadedControlView.frame;
	theFrame.origin.x = controlScrollView.contentOffset.x + movieXOffset;
	loadedControlView.frame = theFrame;
	// update the movie view too
	theFrame = movieView.frame;
	theFrame.origin.x = controlScrollView.contentOffset.x + movieXOffset;
	movieView.frame = theFrame;
	[UIView animateWithDuration:0.25f delay:0.0f options:0 animations:^{
		movieView.alpha = 1.0f;
	} completion:^(BOOL finished) {
//		if ( loadedControlView.playbackMode == NMHalfScreenMode ) {
			[loadedControlView setControlsHidden:NO animated:YES];
//		}
	}];
}

- (NMMovieDetailView *)getFreeMovieDetailView {
	NMMovieDetailView * detailView = nil;
	for (detailView in movieDetailViewArray) {
		if ( detailView.video == nil ) {
			break;
		}
	}
	return detailView;
}

//- (void)hideControlView {
//	if ( loadedControlView.alpha > 0.0f ) {
//		[UIView animateWithDuration:0.25f animations:^{
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
			
		case NM_ANIMATION_FULL_PLAYBACK_SCREEN_CONTEXT:
			// show the top bar with animation
			[loadedControlView setTopBarHidden:NO animated:NO];
			// hide all movie detail view
//			for (NMMovieDetailView * theDetailView in movieDetailViewArray) {
//				theDetailView.hidden = YES;
//			}
			[self configureDetailViewForContext:ctxInt];
			ribbonView.hidden = YES;
			break;
			
		case NM_ANIMATION_VIDEO_THUMBNAIL_CONTEXT:
			controlScrollView.scrollEnabled = YES;
			[self configureControlViewForVideo:[self playerCurrentVideo]];
			[self playCurrentVideo];
			break;
		default:
			break;
	}
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
	[nowboxTaskController issueSendViewEventForVideo:theVideo elapsedSeconds:loadedControlView.timeElapsed playedToEnd:aEndOfVideo];
	// visually transit to next video just like the user has tapped next button
	//if ( aEndOfVideo ) {
	// disable interface scrolling
	// will activate again on "currentItem" change kvo notification
	controlScrollView.scrollEnabled = NO;
	// fade out the view
	[UIView animateWithDuration:0.75f animations:^(void) {
		movieView.alpha = 0.0f;
	} completion:^(BOOL finished) {
		currentXOffset += screenWidth + NM_MOVIE_VIEW_GAP_FLOAT;
		// scroll to next video
		// translate the movie view
		[UIView animateWithDuration:0.5f animations:^{
			controlScrollView.contentOffset = CGPointMake(currentXOffset, 0.0f);
		}];
		if ( [playbackModelController moveToNextVideo] ) {
			playbackModelController.previousVideo.nm_did_play = [NSNumber numberWithBool:YES];
			[movieView.player advanceToVideo:playbackModelController.currentVideo];
		}
	}];
	// when traisition is done. move shift the scroll view and reveals the video player again
	// this method does not handle the layout (position) of the movie control. that should be handled in scroll view delegate method
}

- (void)playVideo:(NMVideo *)aVideo {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	// Channel View calls this method when user taps a video from the table
	// stop video
	[self stopVideo];
	// flush the video player
	[movieView.player removeAllItems];	// optimize for skipping to next or next-next video. Do not call this method those case
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
	}
	[playbackModelController setVideo:aVideo];
	forceStopByUser = NO;
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
		theDetailView = [self getFreeMovieDetailView];
		ctrl.nextVideo.nm_movie_detail_view = theDetailView;
	}
	theDetailView.video = ctrl.nextVideo;
	
	CGFloat xOffset = (CGFloat)(ctrl.nextIndexPath.row * (480 + NM_MOVIE_VIEW_GAP));
#ifdef DEBUG_PLAYER_NAVIGATION
	NSLog(@"offset of next MDV: %f ptr: %p", xOffset, theDetailView);
#endif
	CGRect theFrame = theDetailView.frame;
	theFrame.origin.x = xOffset;
	theDetailView.frame = theFrame;
	// resolve the URL
	if ( !NMVideoPlaybackViewIsScrolling ) [movieView.player resolveAndQueueVideo:ctrl.nextVideo];
}

- (void)didLoadPreviousVideoManagedObjectForController:(VideoPlaybackModelController *)ctrl {
	NMMovieDetailView * theDetailView = ctrl.previousVideo.nm_movie_detail_view;
	if ( theDetailView == nil ) {
		theDetailView = [self getFreeMovieDetailView];
		ctrl.previousVideo.nm_movie_detail_view = theDetailView;
	}
	theDetailView.video = ctrl.previousVideo;
	
	CGFloat xOffset = (CGFloat)(ctrl.previousIndexPath.row * (480 + NM_MOVIE_VIEW_GAP));
#ifdef DEBUG_PLAYER_NAVIGATION
	NSLog(@"offset of previous MDV: %f ptr: %p", xOffset, theDetailView);
#endif
	CGRect theFrame = theDetailView.frame;
	theFrame.origin.x = xOffset;
	theDetailView.frame = theFrame;
	// resolve the URL
	if ( !NMVideoPlaybackViewIsScrolling ) [movieView.player resolveAndQueueVideo:ctrl.previousVideo];
}

- (void)didLoadCurrentVideoManagedObjectForController:(VideoPlaybackModelController *)ctrl {
	NMMovieDetailView * theDetailView = ctrl.currentVideo.nm_movie_detail_view;
	if ( theDetailView == nil ) {
		theDetailView = [self getFreeMovieDetailView];
		ctrl.currentVideo.nm_movie_detail_view = theDetailView;
	}
	theDetailView.video = ctrl.currentVideo;
	
	CGFloat xOffset = (CGFloat)(ctrl.currentIndexPath.row * (480 + NM_MOVIE_VIEW_GAP));
#ifdef DEBUG_PLAYER_NAVIGATION
	NSLog(@"offset of current MDV: %f actual: %f ptr: %p, %@", xOffset, theDetailView.frame.origin.x, theDetailView, ctrl.currentVideo.title);
#endif
	CGRect theFrame = theDetailView.frame;
	theFrame.origin.x = xOffset;
	theDetailView.frame = theFrame;
	// when scrolling is inflight, do not issue the URL resolution request. Playback View Controller will call "advanceToNextVideo" later on which will trigger sending of resolution request.
	if ( !NMVideoPlaybackViewIsScrolling ) [movieView.player resolveAndQueueVideo:ctrl.currentVideo];
}

- (void)controller:(VideoPlaybackModelController *)ctrl didUpdateVideoListWithTotalNumberOfVideo:(NSUInteger)totalNum {
#ifdef DEBUG_PLAYER_NAVIGATION
	NSLog(@"current total num videos: %d", totalNum);
#endif

	controlScrollView.contentSize = CGSizeMake((CGFloat)( (480 + NM_MOVIE_VIEW_GAP) * totalNum), 320.0f);
	CGFloat newOffset = (CGFloat)(playbackModelController.currentIndexPath.row * (480 + NM_MOVIE_VIEW_GAP));
	if ( totalNum ) {
		if ( currentXOffset != newOffset ) {
			// update offset
			currentXOffset = newOffset;
			// move over to the new location
			[UIView animateWithDuration:0.5f animations:^{
				controlScrollView.contentOffset = CGPointMake(currentXOffset, 0.0f);
			} completion:^(BOOL finished) {
				[self performSelector:@selector(delayRestoreDetailView) withObject:nil afterDelay:0.5f];
			}];
		} else {
			[self performSelector:@selector(delayRestoreDetailView) withObject:nil afterDelay:0.5f];
		}
	}
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
	if ( channelSwitchStatus ) {
		[self resetChannelHeaderView:channelSwitchStatus == ChannelSwitchPrevious];
		channelSwitchingScrollView.contentOffset = CGPointZero;
		channelSwitchingScrollView.contentInset = UIEdgeInsetsZero;
		channelSwitchStatus = ChannelSwitchNone;
		channelSwitchingScrollView.scrollEnabled = YES;
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
- (void)delayHandleDidPlayItem:(NMAVPlayerItem *)anItem {
	if ( playbackModelController.nextVideo == nil ) {
		// finish up playing the whole channel
		[self dismissModalViewControllerAnimated:YES];
	} else {
		didPlayToEnd = YES;
		[self showNextVideo:YES];
	}
}

- (void)handleDidPlayItemNotification:(NSNotification *)aNotification {
	// For unknown reason, AVPlayerItemDidPlayToEndTimeNotification is sent twice sometimes. Don't know why. This delay execution mechanism tries to solve this problem
#ifdef DEBUG_PLAYBACK_QUEUE
	NSLog(@"did play notification: %@", [aNotification name]);
#endif
	// according to documentation, AVPlayerItemDidPlayToEndTimeNotification is not guaranteed to be fired from the main thread.
	dispatch_async(dispatch_get_main_queue(), ^{
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayHandleDidPlayItem:) object:[aNotification object]];
		[self performSelector:@selector(delayHandleDidPlayItem:) withObject:[aNotification object] afterDelay:0.1];
	});
}

- (void)handleApplicationDidBecomeActiveNotification:(NSNotification *)aNotification {
	// resume playing the video
	[self playCurrentVideo];
	NMAVPlayerItem * item = (NMAVPlayerItem *)movieView.player.currentItem;
	// send event back to server
	if ( item ) {
		[nowboxTaskController issueSendViewEventForVideo:item.nmVideo elapsedSeconds:loadedControlView.timeElapsed playedToEnd:NO];
	}
}

- (void)handleChannelManagementNotification:(NSNotification *)aNotification {
	if ( NM_RUNNING_IOS_5 ) {
		if ( [[aNotification name] isEqualToString:NMChannelManagementWillAppearNotification] ) {
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
			if ( !movieView.player.airPlayVideoActive ) {
				forceStopByUser = NO;
				[self playCurrentVideo];
			}
#endif
		}
	} else {
		if ( [[aNotification name] isEqualToString:NMChannelManagementWillAppearNotification] ) {            
			// stop video from playing
			[self stopVideo];
		} else {
			forceStopByUser = NO;
			// resume video playing
			[self playCurrentVideo];
		}
	}
}

- (void)handleVideoEventNotification:(NSNotification *)aNotification {
	// check it's the current, previous or next video
	NMVideo * vidObj = [[aNotification userInfo] objectForKey:@"video"];
	// do nth if the video object is nil
	if ( vidObj == nil ) return;
	
	NSString * name = [aNotification name];
	if ( [name isEqualToString:NMDidShareVideoNotification] && [playbackModelController.currentVideo isEqual:vidObj] ) {
//		[self animateFavoriteButtonsToActive];
	} else if ( [name isEqualToString:NMDidUnfavoriteVideoNotification] && [playbackModelController.currentVideo isEqual:vidObj] ) {
//		[self animateFavoriteButtonsToActive];
	} else if ( [name isEqualToString:NMDidEnqueueVideoNotification] && [playbackModelController.currentVideo isEqual:vidObj] ) {
		// queued a video successfully, animate the icon to appropriate state
//		[self animateWatchLaterButtonsToActive];
	} else if ( [name isEqualToString:NMDidDequeueVideoNotification] && [playbackModelController.currentVideo isEqual:vidObj] ) {
		// dequeued a video successfully
//		[self animateWatchLaterButtonsToActive];
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
		
		[self performSelector:@selector(showActivityLoader) withObject:nil afterDelay:1.25f];
		
		if ( didPlayToEnd ) {
			controlScrollView.scrollEnabled = YES;
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
			// Apple TV does not send remote event back to app. No need to implement for now.
			// receive remote event
//			[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
//			[self becomeFirstResponder];
		} else {
			// remove the interface indication
			[movieView hideAirPlayIndicatorView:YES];
			NM_AIRPLAY_ACTIVE = NO;
			// Apple TV does not send remote event back to app. No need to implement for now.
//			[[UIApplication sharedApplication] endReceivingRemoteControlEvents];
//			[self resignFirstResponder];
		}
#endif
	}
	// refer to https://pipely.lighthouseapp.com/projects/77614/tickets/93-study-video-switching-behavior-how-to-show-loading-ui-state
	else if ( c == NM_PLAYBACK_LIKELY_TO_KEEP_UP_CONTEXT ) {
		if ( !forceStopByUser ) {
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
		} else {
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
//	[self updateRibbonButtons];
//	[UIView animateWithDuration:0.25f animations:^{
//		ribbonView.alpha = 1.0f;
//	}];
//	ribbonView.userInteractionEnabled = YES;
}

- (void)configureDetailViewForContext:(NSInteger)ctx {
//	switch (ctx) {
//		case NM_ANIMATION_SPLIT_VIEW_CONTEXT:
//			for (NMMovieDetailView * dtlView in movieDetailViewArray) {
//				// hide everything except the thumbnail view
//				[dtlView configureMovieThumbnailForFullScreen:NO];
//			}
//			break;
//			
//		case NM_ANIMATION_FULL_PLAYBACK_SCREEN_CONTEXT:
//			for (NMMovieDetailView * dtlView in movieDetailViewArray) {
//				[dtlView configureMovieThumbnailForFullScreen:YES];
//			}
//			break;
//			
//		default:
//			break;
//	}
}
#pragma mark Popover delegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	[self playCurrentVideo];
}

#pragma mark Scroll View Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	if ( scrollView == channelSwitchingScrollView ) {
		return;
	}
	
	forceStopByUser = NO;	// reset force stop variable when scrolling begins
	NMVideoPlaybackViewIsScrolling = YES;
	if ( NM_RUNNING_IOS_5 ) {
		[UIView animateWithDuration:0.25f animations:^{
			ribbonView.alpha = 0.15;
		}];
		ribbonView.userInteractionEnabled = NO;
	} else {
		ribbonView.alpha = 0.15;
	}
//	if ( launchModeActive ) {
//		[launchController dimProgressLabel];
//	}
//	[self hideControlView];
	[loadedControlView setControlsHidden:YES animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if ( scrollView == channelSwitchingScrollView ) {
		CGFloat yOff = scrollView.contentOffset.y;
		if (yOff < -REFRESH_HEADER_HEIGHT ) {
			previousChannelSwitchingLabel.text = @"Release to switch channel";
		} else if ( yOff > REFRESH_HEADER_HEIGHT ) {
			nextChannelSwitchingLabel.text = @"Release to switch channel";
		} else if ( yOff < 0.0f && yOff >= -REFRESH_HEADER_HEIGHT ) {
			[self resetChannelHeaderView:YES];
		} else if ( yOff > 0.0f && yOff <= REFRESH_HEADER_HEIGHT ) {
			[self resetChannelHeaderView:NO];
		}
//		if ( isSwitchingChannel ) {
//			if (scrollView.contentOffset.y > 0)
//				scrollView.contentInset = UIEdgeInsetsZero;
//			else if (scrollView.contentOffset.y >= -REFRESH_HEADER_HEIGHT)
//				scrollView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
//		} else if (scrollView.contentOffset.y <= -REFRESH_HEADER_HEIGHT) {
//			// Released above the header
//			isSwitchingChannel = YES;
//			NSLog(@"start switching channel");
//		}

		return;
	}

	CGFloat dx;
	dx = ABS(currentXOffset - scrollView.contentOffset.x);
	// reduce alpha of the playback view
	movieView.alpha = (screenWidth - dx) / screenWidth;
}

- (void)delayedChangeChannelSwitchingScrollViewOffset {
	CGFloat yOff;
	NMChannel * chnObj = nil;
	switch (channelSwitchStatus) {
		case ChannelSwitchNext:
			chnObj = [nowboxTaskController.dataController nextChannel:currentChannel];
			yOff = fullScreenRect.size.height;
			break;
		case ChannelSwitchPrevious:
			chnObj = [nowboxTaskController.dataController previousChannel:currentChannel];
			yOff = -fullScreenRect.size.height;
			break;
			
		default:
			break;
	}
	if ( chnObj ) {
		[self setCurrentChannel:chnObj];
		[channelSwitchingScrollView setContentOffset:CGPointMake(0.0f, yOff) animated:YES];
	} else {
		[self resetChannelHeaderView:channelSwitchStatus == ChannelSwitchPrevious];
		channelSwitchingScrollView.contentOffset = CGPointZero;
		channelSwitchingScrollView.contentInset = UIEdgeInsetsZero;
		channelSwitchStatus = ChannelSwitchNone;
		channelSwitchingScrollView.scrollEnabled = YES;
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if ( scrollView == channelSwitchingScrollView ) {
		CGFloat yOff = scrollView.contentOffset.y;
		if ( yOff <= -REFRESH_HEADER_HEIGHT ) {
			// Released above the header
			channelSwitchStatus = ChannelSwitchPrevious;
			// push the view down
			channelSwitchingScrollView.contentInset = UIEdgeInsetsMake(320.0f, 0.0f, 0.0f, 0.0f);
			scrollView.scrollEnabled = NO;
			[self stopVideo];
			[self performSelector:@selector(delayedChangeChannelSwitchingScrollViewOffset) withObject:nil afterDelay:0.0f];
			[self startLoadingChannel:YES];
		} else if ( yOff >= REFRESH_HEADER_HEIGHT ) {
			channelSwitchStatus = ChannelSwitchNext;
			// push the view down
			channelSwitchingScrollView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 320.0f, 0.0f);
			scrollView.scrollEnabled = NO;
			[self stopVideo];
			[self performSelector:@selector(delayedChangeChannelSwitchingScrollViewOffset) withObject:nil afterDelay:0.0f];
			[self startLoadingChannel:NO];
		}
		return;
	}
	// this is for preventing user from flicking continuous. user has to flick through video one by one. scrolling will enable again in "scrollViewDidEndDecelerating"
#ifndef DEBUG_NO_VIDEO_PLAYBACK_VIEW
	scrollView.scrollEnabled = NO;
#endif
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	if ( scrollView == channelSwitchingScrollView ) {
		return;
	}
	// switch to the next/prev video
//	scrollView.scrollEnabled = YES; move to animation handler
	if ( scrollView.contentOffset.x > currentXOffset ) {
		// stop playing the video if user has scrolled to another video. This avoids the weird UX where there's sound of the previous video playing but the view is showing the thumbnail of the next video
		[self stopVideo];
		didSkippedVideo = YES;
		currentXOffset += screenWidth + NM_MOVIE_VIEW_GAP_FLOAT;
		if ( [playbackModelController moveToNextVideo] ) {
			playbackModelController.previousVideo.nm_did_play = [NSNumber numberWithBool:YES];
			[movieView.player advanceToVideo:playbackModelController.currentVideo];
			[playbackModelController.previousVideo.nm_movie_detail_view restoreThumbnailView];
		}
#ifdef DEBUG_PLAYER_NAVIGATION
		else
			NSLog(@"can't move to next video. no video!!");
#endif
	} else if ( scrollView.contentOffset.x < currentXOffset ) {
		[self stopVideo];
		didSkippedVideo = YES;
		currentXOffset -= screenWidth + NM_MOVIE_VIEW_GAP_FLOAT;
		if ( playbackModelController.previousVideo ) {
			// instruct the data model to rearrange itself
			[playbackModelController moveToPreviousVideo];
			playbackModelController.nextVideo.nm_did_play = [NSNumber numberWithBool:YES];
			// update the queue player
			[movieView.player revertToVideo:playbackModelController.currentVideo];
			[playbackModelController.nextVideo.nm_movie_detail_view restoreThumbnailView];
		}
	} else {
		scrollView.scrollEnabled = YES;
	}
	NMVideoPlaybackViewIsScrolling = NO;
	// ribbon fade in transition
	[UIView animateWithDuration:0.25f animations:^{
		ribbonView.alpha = 1.0f;
	}];
	ribbonView.userInteractionEnabled = YES;
}

#pragma mark Gesture delegate methods
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
//	NSLog(@"should begin gesture: %d", !scrollBeyondThreshold);
//	if ( !scrollBeyondThreshold ) {
//		controlScrollView.scrollEnabled = NO;
//	}
//	return !scrollBeyondThreshold;
	controlScrollView.scrollEnabled = NO;
	return YES;
}

#pragma mark Target-action methods
- (void)movieViewTouchUp:(UITapGestureRecognizer *)sender {
	loadedControlView.hidden = NO;
	[UIView animateWithDuration:0.25f animations:^{
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
//	UIView * v = (UIView *)sender;
	[UIView animateWithDuration:0.25f animations:^{
		loadedControlView.alpha = 0.0f;
	} completion:^(BOOL finished) {
		if ( finished ) {
			loadedControlView.hidden = YES;
		}
	}];
}

- (IBAction)addVideoToFavorite:(id)sender {
	NMVideo * vdo = playbackModelController.currentVideo;
	[nowboxTaskController issueShare:![vdo.nm_favorite boolValue] video:playbackModelController.currentVideo duration:loadedControlView.duration elapsedSeconds:loadedControlView.timeElapsed];
    
//    [[ToolTipController sharedToolTipController] notifyEvent:ToolTipEventFavoriteTap sender:sender];
}

- (IBAction)addVideoToQueue:(id)sender {
	NMVideo * vdo = playbackModelController.currentVideo;
	[nowboxTaskController issueEnqueue:![vdo.nm_watch_later boolValue] video:playbackModelController.currentVideo];
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
	[UIView animateWithDuration:0.25 animations:^{
		loadedControlView.seekBubbleButton.alpha = 1.0f;
		if ( NM_AIRPLAY_ACTIVE ) {
			// hide the airplay indicator
			movieView.airPlayIndicatorView.alpha = 0.0f;
		}
	}];
	lastStartTime = lastTimeElapsed;
	lastTimeElapsed = loadedControlView.timeElapsed;
}

- (IBAction)touchUpProgressBar:(id)sender {
	forceStopByUser = NO;
	[self playCurrentVideo];
	loadedControlView.isSeeking = NO;
	showMovieControlTimestamp = loadedControlView.timeElapsed;
	[UIView animateWithDuration:0.25 animations:^{
		loadedControlView.seekBubbleButton.alpha = 0.0f;
		if ( NM_AIRPLAY_ACTIVE ) {
			// show the airplay indicator
			movieView.airPlayIndicatorView.alpha = 1.0f;
		}
	}];
	// send the event
	[nowboxTaskController issueSendViewEventForVideo:playbackModelController.currentVideo start:lastStartTime elapsedSeconds:lastTimeElapsed];
	lastTimeElapsed = showMovieControlTimestamp;
}

# pragma mark Gestures
//- (void)handleMovieViewPinched:(UIPinchGestureRecognizer *)sender {
//	switch (sender.state) {
//		case UIGestureRecognizerStateCancelled:
//			controlScrollView.scrollEnabled = YES;
//			break;
//			
//		case UIGestureRecognizerStateChanged:
//		{
//			if ( sender.velocity < -1.8 && sender.scale < 0.8 ) {
//				detectedPinchAction = NM_SHOULD_TRANSIT_SPLIT_VIEW;
//			} else if ( sender.velocity > 2.0 && sender.scale > 1.2 ) {
//				detectedPinchAction = NM_SHOULD_TRANSIT_FULL_SCREEN_VIEW;
//			}
//			break;
//		}
//		case UIGestureRecognizerStateRecognized:
//		{
//			CGRect theFrame = channelController.panelView.frame;
//			BOOL panelHidden = YES;
//			if ( theFrame.origin.y < 768.0 ) {
//				// assume the panel is visible
//				panelHidden = NO;
//			}
//			
//			if ( ( panelHidden && detectedPinchAction == NM_SHOULD_TRANSIT_SPLIT_VIEW ) || ( !panelHidden && detectedPinchAction == NM_SHOULD_TRANSIT_FULL_SCREEN_VIEW ) ) {
//				[self toggleChannelPanel:sender.view];
//			}
//			controlScrollView.scrollEnabled = YES;
//			break;
//		}
//			
//		default:
//			break;
//	}
//}

#pragma mark - ToolTipControllerDelegate

//- (BOOL)toolTipController:(ToolTipController *)controller shouldPresentToolTip:(ToolTip *)tooltip sender:(id)sender {
//    if ([tooltip.name isEqualToString:@"ShareButtonTip"]) {
//        // Don't show share tip if user is already logged in
//        if (NM_USER_TWITTER_CHANNEL_ID || NM_USER_FACEBOOK_CHANNEL_ID) {
//            return NO;
//        }
//    } else if ([tooltip.name hasPrefix:@"SwipeTip"] && sender) {
//        // Don't show swipe tip until next video is ready to play
//        pendingToolTip = tooltip;
//        return NO;
//    }
//    
//    return loadedControlView.playbackMode == NMHalfScreenMode;
//}
//
//- (UIView *)toolTipController:(ToolTipController *)controller viewForPresentingToolTip:(ToolTip *)tooltip sender:(id)sender {
//    
//    if ([tooltip.name isEqualToString:@"BadVideoTip"]) {
//        // We want to position this one relative to the cell
//        UITableView *channelTable = channelController.tableView;
//        
//        tooltip.center = CGPointMake(floor([sender frame].size.height / 2), -24);
//        tooltip.center = [sender convertPoint:tooltip.center toView:self.view];
//        
//        // Keep tooltip within screen bounds, and avoid subpixel text rendering (blurrier)
//        CGPoint center = CGPointMake(MAX(MIN(tooltip.center.x, channelTable.frame.size.width - 128), 196),
//                                     MAX(channelController.panelView.frame.origin.y, tooltip.center.y));
//        center.x = floor(center.x);
//        center.y = floor(center.y);
//        if ((NSInteger) center.x % 2 == 1) {
//            center.x++;
//        }
//        if ((NSInteger) center.y % 2 == 1) {
//            center.y++;
//        }
//        tooltip.center = center;
//    } else if ([tooltip.name isEqualToString:@"ChannelManagementTip"]) {
//        tooltip.target = channelController;
//        tooltip.action = @selector(showChannelManagementView:);
//    } else if ([tooltip.name isEqualToString:@"ShareButtonTip"]) {
//        tooltip.target = channelController;
//        tooltip.action = @selector(showChannelManagementView:);        
//    }
//    
//    return self.view;
//}

#pragma mark Debug

#ifdef DEBUG_PLAYER_NAVIGATION
- (NMAVQueuePlayer *)getQueuePlayer {
	return movieView.player;
}

#endif

@end
