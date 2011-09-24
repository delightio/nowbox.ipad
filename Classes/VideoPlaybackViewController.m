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
#import "ipadAppDelegate.h"
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
#define NM_ANIMATION_HIDE_CONTROL_VIEW_FOR_USER			10001
#define NM_ANIMATION_RIBBON_FADE_OUT_CONTEXT			10002
#define NM_ANIMATION_RIBBON_FADE_IN_CONTEXT				10003
#define NM_ANIMATION_FAVORITE_BUTTON_ACTIVE_CONTEXT		10004
#define NM_ANIMATION_WATCH_LATER_BUTTON_ACTIVE_CONTEXT	10005
#define NM_ANIMATION_FULL_PLAYBACK_SCREEN_CONTEXT		10006
#define NM_ANIMATION_SPLIT_VIEW_CONTEXT					10007
#define NM_ANIMATION_VIDEO_THUMBNAIL_CONTEXT			10008
#define NM_ANIMATION_FULL_SCREEN_CHANNEL_CONTEXT		10009

@interface VideoPlaybackViewController (PrivateMethods)

//- (void)insertVideoAtIndex:(NSUInteger)idx;
//- (void)queueVideoToPlayer:(NMVideo *)vid;
- (void)controlsViewTouchUp:(id)sender;
- (void)configureControlViewForVideo:(NMVideo *)aVideo;
- (void)configureDetailViewForContext:(NSInteger)ctx;
- (void)showNextVideo:(BOOL)didPlayToEnd;
- (void)playCurrentVideo;
- (void)stopVideo;
- (void)setupPlayer;
- (void)hideControlView;

- (NMVideo *)playerCurrentVideo;

// debug message
- (void)printDebugMessage:(NSString *)str;

@end


@implementation VideoPlaybackViewController
@synthesize managedObjectContext=managedObjectContext_;
@synthesize currentChannel;
@synthesize channelController;
@synthesize loadedControlView;
@synthesize loadedMovieDetailView;
@synthesize appDelegate;

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
	[[UIApplication sharedApplication] setStatusBarHidden:NO];
//	self.wantsFullScreenLayout = YES;
	isAspectFill = YES;
	currentXOffset = 0.0f;
	movieXOffset = 0.0f;
	showMovieControlTimestamp = -1;
	fullScreenRect = CGRectMake(0.0f, 0.0f, 1024.0f, 768.0f);
	splitViewRect = CGRectMake(0.0f, 0.0f, 1024.0f, 380.0f);
	
	// ribbon view
	ribbonView.layer.contents = (id)[UIImage imageNamed:@"ribbon"].CGImage;
	ribbonView.layer.shouldRasterize = YES;
	
	// playback data model controller
	nowmovTaskController = [NMTaskQueueController sharedTaskQueueController];
	playbackModelController = [VideoPlaybackModelController sharedVideoPlaybackModelController];
	playbackModelController.managedObjectContext = self.managedObjectContext;
	playbackModelController.dataDelegate = self;

	// pre-load the movie detail view. we need to cache 3 of them so that user can see the current, next and previous movie detail with smooth scrolling transition
	NSBundle * mb = [NSBundle mainBundle];
	CGRect theFrame;
	movieDetailViewArray = [[NSMutableArray alloc] initWithCapacity:3];
	for (NSInteger i = 0; i < 3; i++) {
		[mb loadNibNamed:@"MovieDetailInfoView" owner:self options:nil];
		[movieDetailViewArray addObject:self.loadedMovieDetailView];
		theFrame = loadedMovieDetailView.frame;
		theFrame.origin.y = 0.0f;
		theFrame.origin.x = -1024.0f;
		loadedMovieDetailView.frame = theFrame;
		loadedMovieDetailView.alpha = 0.0f;
		[controlScrollView addSubview:loadedMovieDetailView];
		// movie detail view doesn't need to respond to autoresize
	}
	self.loadedMovieDetailView = nil;
	
	// === don't change the sequence in this block ===
	// create movie view
	movieView = [[NMMovieView alloc] initWithFrame:CGRectMake(movieXOffset, 20.0f, 640.0f, 360.0f)];
	// set target-action methods
	[movieView addTarget:self action:@selector(movieViewTouchUp:)];
	[controlScrollView addSubview:movieView];
	controlScrollView.frame = splitViewRect;
	
	// pre-load control view
	// load the nib
	[mb loadNibNamed:@"VideoControlView" owner:self options:nil];
	// hook up with target-action
	[loadedControlView addTarget:self action:@selector(controlsViewTouchUp:)];
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
	[nowmovTaskController issueGetFeaturedCategories];
	
	// load channel view
	[[NSBundle mainBundle] loadNibNamed:@"ChannelPanelView" owner:self options:nil];
	theFrame = channelController.panelView.frame;
	theFrame.origin.y = splitViewRect.size.height;
	channelController.panelView.frame = theFrame;
	channelController.videoViewController = self;
	[self.view addSubview:channelController.panelView];
    
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
	[movieView addGestureRecognizer:pinRcr];
	[pinRcr release];
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
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
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
	[super dealloc];
}

