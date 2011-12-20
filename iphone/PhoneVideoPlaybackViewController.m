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
#import "PhoneLaunchController.h"
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
#define NM_ANIMATION_FULL_PLAYBACK_SCREEN_CONTEXT		10006
#define NM_ANIMATION_VIDEO_THUMBNAIL_CONTEXT			10008

#define NM_SHOULD_TRANSIT_SPLIT_VIEW					1
#define NM_SHOULD_TRANSIT_FULL_SCREEN_VIEW				2

#define NM_MOVIE_VIEW_GAP								20
#define NM_MOVIE_VIEW_GAP_FLOAT							20.0f

#define REFRESH_HEADER_HEIGHT 80.0f

#define NM_RATE_US_REMINDER_MINIMUM_TIME_ON_APP         (60.0f * 40)

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

// Movie detail view management
- (void)resetAllMovieDetailViews;
- (NMMovieDetailView *)dequeueReusableMovieDetailView;
- (void)reclaimMovieDetailViewForVideo:(NMVideo *)vdo;

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
	movieXOffset = 0.0f;
	showMovieControlTimestamp = -1;
	
	// channel switching header
	CGRect theFrame;
	theFrame = previousChannelHeaderView.frame;
	theFrame.origin.y = -theFrame.size.height;
	previousChannelHeaderView.frame = theFrame;
	[channelSwitchingScrollView addSubview:previousChannelHeaderView];
	[self resetChannelHeaderView:YES];
	
	theFrame = nextChannelHeaderView.frame;
	theFrame.origin.y = topLevelContainerView.frame.size.height;
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

#ifndef DEBUG_NO_VIDEO_PLAYBACK_VIEW
	// === don't change the sequence in this block ===
	// create movie view
	movieView = [[NMMovieView alloc] initWithFrame:CGRectMake(movieXOffset, 0.0f, topLevelContainerView.frame.size.width, topLevelContainerView.frame.size.height)];
	movieView.alpha = 0.0f;
    movieView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

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
	controlScrollView.frame = CGRectMake(0.0f, 0.0f, topLevelContainerView.frame.size.width + NM_MOVIE_VIEW_GAP_FLOAT, topLevelContainerView.frame.size.height);
	channelSwitchingScrollView.contentSize = channelSwitchingScrollView.bounds.size;
	[channelSwitchingScrollView setDecelerationRate:UIScrollViewDecelerationRateFast];

	// for unknown reason, setting "directional lock" in interface builder does NOT work. So, set programmatically.
//	controlScrollView.directionalLockEnabled = YES;
	
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
    
    [defaultNotificationCenter addObserver:self selector:@selector(keyboardWillAppear:) name:UIKeyboardWillShowNotification object:nil];
    [defaultNotificationCenter addObserver:self selector:@selector(keyboardWillDisappear:) name:UIKeyboardWillHideNotification object:nil];
    [defaultNotificationCenter addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
	[defaultNotificationCenter addObserver:self selector:@selector(handleDidGetInfoNotification:) name:NMDidCheckUpdateNotification object:nil];

	// setup gesture recognizer
	UIPinchGestureRecognizer * pinRcr = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleMovieViewPinched:)];
    pinRcr.delegate = self;
	[controlScrollView addGestureRecognizer:pinRcr];
	[pinRcr release];
	
	// create the launch view
	launchController = [[PhoneLaunchController alloc] init];
	launchController.viewController = self;
	[[NSBundle mainBundle] loadNibNamed:@"LaunchView" owner:launchController options:nil];
	[self showLaunchView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateViewsForInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self playCurrentVideo];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
	return YES;
}

- (void)updateViewsForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        topLevelContainerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height / 2);
        
        gridNavigationContainer.frame = CGRectMake(0, self.view.bounds.size.height / 2, self.view.bounds.size.width, self.view.bounds.size.height / 2);
        gridNavigationController.view.frame = gridNavigationContainer.bounds;
        gridNavigationContainer.alpha = 1.0f;
        
        [loadedControlView setToggleGridButtonHidden:YES];   
		[loadedControlView setControlsHidden:YES animated:NO];                
    } else {
        topLevelContainerView.frame = self.view.bounds;
        if (!gridShowing) {
            gridNavigationController.view.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height - loadedControlView.controlContainerView.frame.size.height);      
            gridNavigationContainer.alpha = 0.0f;
        } else {
            gridNavigationController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - loadedControlView.controlContainerView.frame.size.height);            
            gridNavigationContainer.alpha = 1.0f;
        }
        gridNavigationContainer.frame = gridNavigationController.view.bounds;
        [loadedControlView setToggleGridButtonHidden:NO];
		[loadedControlView setControlsHidden:NO animated:NO];        
    }
    
    [launchController updateViewForInterfaceOrientation:interfaceOrientation];
	
    // Update scroll view sizes / content offsets
    channelSwitchingScrollView.contentSize = channelSwitchingScrollView.bounds.size;
    
    controlScrollView.frame = CGRectMake(0.0f, 0.0f, topLevelContainerView.frame.size.width + NM_MOVIE_VIEW_GAP_FLOAT, topLevelContainerView.frame.size.height);
    controlScrollView.contentSize = CGSizeMake((CGFloat)( (topLevelContainerView.frame.size.width + NM_MOVIE_VIEW_GAP) * playbackModelController.numberOfVideos), topLevelContainerView.frame.size.height);
    currentXOffset = (CGFloat)(playbackModelController.currentIndexPath.row * (topLevelContainerView.frame.size.width + NM_MOVIE_VIEW_GAP));
    controlScrollView.contentOffset = CGPointMake(currentXOffset, 0.0f);
    
    // Update detail view positions
    for (UIView *view in movieDetailViewArray) {
        view.frame = CGRectMake(view.tag * (topLevelContainerView.frame.size.width + NM_MOVIE_VIEW_GAP), 0.0f, topLevelContainerView.frame.size.width, topLevelContainerView.frame.size.height);
    }
    
    // Update controls / movie position
	CGRect theFrame = loadedControlView.frame;
	theFrame.origin.x = controlScrollView.contentOffset.x + movieXOffset;
	loadedControlView.frame = theFrame;

	theFrame = movieView.frame;
	theFrame.origin.x = controlScrollView.contentOffset.x + movieXOffset;
    theFrame.size.width = topLevelContainerView.frame.size.width;
    theFrame.size.height = topLevelContainerView.frame.size.height;
	movieView.frame = theFrame;
    loadedControlView.frame = theFrame;
    
    // Update "pull to switch" positions
    theFrame = nextChannelHeaderView.frame;
	theFrame.origin.y = topLevelContainerView.frame.size.height;
    theFrame.size.width = topLevelContainerView.frame.size.width;
	nextChannelHeaderView.frame = theFrame;
    
    theFrame = previousChannelHeaderView.frame;
    theFrame.size.width = topLevelContainerView.frame.size.width;
    previousChannelHeaderView.frame = theFrame;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [gridNavigationController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self updateViewsForInterfaceOrientation:toInterfaceOrientation];
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
	[gridNavigationController release];
    [gridNavigationContainer release];
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
    [ratingsURL release];

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
    
    ChannelGridController *gridController = [[ChannelGridController alloc] initWithNibName:@"GridController" bundle:[NSBundle mainBundle]];
    gridController.delegate = self;
    gridController.managedObjectContext = self.managedObjectContext;
    gridNavigationController = [[SizableNavigationController alloc] initWithRootViewController:gridController];
    gridNavigationController.playbackModelController = playbackModelController;
    gridNavigationController.playbackViewController = self;
    [gridController release];
    
    gridNavigationContainer = [[UIView alloc] initWithFrame:gridController.view.frame];
    gridNavigationContainer.backgroundColor = [UIColor clearColor];
    gridNavigationContainer.clipsToBounds = YES;
    gridNavigationContainer.autoresizesSubviews = YES;
    [gridNavigationContainer addSubview:gridNavigationController.view];
    [self.view addSubview:gridNavigationContainer];
    
    [self updateViewsForInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation];
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
	[self resetAllMovieDetailViews];     
	// save the channel ID to user defaults
	[appDelegate saveChannelID:chnObj.nm_id];
	
	playFirstVideoOnLaunchWhenReady = aPlayFlag;
	forceStopByUser = NO;	// reset the flag