#pragma mark Playback data structure

- (void)markPlaybackCheckpoint {
	NMVideo * theVideo = [self playerCurrentVideo];
	CMTime aTime = movieView.player.currentTime;
	if ( aTime.flags & kCMTimeFlags_Valid ) {
		currentChannel.nm_time_elapsed_value = [NSNumber numberWithLongLong:aTime.value];
		currentChannel.nm_time_elapsed_timescale = [NSNumber numberWithInteger:aTime.timescale];
	}
	// send event back to nowmov server
	currentChannel.nm_last_vid = theVideo.nm_id;
	// send event back to nowmov server
	[nowmovTaskController issueSendViewEventForVideo:playbackModelController.currentVideo duration:loadedControlView.duration elapsedSeconds:loadedControlView.timeElapsed playedToEnd:NO];
}


- (void)setCurrentChannel:(NMChannel *)chnObj {
	if ( currentChannel ) {
		if ( currentChannel != chnObj ) {
			// clear all task related to the previous channel
			[nowmovTaskController cancelAllPlaybackTasksForChannel:currentChannel];
			[currentChannel release];
			currentChannel = [chnObj retain];
		}
	} else {
		currentChannel = [chnObj retain];
	}
	// save the channel ID to user defaults
	[appDelegate saveChannelID:chnObj.nm_id];
	
	currentXOffset = 0.0f;
	// playbackModelController is responsible for loading the channel managed objects and set up the playback data structure.
	playbackModelController.channel = chnObj;
	NSArray * vidAy = [playbackModelController videosForBuffering];
	if ( vidAy ) {
		[movieView.player resolveAndQueueVideos:vidAy];
	}
	
	if ( chnObj == nil ) {
		for (NMMovieDetailView * theDetailView in movieDetailViewArray) {
			theDetailView.video = nil;
		}
		
		[loadedControlView resetView];
		return;	// return if the channel object is nil
	}
	
	// update the interface if necessary
//	[movieView setActivityIndicationHidden:NO animated:NO];
	[self updateRibbonButtons];
	[playbackModelController.currentVideo.nm_movie_detail_view fadeOutThumbnailView:self context:(void *)NM_ANIMATION_VIDEO_THUMBNAIL_CONTEXT];
//	if ( playbackModelController.currentVideo == nil ) {
		// we need to wait for video to come. show loading view
		//controlScrollView.scrollEnabled = NO;
//	}
	
	//TODO: update the scroll view content size, set position of movie view and control view
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
	if ( movieView.player.rate == 0.0 ) {
		[movieView.player play];
	}
}

- (IBAction)playStopVideo:(id)sender {
	if ( movieView.player.rate == 0.0 ) {
		[movieView.player play];
	} else {
		[movieView.player pause];
	}
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
	[movieView.layer addObserver:self forKeyPath:@"readyForDisplay" options:0 context:(void *)NM_VIDEO_READY_FOR_DISPLAY_CONTEXT];
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
				[self hideControlView];
			}
		}
	}];
	// retain the time observer
	[timeObserver retain];
}