//	currentXOffset = 0.0f;
	ribbonView.alpha = 0.15;	// set alpha before calling "setVideo" method
	ribbonView.userInteractionEnabled = NO;

	// playbackModelController is responsible for loading the channel managed objects and set up the playback data structure.
	playbackModelController.channel = chnObj;
	chnObj.nm_is_new = (NSNumber *)kCFBooleanFalse;    
    
    // Update highlighted channel in grid
    if ([gridNavigationController.visibleViewController isKindOfClass:[ChannelGridController class]]) {
        [((ChannelGridController *)gridNavigationController.visibleViewController).gridView reloadData];
    }
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
		previousChannelSwitchingLabel.text = @"Switching to previous channel...";
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
		if ( showMovieControlTimestamp > 0 && (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) || !gridShowing)) {
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
    theFrame.size.width = topLevelContainerView.frame.size.width;
    theFrame.size.height = topLevelContainerView.frame.size.height;
	movieView.frame = theFrame;
    
	[UIView animateWithDuration:0.25f delay:0.0f options:0 animations:^{
		movieView.alpha = 1.0f;
	} completion:^(BOOL finished) {
        [loadedControlView setControlsHidden:NO animated:YES];
	}];
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
            theFrame.origin.x = -(topLevelContainerView.frame.size.width + NM_MOVIE_VIEW_GAP_FLOAT);
            theFrame.size.width = topLevelContainerView.frame.size.width;
            theFrame.size.height = topLevelContainerView.frame.size.height;
            loadedMovieDetailView.frame = theFrame;
            loadedMovieDetailView.tag = i;
			[controlScrollView insertSubview:loadedMovieDetailView belowSubview:movieView];
			self.loadedMovieDetailView = nil;
			// movie detail view doesn't need to respond to autoresize
		}
	}
	// get a free view
	for ( NMMovieDetailView * theView in movieDetailViewArray ) {
		if ( theView.video == nil ) {
			theView.hidden = NO;
			return theView;
		}
	}
	// check if any of the video is marked as error
	for ( NMMovieDetailView * theView in movieDetailViewArray ) {
		if ( theView.video.nm_playback_status == NMVideoQueueStatusError ) {
			[self reclaimMovieDetailViewForVideo:theView.video];
			theView.hidden = NO;
			return theView;
		}
	}
	NSLog(@"Problem!! can't get a free movie detail view");
	return nil;
}

- (void)reclaimMovieDetailViewForVideo:(NMVideo *)vdo {
	if ( vdo == nil ) return;
	NMMovieDetailView * theView = vdo.nm_movie_detail_view;
	vdo.nm_movie_detail_view = nil;
	theView.video = nil;
	[theView restoreThumbnailView];
	[theView setActivityViewHidden:YES];
	theView.hidden = YES;
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
		currentXOffset += topLevelContainerView.frame.size.width + NM_MOVIE_VIEW_GAP_FLOAT;
		// scroll to next video
		// translate the movie view
		[UIView animateWithDuration:0.5f animations:^{
			controlScrollView.contentOffset = CGPointMake(currentXOffset, 0.0f);
		}];
        [self reclaimMovieDetailViewForVideo:playbackModelController.previousVideo];
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
		theDetailView = [self dequeueReusableMovieDetailView];
		ctrl.nextVideo.nm_movie_detail_view = theDetailView;
	}
	theDetailView.video = ctrl.nextVideo;
	
	CGFloat xOffset = (CGFloat)(ctrl.nextIndexPath.row * (topLevelContainerView.frame.size.width + NM_MOVIE_VIEW_GAP));
#ifdef DEBUG_PLAYER_NAVIGATION
	NSLog(@"offset of next MDV: %f ptr: %p", xOffset, theDetailView);
#endif
	CGRect theFrame = theDetailView.frame;
	theFrame.origin.x = xOffset;
	theDetailView.frame = theFrame;
    theDetailView.tag = ctrl.nextIndexPath.row;
    
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
	
	CGFloat xOffset = (CGFloat)(ctrl.previousIndexPath.row * (topLevelContainerView.frame.size.width + NM_MOVIE_VIEW_GAP));
#ifdef DEBUG_PLAYER_NAVIGATION
	NSLog(@"offset of previous MDV: %f ptr: %p", xOffset, theDetailView);
#endif
	CGRect theFrame = theDetailView.frame;
	theFrame.origin.x = xOffset;
	theDetailView.frame = theFrame;
    theDetailView.tag = ctrl.previousIndexPath.row;
    
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
	
	CGFloat xOffset = (CGFloat)(ctrl.currentIndexPath.row * (topLevelContainerView.frame.size.width + NM_MOVIE_VIEW_GAP));
#ifdef DEBUG_PLAYER_NAVIGATION
	NSLog(@"offset of current MDV: %f actual: %f ptr: %p, %@", xOffset, theDetailView.frame.origin.x, theDetailView, ctrl.currentVideo.title);
#endif
	CGRect theFrame = theDetailView.frame;
	theFrame.origin.x = xOffset;
	theDetailView.frame = theFrame;
    theDetailView.tag = ctrl.currentIndexPath.row;
    
	// when scrolling is inflight, do not issue the URL resolution request. Playback View Controller will call "advanceToNextVideo" later on which will trigger sending of resolution request.
	if ( !NMVideoPlaybackViewIsScrolling ) [movieView.player resolveAndQueueVideo:ctrl.currentVideo];
}

- (void)controller:(VideoPlaybackModelController *)ctrl didUpdateVideoListWithTotalNumberOfVideo:(NSUInteger)totalNum {
#ifdef DEBUG_PLAYER_NAVIGATION
	NSLog(@"current total num videos: %d", totalNum);
#endif

	controlScrollView.contentSize = CGSizeMake((CGFloat)( (topLevelContainerView.frame.size.width + NM_MOVIE_VIEW_GAP) * totalNum), topLevelContainerView.frame.size.height);
	CGFloat newOffset = (CGFloat)(playbackModelController.currentIndexPath.row * (topLevelContainerView.frame.size.width + NM_MOVIE_VIEW_GAP));
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
	controlScrollView.scrollEnabled = NO;
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
//- (void)delayHandleDidPlayItem:(NMAVPlayerItem *)anItem {
//	if ( playbackModelController.nextVideo == nil ) {
//		// finish up playing the whole channel
//		[self dismissModalViewControllerAnimated:YES];
//	} else {
//		didPlayToEnd = YES;
//		[self showNextVideo:YES];
//	}
//}

- (void)handleDidPlayItemNotification:(NSNotification *)aNotification {
	// For unknown reason, AVPlayerItemDidPlayToEndTimeNotification is sent twice sometimes. Don't know why. This delay execution mechanism tries to solve this problem
#ifdef DEBUG_PLAYBACK_QUEUE
	NSLog(@"did play notification: %@", [aNotification name]);
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
        scrollingNotFromUser = NO;        
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
        if (scrollingNotFromUser) return;
        
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
		return;
	}

	CGFloat dx;
	dx = ABS(currentXOffset - scrollView.contentOffset.x);
	// reduce alpha of the playback view
	movieView.alpha = (topLevelContainerView.frame.size.width - dx) / topLevelContainerView.frame.size.width;    
}