#pragma mark Control Views Management
- (void)configureControlViewForVideo:(NMVideo *)aVideo {
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
	[UIView animateWithDuration:0.25f delay:0.5f options:0 animations:^{
		movieView.alpha = 1.0f;
	} completion:^(BOOL finished) {
		[loadedControlView setControlsHidden:NO animated:YES];
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

- (void)hideControlView {
	if ( loadedControlView.alpha > 0.0f ) {
		[UIView animateWithDuration:0.25f animations:^{
			loadedControlView.alpha = 0.0f;
		}];
	}
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	NSInteger ctxInt = (NSInteger)context;
	switch (ctxInt) {
		case NM_ANIMATION_HIDE_CONTROL_VIEW_FOR_USER:
			showMovieControlTimestamp = loadedControlView.timeElapsed;
			break;
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
			[loadedControlView setTopBarHidden:NO animated:YES];
			// hide all movie detail view
//			for (NMMovieDetailView * theDetailView in movieDetailViewArray) {
//				theDetailView.hidden = YES;
//			}
			[self configureDetailViewForContext:ctxInt];
			ribbonView.hidden = YES;
			break;
			
		case NM_ANIMATION_FULL_SCREEN_CHANNEL_CONTEXT:
			[channelController postAnimationChangeForDisplayMode:NMFullScreenChannelMode];
			break;
			
		case NM_ANIMATION_SPLIT_VIEW_CONTEXT:
			controlScrollView.frame = splitViewRect;
			[channelController postAnimationChangeForDisplayMode:NMHalfScreenMode];
			break;
		case NM_ANIMATION_VIDEO_THUMBNAIL_CONTEXT:
			controlScrollView.scrollEnabled = YES;
			[self configureControlViewForVideo:[self playerCurrentVideo]];
			break;
		default:
			break;
	}
}

#pragma mark Ribbon management

- (void)updateRibbonButtons {
	[self updateFavoriteButton];
	[self updateWatchLaterButton];
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
	[nowmovTaskController issueSendViewEventForVideo:theVideo duration:loadedControlView.duration elapsedSeconds:loadedControlView.timeElapsed playedToEnd:aEndOfVideo];
	// visually transit to next video just like the user has tapped next button
	//if ( aEndOfVideo ) {
	// disable interface scrolling
	// will activate again on "currentItem" change kvo notification
	controlScrollView.scrollEnabled = NO;
	// fade out the view
	[UIView animateWithDuration:0.75f animations:^(void) {
		movieView.alpha = 0.0f;
	} completion:^(BOOL finished) {
		currentXOffset += 1024.0f;
		// scroll to next video
		// translate the movie view
		controlScrollView.contentOffset = CGPointMake(currentXOffset, 0.0f);
		if ( [playbackModelController moveToNextVideo] ) {
			playbackModelController.previousVideo.nm_did_play = [NSNumber numberWithBool:YES];
			[movieView.player advanceToVideo:playbackModelController.currentVideo];
		}
		[playbackModelController.currentVideo.nm_movie_detail_view fadeOutThumbnailView:self context:(void *)NM_ANIMATION_VIDEO_THUMBNAIL_CONTEXT];
//		controlScrollView.scrollEnabled = YES;
	}];
	// when traisition is done. move shift the scroll view and reveals the video player again
	// this method does not handle the layout (position) of the movie control. that should be handled in scroll view delegate method
}

- (void)playVideo:(NMVideo *)aVideo {
	// Channel View calls this method when user taps a video from the table
	// stop video
	[self stopVideo];
	// flush the video player
	[movieView.player removeAllItems];	// optimize for skipping to next or next-next video. Do not call this method those case
	// show progress indicator
//	[movieView setActivityIndicationHidden:NO animated:NO];
	didSkippedVideo = YES;

	// save the channel ID to user defaults
	[appDelegate saveChannelID:aVideo.channel.nm_id];
	// play the specified video
	ribbonView.alpha = 0.15;	// set alpha before calling "setVideo" method
	ribbonView.userInteractionEnabled = NO;
	[playbackModelController setVideo:aVideo];
//	[self updateRibbonButtons];
//	[playbackModelController.currentVideo.nm_movie_detail_view fadeOutThumbnailView:self context:(void *)NM_ANIMATION_VIDEO_THUMBNAIL_CONTEXT];
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
	
	CGFloat xOffset = (CGFloat)(ctrl.nextIndexPath.row * 1024);
#ifdef DEBUG_PLAYER_NAVIGATION
	NSLog(@"offset of next MDV: %f", xOffset);
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
	
	CGFloat xOffset = (CGFloat)(ctrl.previousIndexPath.row * 1024);
#ifdef DEBUG_PLAYER_NAVIGATION
	NSLog(@"offset of previous MDV: %f", xOffset);
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
	
	CGFloat xOffset = (CGFloat)(ctrl.currentIndexPath.row * 1024);
#ifdef DEBUG_PLAYER_NAVIGATION
	NSLog(@"offset of current MDV: %f actual: %f %@", xOffset, theDetailView.frame.origin.x, ctrl.currentVideo.title);
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
	controlScrollView.contentSize = CGSizeMake((CGFloat)(1024 * totalNum), 380.0f);
	CGFloat newOffset = (CGFloat)(playbackModelController.currentIndexPath.row * 1024);
	if ( ribbonView.alpha < 1.0f ) {
		[self performSelector:@selector(delayRestoreDetailView) withObject:nil afterDelay:0.5f];
	}
	if ( currentXOffset > 0.0f && newOffset == currentXOffset ) return;
	currentXOffset = newOffset;
	CGPoint thePoint = CGPointMake(currentXOffset, 0.0f);
//	[controlScrollView scrollRectToVisible:CGRectMake(currentXOffset, 0.0f, 1024.0f, 380.0f) animated:YES];
	[UIView animateWithDuration:0.5f animations:^{
		controlScrollView.contentOffset = thePoint;
	} completion:^(BOOL finished) {
		[self performSelector:@selector(delayRestoreDetailView) withObject:nil afterDelay:0.5f];
	}];
//	[controlScrollView setContentOffset:thePoint animated:YES];
//	[self configureControlViewForVideo:playbackModelController.currentVideo];
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
	[anItem addObserver:self forKeyPath:@"status" options:0 context:(void *)NM_PLAYER_ITEM_STATUS_CONTEXT];
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
	[anItem removeObserver:self forKeyPath:@"status"];
}

//- (void)player:(NMAVQueuePlayer *)aPlayer directURLResolutionErrorForVideo:(NMVideo *)aVideo {
//	[playbackModelController ]
//}

- (void)player:(NMAVQueuePlayer *)aPlayer willBeginPlayingVideo:(NMVideo *)vid {
	
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

- (void)handleDidPlayItemNotification:(NSNotification *)aNotification {
#ifdef DEBUG_PLAYBACK_QUEUE
	NSLog(@"did play notification");
#endif
	if ( playbackModelController.nextVideo == nil ) {
		// finish up playing the whole channel
		[self dismissModalViewControllerAnimated:YES];
	} else {
		didPlayToEnd = YES;
		[self showNextVideo:YES];
	}
}

- (void)handleApplicationDidBecomeActiveNotification:(NSNotification *)aNotification {
	// resume playing the video
	[self playCurrentVideo];
	NMAVPlayerItem * item = (NMAVPlayerItem *)movieView.player.currentItem;
	// send event back to server
	[nowmovTaskController issueSendViewEventForVideo:item.nmVideo duration:loadedControlView.duration elapsedSeconds:loadedControlView.timeElapsed playedToEnd:NO];
}

- (void)handleChannelManagementNotification:(NSNotification *)aNotification {
	if ( NM_RUNNING_IOS_5 ) {
		if ( [[aNotification name] isEqualToString:NMChannelManagementWillAppearNotification] ) {
			// stop video from playing
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_4_3
			if ( !movieView.player.airPlayVideoActive ) [self stopVideo];
#endif
		} else {
			// resume video playing
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_4_3
			if ( !movieView.player.airPlayVideoActive ) [self playCurrentVideo];
#endif
		}
	} else {
		if ( [[aNotification name] isEqualToString:NMChannelManagementWillAppearNotification] ) {
			// stop video from playing
			[self stopVideo];
		} else {
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
		[self animateFavoriteButtonsToActive];
	} else if ( [name isEqualToString:NMDidUnfavoriteVideoNotification] && [playbackModelController.currentVideo isEqual:vidObj] ) {
		[self animateFavoriteButtonsToActive];
	} else if ( [name isEqualToString:NMDidEnqueueVideoNotification] && [playbackModelController.currentVideo isEqual:vidObj] ) {
		// queued a video successfully, animate the icon to appropriate state
		[self animateWatchLaterButtonsToActive];
	} else if ( [name isEqualToString:NMDidDequeueVideoNotification] && [playbackModelController.currentVideo isEqual:vidObj] ) {
		// dequeued a video successfully
		[self animateWatchLaterButtonsToActive];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	NSInteger c = (NSInteger)context;
//	CMTime t;
	if ( c == NM_PLAYER_STATUS_CONTEXT ) {
		switch (movieView.player.status) {
			case AVPlayerStatusReadyToPlay:
			{
				// the instance is ready to play. show time and progress view
//				[loadedControlView setControlsHidden:NO animated:YES];
//				t = movieView.player.currentItem.asset.duration;
//				// check if the time is value
//				if ( t.flags & kCMTimeFlags_Valid ) {
//					loadedControlView.duration = t.value / t.timescale;
//					videoDurationInvalid = NO;
//				} else {
//					videoDurationInvalid = YES;
//				}
//				[movieView setActivityIndicationHidden:YES animated:YES];
				[playbackModelController.currentVideo.nm_movie_detail_view fadeOutThumbnailView:self context:(void *)NM_ANIMATION_VIDEO_THUMBNAIL_CONTEXT];
				break;
			}
			default:
				break;
		}
	} else if ( c == NM_PLAYER_CURRENT_ITEM_CONTEXT ) {
		// update video status
		NMAVPlayerItem * curItem = (NMAVPlayerItem *)movieView.player.currentItem;
		curItem.nmVideo.nm_playback_status = NMVideoQueueStatusCurrentVideo;
		// never change currentIndex here!!
		// ====== update interface ======
//		[self configureControlViewForVideo:[self playerCurrentVideo]]; moved to animation delegate
		// update the time

		// show the control view
		[loadedControlView setControlsHidden:NO animated:YES];
		
		showMovieControlTimestamp = 1;
		
//		t = movieView.player.currentItem.asset.duration;
//		// check if the time is valid
//		if ( t.flags & kCMTimeFlags_Valid ) {
//			loadedControlView.duration = t.value / t.timescale;
//			videoDurationInvalid = NO;
//		} else {
//			videoDurationInvalid = YES;
//		}
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
	} else if ( c == NM_AIR_PLAY_VIDEO_ACTIVE_CONTEXT ) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_4_3
		if ( movieView.player.airPlayVideoActive ) {
			// update the player interface to indicate that Airplay has been enabled
			[movieView hideAirPlayIndicatorView:NO];
			// Apple TV does not send remote event back to app. No need to implement for now.
			// receive remote event
//			[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
//			[self becomeFirstResponder];
		} else {
			// remove the interface indication
			[movieView hideAirPlayIndicatorView:YES];
			// Apple TV does not send remote event back to app. No need to implement for now.
//			[[UIApplication sharedApplication] endReceivingRemoteControlEvents];
//			[self resignFirstResponder];
		}
#endif
	}
	// refer to https://pipely.lighthouseapp.com/projects/77614/tickets/93-study-video-switching-behavior-how-to-show-loading-ui-state
	else if ( c == NM_VIDEO_READY_FOR_DISPLAY_CONTEXT) {
#ifdef DEBUG_PLAYER_NAVIGATION
//		AVPlayerLayer * theLayer = (AVPlayerLayer *)object;
//		NSLog(@"ready for display? %d", theLayer.readyForDisplay);
#endif
	} else if ( c == NM_PLAYBACK_LIKELY_TO_KEEP_UP_CONTEXT ) {
//		NMAVPlayerItem * theItem = (NMAVPlayerItem *)object;
//		NSLog(@"%@ buffer status - keep up: %d full: %d", theItem.nmVideo.title, theItem.playbackLikelyToKeepUp, theItem.playbackBufferFull);
	} else if ( c == NM_PLAYER_ITEM_STATUS_CONTEXT ) {
//		NMAVPlayerItem * theItem = (NMAVPlayerItem *)object;
//		NSLog(@"%@ status: %d", theItem.nmVideo.title, theItem.status);
	} else if ( c == NM_PLAYER_RATE_CONTEXT ) {
		// NOTE:
		// AVQueuePlayer may not post any KVO notification to us on "rate" change.
//		if ( didSkippedVideo && movieView.player.rate == 0.0f ) {
//			// show loading
//			[movieView setActivityIndicationHidden:NO animated:YES];
//		}
//		if ( movieView.player.rate > 0.0f && movieView.activityIndicator.alpha > 0.0 ) {
//			[movieView setActivityIndicationHidden:YES animated:YES];
//		}
		[loadedControlView setPlayButtonStateForRate:movieView.player.rate];
		/*
		if ( didSkippedVideo ) {
			if ( movieView.player.rate == 0.0f ) {
				// show loading
				[movieView setActivityIndicationHidden:NO animated:YES];
			} else {
				didSkippedVideo = NO;
				[movieView setActivityIndicationHidden:YES animated:YES];
			}
			NSLog(@"skipping video - play rate: %f %d", movieView.player.rate, didSkippedVideo);
		}*/
		NSLog(@"rate change: %f", movieView.player.rate);
	} else if ( c == NM_PLAYBACK_LOADED_TIME_RANGES_CONTEXT && object == movieView.player.currentItem ) {
		// buffering progress
		NMAVPlayerItem * theItem = (NMAVPlayerItem *)object;
		NSValue * theRangeValue = [theItem.loadedTimeRanges lastObject];
		if ( theRangeValue ) {
			loadedControlView.timeRangeBuffered = [theRangeValue CMTimeRangeValue];
		}
	}
	/*else if ( c == NM_PLAYBACK_BUFFER_EMPTY_CONTEXT) {
		bufferEmpty = [[object valueForKeyPath:keyPath] boolValue];
	} else if ( c == NM_PLAYBACK_LIKELY_TO_KEEP_UP_CONTEXT ) {
		NSLog(@"%@ %@", keyPath, [object valueForKeyPath:keyPath]);
	}*/
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark Playback view UI update
- (void)delayRestoreDetailView {
	// update which video the buttons hook up to
	[self updateRibbonButtons];
	[playbackModelController.currentVideo.nm_movie_detail_view fadeOutThumbnailView:self context:(void *)NM_ANIMATION_VIDEO_THUMBNAIL_CONTEXT];
	[UIView animateWithDuration:0.25f animations:^{
		ribbonView.alpha = 1.0f;
	}];
	ribbonView.userInteractionEnabled = YES;
}

- (void)configureDetailViewForContext:(NSInteger)ctx {
	switch (ctx) {
		case NM_ANIMATION_SPLIT_VIEW_CONTEXT:
			for (NMMovieDetailView * dtlView in movieDetailViewArray) {
				// hide everything except the thumbnail view
				[dtlView configureMovieThumbnailForFullScreen:NO];
			}
			break;
			
		case NM_ANIMATION_FULL_PLAYBACK_SCREEN_CONTEXT:
			for (NMMovieDetailView * dtlView in movieDetailViewArray) {
				[dtlView configureMovieThumbnailForFullScreen:YES];
			}
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
	NMVideoPlaybackViewIsScrolling = YES;
	[UIView animateWithDuration:0.25f animations:^{
		ribbonView.alpha = 0.15;
	}];
	ribbonView.userInteractionEnabled = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	CGFloat dx;
	if ( scrollView.contentOffset.x < currentXOffset ) {
		dx = currentXOffset - scrollView.contentOffset.x;
	} else {
		dx = scrollView.contentOffset.x - currentXOffset;
	}
	movieView.alpha = (1024.0 - dx) / 1024.0;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	// this delegate method is called when user has lifted their thumb out of the screen
	[self stopVideo];
	// this is for preventing user from flicking continuous. user has to flick through video one by one. scrolling will enable again in "scrollViewDidEndDecelerating"
	scrollView.scrollEnabled = NO;
//	NMControlsView * ctrlView = [controlViewArray objectAtIndex:RRIndex(currentIndex)];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	// switch to the next/prev video
//	scrollView.scrollEnabled = YES; move to animation handler
	if ( scrollView.contentOffset.x > currentXOffset ) {
//		[movieView setActivityIndicationHidden:NO animated:NO];
		didSkippedVideo = YES;
		currentXOffset += 1024.0f;
		if ( [playbackModelController moveToNextVideo] ) {
			playbackModelController.previousVideo.nm_did_play = [NSNumber numberWithBool:YES];
			[movieView.player advanceToVideo:playbackModelController.currentVideo];
			[self updateRibbonButtons];
			[playbackModelController.currentVideo.nm_movie_detail_view fadeOutThumbnailView:self context:(void *)NM_ANIMATION_VIDEO_THUMBNAIL_CONTEXT];
		}
#ifdef DEBUG_PLAYER_NAVIGATION
		else
			NSLog(@"can't move to next video. no video!!");
#endif
	} else if ( scrollView.contentOffset.x < currentXOffset ) {
//		[movieView setActivityIndicationHidden:NO animated:NO];
		didSkippedVideo = YES;
		currentXOffset -= 1024.0f;
		if ( playbackModelController.previousVideo ) {
			[playbackModelController moveToPreviousVideo];
			playbackModelController.nextVideo.nm_did_play = [NSNumber numberWithBool:YES];
			[movieView.player revertToVideo:playbackModelController.currentVideo];
			[self updateRibbonButtons];
			[playbackModelController.currentVideo.nm_movie_detail_view fadeOutThumbnailView:self context:(void *)NM_ANIMATION_VIDEO_THUMBNAIL_CONTEXT];
		}
	} else {
		// play the video again
		[self playCurrentVideo];
		scrollView.scrollEnabled = YES;
		// this method pairs with "stopVideo" in scrollViewDidEndDragging
		// prefer to stop video when user has lifted their thumb. This usually means scrolling is likely to continue. I.e. the prev/next page will be shown. If the video keeps playing when we are showing the next screen, it will be weird. (background sound still playing)
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
	if ( !NMVideoPlaybackViewIsScrolling ) {
		controlScrollView.scrollEnabled = NO;
	}
	return !NMVideoPlaybackViewIsScrolling;
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

	CGRect viewRect;
	
	[UIView beginAnimations:nil context:(panelHidden ? (void *)NM_ANIMATION_SPLIT_VIEW_CONTEXT : (void *)NM_ANIMATION_FULL_PLAYBACK_SCREEN_CONTEXT)];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:0.5f];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView setAnimationDelegate:self];
	if ( panelHidden ) {
		// slide in the channel view with animation
		movieXOffset = 0.0f;
		//MARK: not sure if we still need to show/hide status bar
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
		viewRect = CGRectMake(movieView.frame.origin.x + movieXOffset, 20.0f, 640.0f, 360.0f);
		movieView.frame = viewRect;
		[loadedControlView setPlaybackMode:NMHalfScreenMode animated:NO];
		// fade in detail view
		playbackModelController.currentVideo.nm_movie_detail_view.alpha = 1.0f;
		// slide in
		theFrame.origin.y = splitViewRect.size.height;
		channelController.panelView.frame = theFrame;
	} else {
		// slide out the channel view
		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
		viewRect = CGRectMake(movieView.frame.origin.x - movieXOffset, 0.0f, 1024.0f, 768.0f);
		movieView.frame = viewRect;
		[loadedControlView setPlaybackMode:NMFullScreenPlaybackMode animated:NO];
		// fade out detail view
		playbackModelController.currentVideo.nm_movie_detail_view.alpha = 0.0f;
		// reset offset value
		movieXOffset = 0.0f;
		ribbonView.alpha = 0.0f;
		// slide out
		theFrame.origin.y = 768.0;
		channelController.panelView.frame = theFrame;
	}
	[UIView commitAnimations];
	if ( panelHidden ) {
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
		for (NMMovieDetailView * theDetailView in movieDetailViewArray) {
			theDetailView.hidden = NO;
			theDetailView.alpha = 1.0f;
		}
		[self configureDetailViewForContext:NM_ANIMATION_SPLIT_VIEW_CONTEXT];
	} else {
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
	CGRect theFrame = channelController.panelView.frame;
	CGRect scrollFrame = controlScrollView.frame;
	
	[UIView beginAnimations:nil context:(void*)(shouldToggleToFullScreen ? NM_ANIMATION_FULL_SCREEN_CHANNEL_CONTEXT : NM_ANIMATION_SPLIT_VIEW_CONTEXT)];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:0.5f];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView setAnimationDelegate:self];
	if ( shouldToggleToFullScreen ) {
		// move the channel panel up
		theFrame.origin.y = 20.0f;
		[channelController setDisplayMode:NMFullScreenChannelMode];
		scrollFrame.origin.y -= scrollFrame.size.height;
	} else {
		// move the panel down
		theFrame.origin.y = splitViewRect.size.height;
		[channelController setDisplayMode:NMHalfScreenMode];
		scrollFrame.origin.y = splitViewRect.origin.y;
	}
	channelController.panelView.frame = theFrame;
	controlScrollView.frame = scrollFrame;
	[UIView commitAnimations];
//    CGRect theFrame;
//	theFrame = channelController.panelView.frame;
//
//	BOOL panelIsFullScreen = NO;
//	if ( theFrame.origin.y < 380.0 ) {
//		// assume the panel is full screen
//		panelIsFullScreen = YES;
//	}
//    
//    if (!panelIsFullScreen && !shouldToggleToFullScreen && shouldResume) {
//        [self toggleChannelPanel:nil];
//    }
//    
//    if (panelIsFullScreen == shouldToggleToFullScreen) {
//        // no need to do anything else
//        return;
//    }
//
////    if (shouldToggleToFullScreen) {
////        [self stopVideo];
////    }
////    else {
////        if (shouldResume) {
////            [self playCurrentVideo];
////        }
////    }
//  
//    // resize animation is slow, so doing this out of animation
//    if (shouldToggleToFullScreen) {
//        theFrame.size.height = 748-8;
//        channelController.panelView.frame = theFrame;
//    }    
//    
//    theFrame = channelController.panelView.frame;
//    [UIView beginAnimations:nil context:nil];
//	[UIView setAnimationBeginsFromCurrentState:YES];
//	[UIView setAnimationDuration:0.5f];
//
//    if (shouldToggleToFullScreen) {
//        theFrame = channelController.panelView.frame;
//        // the dimensions are hard coded :(
//        theFrame.origin.y = 20;
//
////		movieView.frame = CGRectMake(0, -340, 640.0f, 360.0f);
//
//        [channelController.fullScreenButton setImage:styleUtility.toolbarCollapseImage forState:UIControlStateNormal];
//        [channelController.fullScreenButton setImage:styleUtility.toolbarCollapseHighlightedImage forState:UIControlStateHighlighted];
//        
//        controlScrollView.frame = CGRectMake(0, -360, controlScrollView.frame.size.width, controlScrollView.frame.size.height);
//
//        channelController.panelView.frame = theFrame;
//        [channelController.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:indexInTable inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
//        
//    }
//    else {
//        theFrame = channelController.panelView.frame;
//        // the dimensions are hard coded :(
//        theFrame.size.height = 380;
//        theFrame.origin.y = 380;
//		
////        movieView.frame = CGRectMake(0, 20.0f, 640.0f, 360.0f);
//
//        [channelController.fullScreenButton setImage:styleUtility.toolbarExpandImage forState:UIControlStateNormal];
//        [channelController.fullScreenButton setImage:styleUtility.toolbarExpandHighlightedImage forState:UIControlStateHighlighted];
//        
//        controlScrollView.frame = CGRectMake(0, 0, controlScrollView.frame.size.width, controlScrollView.frame.size.height);
//
//        channelController.panelView.frame = theFrame;
//        [channelController.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:indexInTable inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
//    }
//    [UIView commitAnimations];
}

- (void)movieViewTouchUp:(id)sender {
	// show the control view
	[UIView beginAnimations:nil context:(void*)NM_ANIMATION_HIDE_CONTROL_VIEW_FOR_USER];
	loadedControlView.alpha = 1.0;
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView commitAnimations];
}

- (void)controlsViewTouchUp:(id)sender {
	UIView * v = (UIView *)sender;
	// hide the control view
	[UIView beginAnimations:nil context:nil];
	v.alpha = 0.0;
	[UIView commitAnimations];
}

- (IBAction)addVideoToFavorite:(id)sender {
	NMVideo * vdo = playbackModelController.currentVideo;
	[nowmovTaskController issueShare:![vdo.nm_favorite boolValue] video:playbackModelController.currentVideo duration:loadedControlView.duration elapsedSeconds:loadedControlView.timeElapsed];
	[self animateFavoriteButtonsToInactive];
}

- (IBAction)addVideoToQueue:(id)sender {
	NMVideo * vdo = playbackModelController.currentVideo;
	[nowmovTaskController issueEnqueue:![vdo.nm_watch_later boolValue] video:playbackModelController.currentVideo];
	[self animateWatchLaterButtonsToInactive];
}

// seek bar
- (IBAction)seekPlaybackProgress:(id)sender {
	NMSeekBar * slider = (NMSeekBar *)sender;
	CMTime theTime = CMTimeMake((int64_t)slider.currentTime, 1);
	[movieView.player seekToTime:theTime];
	[loadedControlView updateSeekBubbleLocation];
}

- (IBAction)touchDownProgressBar:(id)sender {
	[self stopVideo];
	showMovieControlTimestamp = -1;
	loadedControlView.isSeeking = YES;
	// get current control nub position
	[loadedControlView updateSeekBubbleLocation];
	// show seek bubble
	[UIView beginAnimations:nil context:nil];
	loadedControlView.seekBubbleButton.alpha = 1.0f;
	[UIView commitAnimations];
}

- (IBAction)touchUpProgressBar:(id)sender {
	[self playCurrentVideo];
	loadedControlView.isSeeking = NO;
	showMovieControlTimestamp = loadedControlView.timeElapsed;
	[UIView beginAnimations:nil context:nil];
	loadedControlView.seekBubbleButton.alpha = 0.0f;
	[UIView commitAnimations];
}

# pragma mark gestures
- (void)handleMovieViewPinched:(UIPinchGestureRecognizer *)sender {
	switch (sender.state) {
		case UIGestureRecognizerStateCancelled:
		case UIGestureRecognizerStateEnded:
			controlScrollView.scrollEnabled = YES;
			break;
			
		case UIGestureRecognizerStateChanged:
		{
			CGRect theFrame = channelController.panelView.frame;
			BOOL panelHidden = YES;
			if ( theFrame.origin.y < 768.0 ) {
				// assume the panel is visible
				panelHidden = NO;
			}
			
			if ( panelHidden ) {
				// check if it's a pinch in gesture
				if ( sender.velocity < -1.8 && sender.scale < 0.8 ) {
					NSLog(@"pinch in fired");
					[self toggleChannelPanel:sender.view];
				}
			} else {
				// check if it's a pinch out gesture
				if ( sender.velocity > 5.0 && sender.scale > 1.4 ) {
					NSLog(@"pinch out fired");
					[self toggleChannelPanel:sender.view];
				}
			}
			break;
		}
			
		default:
			break;
	}
}

#pragma mark Debug

#ifdef DEBUG_PLAYER_NAVIGATION
- (NMAVQueuePlayer *)getQueuePlayer {
	return movieView.player;
}

#endif

@end