- (void)delayedChangeChannelSwitchingScrollViewOffset {
	CGFloat yOff;
	NMChannel * chnObj = nil;
	switch (channelSwitchStatus) {
		case ChannelSwitchNext:
			chnObj = [nowboxTaskController.dataController nextChannel:currentChannel];
			yOff = topLevelContainerView.frame.size.height;
			break;
		case ChannelSwitchPrevious:
			chnObj = [nowboxTaskController.dataController previousChannel:currentChannel];
			yOff = -topLevelContainerView.frame.size.height;
			break;
			
		default:
			break;
	}
	if ( chnObj ) {
		[self setCurrentChannel:chnObj];
//		[self playVideo:[chnObj.videos anyObject]];
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
			channelSwitchingScrollView.contentInset = UIEdgeInsetsMake(topLevelContainerView.frame.size.height, 0.0f, 0.0f, 0.0f);
			scrollView.scrollEnabled = NO;
			[self stopVideo];
            scrollingNotFromUser = YES;
			[self performSelector:@selector(delayedChangeChannelSwitchingScrollViewOffset) withObject:nil afterDelay:0.0f];
			[self startLoadingChannel:YES];
		} else if ( yOff >= REFRESH_HEADER_HEIGHT ) {
			channelSwitchStatus = ChannelSwitchNext;
			// push the view down
			channelSwitchingScrollView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, topLevelContainerView.frame.size.height, 0.0f);
			scrollView.scrollEnabled = NO;
			[self stopVideo];
            scrollingNotFromUser = YES;            
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
		currentXOffset += topLevelContainerView.frame.size.width + NM_MOVIE_VIEW_GAP_FLOAT;
		// return the movie detail view
		[self reclaimMovieDetailViewForVideo:playbackModelController.previousVideo];
		if ( [playbackModelController moveToNextVideo] ) {
			playbackModelController.previousVideo.nm_did_play = [NSNumber numberWithBool:YES];
			[movieView.player advanceToVideo:playbackModelController.currentVideo];
            
            [[MixpanelAPI sharedAPI] track:AnalyticsEventPlayVideo properties:[NSDictionary dictionaryWithObjectsAndKeys:playbackModelController.channel.title, AnalyticsPropertyChannelName, playbackModelController.currentVideo.title, AnalyticsPropertyVideoName, playbackModelController.currentVideo.nm_id, AnalyticsPropertyVideoId, @"player", AnalyticsPropertySender, @"swipe", AnalyticsPropertyAction, [NSNumber numberWithBool:NM_AIRPLAY_ACTIVE], AnalyticsPropertyAirPlayActive, nil]];		
        }
#ifdef DEBUG_PLAYER_NAVIGATION
		else
			NSLog(@"can't move to next video. no video!!");
#endif
	} else if ( scrollView.contentOffset.x < currentXOffset ) {
		[self stopVideo];
		didSkippedVideo = YES;
		currentXOffset -= topLevelContainerView.frame.size.width + NM_MOVIE_VIEW_GAP_FLOAT;
		[self reclaimMovieDetailViewForVideo:playbackModelController.nextVideo];        
		if ( playbackModelController.previousVideo ) {
			// instruct the data model to rearrange itself
			[playbackModelController moveToPreviousVideo];
			playbackModelController.nextVideo.nm_did_play = [NSNumber numberWithBool:YES];
			// update the queue player
			[movieView.player revertToVideo:playbackModelController.currentVideo];
            
            [[MixpanelAPI sharedAPI] track:AnalyticsEventPlayVideo properties:[NSDictionary dictionaryWithObjectsAndKeys:playbackModelController.channel.title, AnalyticsPropertyChannelName, playbackModelController.currentVideo.title, AnalyticsPropertyVideoName, playbackModelController.currentVideo.nm_id, AnalyticsPropertyVideoId, @"player", AnalyticsPropertySender, @"swipe", AnalyticsPropertyAction, [NSNumber numberWithBool:NM_AIRPLAY_ACTIVE], AnalyticsPropertyAirPlayActive, nil]];
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

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView == channelSwitchingScrollView) {
        scrollingNotFromUser = NO;
    }
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
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) && gridShowing) return;
    
	[UIView animateWithDuration:0.25f animations:^{
		loadedControlView.alpha = 0.0f;
        loadedControlView.toggleGridButton.userInteractionEnabled = NO;
	} completion:^(BOOL finished) {
		if ( finished ) {
            loadedControlView.toggleGridButton.userInteractionEnabled = YES;
		}
	}];
}

- (IBAction)addVideoToFavorite:(id)sender {
	NMVideo * vdo = playbackModelController.currentVideo;
	[nowboxTaskController issueShare:![vdo.nm_favorite boolValue] video:playbackModelController.currentVideo duration:loadedControlView.duration elapsedSeconds:loadedControlView.timeElapsed];
}

- (IBAction)addVideoToQueue:(id)sender {
	NMVideo * vdo = playbackModelController.currentVideo;
    
    showMovieControlTimestamp = loadedControlView.timeElapsed;
    if (![vdo.nm_watch_later boolValue]) {
        [[ToolTipController sharedToolTipController] notifyEvent:ToolTipEventWatchLaterTap sender:sender];
    }
    
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

- (IBAction)toggleGrid:(id)sender {
    gridShowing = !gridShowing;
    
    // Keep controls view showing a little longer
    showMovieControlTimestamp = loadedControlView.timeElapsed;

    if (gridShowing) {
        gridNavigationController.view.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height - loadedControlView.controlContainerView.frame.size.height);            
        gridNavigationContainer.alpha = 1.0f;
    }

    [UIView animateWithInteractiveDuration:0.3
                                animations:^{
                                    if (gridShowing) {
                                        gridNavigationController.view.frame = CGRectOffset(gridNavigationController.view.frame, 0, -self.view.bounds.size.height);
                                        [loadedControlView.toggleGridButton setImage:[UIImage imageNamed:@"toolbar-collapse.png"] forState:UIControlStateNormal];
                                        [loadedControlView.toggleGridButton setImage:[UIImage imageNamed:@"toolbar-collapse-active.png"] forState:UIControlStateHighlighted];
                                    } else {
                                        gridNavigationController.view.frame = CGRectOffset(gridNavigationController.view.frame, 0, self.view.bounds.size.height);
                                        [loadedControlView.toggleGridButton setImage:[UIImage imageNamed:@"toolbar-expand.png"] forState:UIControlStateNormal];
                                        [loadedControlView.toggleGridButton setImage:[UIImage imageNamed:@"toolbar-expand-active.png"] forState:UIControlStateHighlighted];
                                    }                                    
                                }
                                completion:^(BOOL finished){
                                    if (!gridShowing) {
                                        gridNavigationContainer.alpha = 0.0f;
                                    }
                                    
                                    controlScrollView.scrollEnabled = !gridShowing;
                                    channelSwitchingScrollView.scrollEnabled = !gridShowing;
                                }];
}

# pragma mark Gestures
- (void)handleMovieViewPinched:(UIPinchGestureRecognizer *)sender {
    
}

#pragma mark - Keyboard resizing

- (void)resizeViewForKeyboardUserInfo:(NSDictionary *)userInfo
{
    NSValue *sizeValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    NSValue *durationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    
    CGSize keyboardSize = [sizeValue CGRectValue].size;
    
    NSTimeInterval duration = 0;
    [durationValue getValue:&duration];
    
    CGRect frame = gridNavigationContainer.frame;
    frame.origin.y = 0;
    
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        frame.size.height = self.view.frame.size.height - keyboardSize.height;
    } else {
        frame.size.height = self.view.frame.size.width - keyboardSize.width;
    }
    
    [UIView animateWithDuration:duration
                     animations:^{
                         gridNavigationContainer.frame = frame;
                         gridNavigationController.view.frame = gridNavigationContainer.bounds;
                     }];    
}

- (void)keyboardWillAppear:(NSNotification *)notification
{
    [self resizeViewForKeyboardUserInfo:[notification userInfo]];
}

- (void)keyboardWillDisappear:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    NSValue *durationValue = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    
    NSTimeInterval duration = 0;
    [durationValue getValue:&duration];
    
    CGRect frame = gridNavigationContainer.frame;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        frame.origin.y = self.view.frame.size.height / 2;
        frame.size.height = self.view.frame.size.height / 2;
    } else {
        frame.origin.y = 0;
        frame.size.height = self.view.frame.size.width;
    }
    
    [UIView animateWithDuration:duration
                     animations:^{
                         [self updateViewsForInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
//                         gridNavigationContainer.frame = frame;
//                         gridNavigationController.view.frame = gridNavigationContainer.bounds;
                     }];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    [self resizeViewForKeyboardUserInfo:[notification userInfo]];
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

#pragma mark - GridControllerDelegate

- (void)gridController:(GridController *)gridController didSelectChannel:(NMChannel *)channel
{

}

- (void)gridController:(GridController *)gridController didSelectVideo:(NMVideo *)video
{
    [self playVideo:video];
    
    if (gridShowing && UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        // Hide grid
        [self toggleGrid:nil];
    }
}

#pragma mark Debug

#ifdef DEBUG_PLAYER_NAVIGATION
- (NMAVQueuePlayer *)getQueuePlayer {
	return movieView.player;
}

#endif

@end