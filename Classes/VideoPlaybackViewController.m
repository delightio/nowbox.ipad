//
//  VideoPlaybackViewController.m
//  Nowmov
//
//  Created by Bill So on 03/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "VideoPlaybackViewController.h"
#import "SocialSignInViewController.h"
#import "NMMovieView.h"
#import "ChannelPanelController.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>

#define NM_PLAYER_STATUS_CONTEXT				100
#define NM_PLAYER_CURRENT_ITEM_CONTEXT			101
#define NM_PLAYBACK_BUFFER_EMPTY_CONTEXT		102
#define NM_PLAYBACK_LIKELY_TO_KEEP_UP_CONTEXT	103
#define NM_VIDEO_READY_FOR_DISPLAY_CONTEXT		105
#define NM_PLAYER_ITEM_STATUS_CONTEXT			106
#define NM_PLAYER_RATE_CONTEXT					107
#define NM_MAX_VIDEO_IN_QUEUE				3
#define NM_INDEX_PATH_CACHE_SIZE			4

#define NM_PLAYER_SCROLLVIEW_ANIMATION_CONTEXT	200


@interface VideoPlaybackViewController (PrivateMethods)

//- (void)insertVideoAtIndex:(NSUInteger)idx;
//- (void)queueVideoToPlayer:(NMVideo *)vid;
- (void)controlsViewTouchUp:(id)sender;
- (void)configureControlViewForVideo:(NMVideo *)aVideo;
- (void)showNextVideo:(BOOL)didPlayToEnd;
- (void)translateMovieViewByOffset:(CGFloat)offset;
- (void)playCurrentVideo;
- (void)stopVideo;
- (void)setupPlayer;

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
	[[UIApplication sharedApplication] setStatusBarHidden:NO];
//	self.wantsFullScreenLayout = YES;
	isAspectFill = YES;
	firstShowControlView = YES;
	currentXOffset = 0.0f;
	movieXOffset = 0.0f;
	
	// view background
	UIColor * bgColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"playback_background_pattern"]];
	self.view.backgroundColor = bgColor;
	
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
	}
	self.loadedMovieDetailView = nil;
	
	// === don't change the sequence in this block ===
	// create movie view
	movieView = [[NMMovieView alloc] initWithFrame:CGRectMake(movieXOffset, 20.0f, 640.0f, 360.0f)];
	[controlScrollView addSubview:movieView];
	
	// pre-load control view
	// load the nib
	[mb loadNibNamed:@"VideoControlView" owner:self options:nil];
	// hook up with target-action
	[loadedControlView addTarget:self action:@selector(controlsViewTouchUp:)];
	loadedControlView.frame = movieView.frame;
	[loadedControlView setPlaybackMode:NMHalfScreenMode animated:NO];
	
	// put the view to scroll view
	[controlScrollView addSubview:loadedControlView];
	
	// set up player
	[self setupPlayer];
	
	// ======
	
	// load channel view
	[[NSBundle mainBundle] loadNibNamed:@"ChannelPanelView" owner:self options:nil];
	theFrame = channelController.panelView.frame;
	theFrame.origin.y = self.view.bounds.size.height - theFrame.size.height;
	channelController.panelView.frame = theFrame;
	channelController.videoViewController = self;
	[self.view addSubview:channelController.panelView];
	
	defaultNotificationCenter = [NSNotificationCenter defaultCenter];
	// listen to item finish up playing notificaiton
	[defaultNotificationCenter addObserver:self selector:@selector(handleDidPlayItemNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
	// listen to system notification
	[defaultNotificationCenter addObserver:self selector:@selector(handleApplicationDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
	
	// setup gesture recognizer
//	UIPinchGestureRecognizer * pinRcr = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleMovieViewPinched:)];
//	[controlScrollView addGestureRecognizer:pinRcr];
//	[pinRcr release];
	// set target-action methods
	[movieView addTarget:self action:@selector(movieViewTouchUp:)];
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
	[super dealloc];
}

#pragma mark Playback data structure

- (void)setPlaybackCheckpoint {
	NMVideo * theVideo = [self playerCurrentVideo];
	CMTime aTime = movieView.player.currentTime;
	if ( aTime.flags & kCMTimeFlags_Valid ) {
		currentChannel.nm_time_elapsed_value = [NSNumber numberWithLongLong:aTime.value];
		currentChannel.nm_time_elapsed_timescale = [NSNumber numberWithInteger:aTime.timescale];
	}
	// send event back to nowmov server
	currentChannel.nm_last_vid = theVideo.nm_id;
	// send event back to nowmov server
	[nowmovTaskController issueSendViewingEventForVideo:playbackModelController.currentVideo duration:loadedControlView.duration elapsedSeconds:loadedControlView.timeElapsed];
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
	currentXOffset = 0.0f;
	firstShowControlView = YES;
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
	[movieView setActivityIndicationHidden:NO animated:NO];
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

#pragma mark Movie View Management
- (void)setupPlayer {
	NMAVQueuePlayer * player = [[NMAVQueuePlayer alloc] init];
	player.playbackDelegate = self;
	// actionAtItemEnd MUST be set to AVPlayerActionAtItemEndPause. When the player plays to the end of the video, the controller needs to remove the AVPlayerItem from oberver list. We do this in the notification handler
	player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
	movieView.player = player;
	// observe status change in player
	[player addObserver:self forKeyPath:@"status" options:0 context:(void *)NM_PLAYER_STATUS_CONTEXT];
	[player addObserver:self forKeyPath:@"currentItem" options:0 context:(void *)NM_PLAYER_CURRENT_ITEM_CONTEXT];
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
		if ( videoDurationInvalid ) {
			t = movieView.player.currentItem.asset.duration;
			if ( t.flags & kCMTimeFlags_Valid ) {
#ifdef DEBUG_PLAYBACK_QUEUE
				NSLog(@"invalid time, get duration again: %lld", t.value / t.timescale);
#endif
				NSInteger d = t.value / t.timescale;
				loadedControlView.duration = d;
				// duration of video should never be 0. Do NOT set the flag to YES if duration == 0.
				if ( d ) videoDurationInvalid = NO;
			}
		}
		loadedControlView.timeElapsed = sec;
		if ( firstShowControlView && (sec + 1) % 3 == 0) {
			firstShowControlView = NO;
			if ( !loadedControlView.hidden && loadedControlView.alpha > 0.0 ) {
				// hide the control
				[self controlsViewTouchUp:loadedControlView];
			}
		}
	}];
	// retain the time observer
	[timeObserver retain];
}

- (void)translateMovieViewByOffset:(CGFloat)offset {
	CGPoint pos = movieView.center;
	pos.x += movieView.bounds.size.width * offset;
	movieView.center = pos;
//	CGRect theFrame = movieView.frame;
//	theFrame.origin.x += theFrame.size.width * offset;
//	movieView.frame = theFrame;
}

#pragma mark Control Views Management
- (void)configureControlViewForVideo:(NMVideo *)aVideo {
	[loadedControlView resetView];
	loadedControlView.title = aVideo.title;
	loadedControlView.channel = aVideo.channel.title;
	// update the position
	CGRect theFrame = loadedControlView.frame;
	theFrame.origin.x = controlScrollView.contentOffset.x + movieXOffset;
	loadedControlView.frame = theFrame;
	// update the movie view too
	theFrame = movieView.frame;
	theFrame.origin.x = controlScrollView.contentOffset.x + movieXOffset;
	movieView.frame = theFrame;
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
	[UIView animateWithDuration:0.25f animations:^(void) {
		movieView.alpha = 0.0f;
	} completion:^(BOOL finished) {
		currentXOffset += 1024.0f;
		firstShowControlView = YES;
		// scroll to next video
		// translate the movie view
		controlScrollView.contentOffset = CGPointMake(currentXOffset, 0.0f);
		if ( [playbackModelController moveToNextVideo] ) {
			[movieView.player advanceToVideo:playbackModelController.currentVideo];
		}
		controlScrollView.scrollEnabled = YES;
	}];
	// when traisition is done. move shift the scroll view and reveals the video player again
	// this method does not handle the layout (position) of the movie control. that should be handled in scroll view delegate method
}

- (void)playVideo:(NMVideo *)aVideo {
	// stop video
	[self stopVideo];
	// flush the video player
	[movieView.player removeAllItems];
	// show progress indicator
	//[movieView setActivityIndicationHidden:NO animated:NO];

	// play the specified video
	[playbackModelController setVideo:aVideo];
}

#pragma mark VideoPlaybackModelController delegate methods
//- (void)controller:(VideoPlaybackModelController *)ctrl shouldBeginPlayingVideo:(NMVideo *)vid {
////	if ( movieView.player == nil ) {
////		// create player
////		[self preparePlayerForVideo:vid];
////	}
//}

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
	NSLog(@"offset of next MDV: %f", xOffset);
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
	NSLog(@"offset of previous MDV: %f", xOffset);
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
	NSLog(@"offset of current MDV: %f actual: %f %@", xOffset, theDetailView.frame.origin.x, ctrl.currentVideo.title);
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
	controlScrollView.contentSize = CGSizeMake((CGFloat)(1024 * totalNum), 768.0f);
	currentXOffset = (CGFloat)(playbackModelController.currentIndexPath.row * 1024);
	CGPoint thePoint = CGPointMake(currentXOffset, 0.0f);
	controlScrollView.contentOffset = thePoint;
	[self configureControlViewForVideo:playbackModelController.currentVideo];
}


#pragma mark NMVideoListUpdateDelegate methods
- (BOOL)task:(NMRefreshChannelVideoListTask *)vidListTask shouldBeginPlaybackSafeUpdateForChannel:(NMChannel *)chnl {
	return chnl == currentChannel;
}

- (NMVideo *)currentVideoForTask:(NMRefreshChannelVideoListTask *)vidListTask {
	return [self playerCurrentVideo];
}

- (void)taskBeginPlaybackSafeUpdate:(NMRefreshChannelVideoListTask *)vidListTask {
	controlScrollView.scrollEnabled = NO;
	// cancel Direct Resolution Task and Get Vdieo list task that may have been triggered when the user is waiting for videos
	BOOL firstPass = YES;
	for (AVPlayerItem * pItem in movieView.player.items ) {
		if ( firstPass ) {
			firstPass = NO;
		} else {
			[movieView.player removeItem:pItem];
		}
	}
}

- (void)taskEndPlaybackSafeUpate:(NMRefreshChannelVideoListTask *)vidListTask {
	controlScrollView.scrollEnabled = YES;
}

#pragma mark NMAVQueuePlayerPlaybackDelegate methods

- (void)player:(NMAVQueuePlayer *)aPlayer observePlayerItem:(AVPlayerItem *)anItem {
#ifdef DEBUG_PLAYBACK_QUEUE
	NMAVPlayerItem * theItem = (NMAVPlayerItem *)anItem;
	NSLog(@"KVO observing: %@", theItem.nmVideo.title);
#endif
	// observe property of the current item
	[anItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:0 context:(void *)NM_PLAYBACK_LIKELY_TO_KEEP_UP_CONTEXT];
	[anItem addObserver:self forKeyPath:@"status" options:0 context:(void *)NM_PLAYER_ITEM_STATUS_CONTEXT];
}

- (void)player:(NMAVQueuePlayer *)aPlayer stopObservingPlayerItem:(AVPlayerItem *)anItem {
#ifdef DEBUG_PLAYBACK_QUEUE
	NMAVPlayerItem * theItem = (NMAVPlayerItem *)anItem;
	NSLog(@"KVO stop observing: %@", theItem.nmVideo.title);
#endif
	((NMAVPlayerItem *)anItem).nmVideo.nm_playback_status = NMVideoQueueStatusPlayed;
	[anItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
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
	[nowmovTaskController issueSendViewingEventForVideo:item.nmVideo duration:loadedControlView.duration elapsedSeconds:loadedControlView.timeElapsed];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	NSInteger c = (NSInteger)context;
	CMTime t;
	if ( c == NM_PLAYER_STATUS_CONTEXT ) {
		switch (movieView.player.status) {
			case AVPlayerStatusReadyToPlay:
			{
				// the instance is ready to play. show time and progress view
				[loadedControlView setControlsHidden:NO animated:YES];
				t = movieView.player.currentItem.asset.duration;
				// check if the time is value
				if ( t.flags & kCMTimeFlags_Valid ) {
					loadedControlView.duration = t.value / t.timescale;
					videoDurationInvalid = NO;
				} else {
					videoDurationInvalid = YES;
				}
				[movieView setActivityIndicationHidden:YES animated:YES];
				break;
			}
			default:
				firstShowControlView = NO;
				break;
		}
	} else if ( c == NM_PLAYER_CURRENT_ITEM_CONTEXT ) {
		// update video status
		NMAVPlayerItem * curItem = (NMAVPlayerItem *)movieView.player.currentItem;
		curItem.nmVideo.nm_playback_status = NMVideoQueueStatusPlaying;
		NSLog(@"playing: %@", curItem.nmVideo.title);
		// never change currentIndex here!!
		// ====== update interface ======
		[self configureControlViewForVideo:[self playerCurrentVideo]];
		// update the time

		[UIView beginAnimations:nil context:nil];
		[loadedControlView setControlsHidden:NO animated:NO];
		
		// make the movie view visible - in the case of finish playing to the end of video, the movie view is set invisible
		if ( movieView.alpha < 1.0 ) movieView.alpha = 1.0;
		
		[UIView commitAnimations];
		firstShowControlView = YES;	// enable this so that the control will disappear later on after first count of 2 sec.
		
		t = movieView.player.currentItem.asset.duration;
		// check if the time is valid
		if ( t.flags & kCMTimeFlags_Valid ) {
			loadedControlView.duration = t.value / t.timescale;
			videoDurationInvalid = NO;
		} else {
			videoDurationInvalid = YES;
		}
		if ( didPlayToEnd ) {
			controlScrollView.scrollEnabled = YES;
			didPlayToEnd = NO;
		}
		[defaultNotificationCenter postNotificationName:NMWillBeginPlayingVideoNotification object:self userInfo:[NSDictionary dictionaryWithObject:playbackModelController.currentVideo forKey:@"video"]];
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
//		NSLog(@"playback rate: %f", movieView.player.rate);
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
- (void)setCurrentTime:(NSInteger)sec {
	currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", sec / 60, sec % 60];
	if ( videoDurationInvalid ) {
		CMTime t = movieView.player.currentItem.asset.duration;
		if ( t.flags & kCMTimeFlags_Valid ) {
			NSInteger sec = t.value / t.timescale;
			totalDurationLabel.text = [NSString stringWithFormat:@"%02d:%02d", sec / 60, sec % 60];
			videoDurationInvalid = NO;
		}
	}
}

//- (void)updateControlsForVideoAtIndex:(NSUInteger)idx {
//	NMVideo * vid = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
////	channelNameLabel.text = [currentChannel.title capitalizedString];
////	videoTitleLabel.text = [vid.title uppercaseString];
//	CMTime t = movieView.player.currentItem.asset.duration;
//	// check if the time is value
//	if ( t.flags & kCMTimeFlags_Valid ) {
//		NSInteger sec = t.value / t.timescale;
//		totalDurationLabel.text = [NSString stringWithFormat:@"%02d:%02d", sec / 60, sec % 60];
//	} else {
//		videoDurationInvalid = YES;
//	}
//}
//
#pragma mark Popover delegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	[self playCurrentVideo];
}

#pragma mark Scroll View Delegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	NMVideoPlaybackViewIsScrolling = YES;
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
	scrollView.scrollEnabled = YES;
	if ( scrollView.contentOffset.x > currentXOffset ) {
		currentXOffset += 1024.0f;
		if ( [playbackModelController moveToNextVideo] ) {
			[movieView.player advanceToVideo:playbackModelController.currentVideo];
		}
#ifdef DEBUG_PLAYER_NAVIGATION
		else
			NSLog(@"can't move to next video. no video!!");
#endif
	} else if ( scrollView.contentOffset.x < currentXOffset ) {
		currentXOffset -= 1024.0f;
		if ( playbackModelController.previousVideo ) {
			[playbackModelController moveToPreviousVideo];
			[movieView.player revertToVideo:playbackModelController.currentVideo];
		}
	} else {
		// play the video again
		[self playCurrentVideo];
		// this method pairs with "stopVideo" in scrollViewDidEndDragging
		// prefer to stop video when user has lifted their thumb. This usually means scrolling is likely to continue. I.e. the prev/next page will be shown. If the video keeps playing when we are showing the next screen, it will be weird. (background sound still playing)
	}
	NMVideoPlaybackViewIsScrolling = NO;
}


#pragma mark Target-action methods

//- (IBAction)showTweetView:(id)sender {
//	if ( infoPanelImageView == nil ) {
//		UIButton * btn = (UIButton *)sender;
//		UIImage * img = [UIImage imageNamed:@"info_panel"];
//		CGRect theFrame;
//		theFrame.size = img.size;
//		theFrame.origin.y = 768.0 - img.size.height - 96.0 + 35.0;
//		theFrame.origin.x = floorf(btn.frame.origin.x - ( img.size.width - btn.frame.size.width ) / 2.0);
//		infoPanelImageView = [[UIImageView alloc] initWithImage:img];
//		infoPanelImageView.frame = theFrame;
//		[controlsContainerView addSubview:infoPanelImageView];
//	} else {
//		[infoPanelImageView removeFromSuperview];
//		[infoPanelImageView release];
//		infoPanelImageView = nil;
//	}
//}
//
//- (IBAction)showVolumeControlView:(id)sender {
//	if ( volumePanelImageView == nil ) {
//		UIButton * btn = (UIButton *)sender;
//		UIImage * img = [UIImage imageNamed:@"volume_panel"];
//		CGRect theFrame;
//		theFrame.size = img.size;
//		theFrame.origin.y = 768.0 - img.size.height - 96.0 + 35.0;
//		theFrame.origin.x = floorf(btn.frame.origin.x - ( img.size.width - btn.frame.size.width ) / 2.0);
//		volumePanelImageView = [[UIImageView alloc] initWithImage:img];
//		volumePanelImageView.frame = theFrame;
//		[controlsContainerView addSubview:volumePanelImageView];
//	} else {
//		[volumePanelImageView removeFromSuperview];
//		[volumePanelImageView release];
//		volumePanelImageView = nil;
//	}
//}
//
//- (IBAction)showShareActionView:(id)sender {
//	if ( shareVideoPanelImageView == nil ) {
//		UIImage * img = [UIImage imageNamed:@"twitter_share_popup"];
//		CGRect theFrame;
//		theFrame.size = img.size;
//		theFrame.origin.x = floorf( (1024.0 - img.size.width) / 2.0 );
//		theFrame.origin.y = floorf( ( 768.0 - img.size.height ) / 2.0 );
//		shareVideoPanelImageView = [[UIImageView alloc] initWithImage:img];
//		shareVideoPanelImageView.frame = theFrame;
//		[controlsContainerView addSubview:shareVideoPanelImageView];
//	} else {
//		[shareVideoPanelImageView removeFromSuperview];
//		[shareVideoPanelImageView release];
//		shareVideoPanelImageView = nil;
//	}
//}
//

- (void)handleMovieViewPinched:(id)sender {
	UIPinchGestureRecognizer * rcr = (UIPinchGestureRecognizer *)sender;
	if ( rcr.velocity < -2.0 && rcr.scale < 0.6 && channelController.panelView.center.y > 768.0f ) {
		// quit this view
//		[self backToChannelView:sender];
		[self toggleChannelPanel:sender];
	} else if ( rcr.velocity < 1.0 && rcr.scale > 0.35 && channelController.panelView.center.y < 768.0f ) {
		[self toggleChannelPanel:sender];
	}
	//	CGRect theFrame;
	//	CGSize theSize;
	//	if ( rcr.velocity > 0 && rcr.scale > 1.2 && isAspectFill ) {
	//		// scale the player layer down
	//		isAspectFill = NO;
	//		theFrame = movieView.bounds;
	//		// calculate the size
	//		theSize = movieView.player.currentItem.presentationSize;
	//		theSize.width = floorf(768.0 / theSize.height * theSize.width);
	//		theSize.height = 768.0;
	//		theFrame.size = theSize;
	//		movieView.bounds = theFrame;
	//	} else if ( rcr.velocity < 0 && rcr.scale < 0.8 && !isAspectFill ) {
	//		isAspectFill = YES;
	//		// restore the original size
	//		theFrame = self.view.bounds;
	//		movieView.bounds = theFrame;
	//	}
}

- (IBAction)vote:(id)sender {
	UIView * v = (UIView *)sender;
	if ( v.tag == 1017 ) {
		// vote up
		[nowmovTaskController issueSendUpVoteEventForVideo:[self playerCurrentVideo] duration:loadedControlView.duration elapsedSeconds:loadedControlView.timeElapsed];
	} else {
		// vote down
		[nowmovTaskController issueSendDownVoteEventForVideo:[self playerCurrentVideo] duration:loadedControlView.duration elapsedSeconds:loadedControlView.timeElapsed];
	}
}

- (IBAction)skipCurrentVideo:(id)sender {
	UIView * btn = (UIView *)sender;
	if ( btn.tag == 1000 ) {
		// prev
	} else {
		if ( playbackModelController.nextVideo == nil ) {
			// already playing the last video in the channel
			[loadedControlView showLastVideoMessage];
		} else {
			// next
			[self showNextVideo:NO];
		}
		// buffer the next next video
		//		[self requestAddVideoAtIndex:currentIndex + 2];
		//		if ( currentIndex < numberOfVideos ) {
		//			currentIndex++;
		//		}
		//		[movieView.player advanceToNextItem];
	}
}

- (IBAction)showSharePopover:(id)sender {
	
	UIButton * btn = (UIButton *)sender;
	
	SocialSignInViewController * socialCtrl = [[SocialSignInViewController alloc] initWithNibName:@"SocialSignInView" bundle:nil];
	socialCtrl.videoViewController = self;
	
	UINavigationController * navCtrl = [[UINavigationController alloc] initWithRootViewController:socialCtrl];
	
	UIPopoverController * popCtrl = [[UIPopoverController alloc] initWithContentViewController:navCtrl];
	popCtrl.popoverContentSize = CGSizeMake(320.0f, 178.0f);
	popCtrl.delegate = self;
	
	[popCtrl presentPopoverFromRect:btn.frame inView:btn.superview permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	
	[socialCtrl release];
	[navCtrl release];
}

- (IBAction)toggleChannelPanel:(id)sender {
	CGRect theFrame;
	theFrame = channelController.panelView.frame;
	BOOL panelHidden = YES;
	if ( theFrame.origin.y < 768.0 ) {
		// assume the panel is visible
		panelHidden = NO;
	}

	CGRect viewRect;
	// make the movie detail view visible
	NMMovieDetailView * theDetailView;
	theDetailView = playbackModelController.currentVideo.nm_movie_detail_view;
	theDetailView.hidden = NO;
	theDetailView.alpha = 0.0f;
	viewRect = theDetailView.frame;
	viewRect.origin = controlScrollView.contentOffset;
	theDetailView.frame = viewRect;
	
	if ( playbackModelController.previousVideo ) {
		theDetailView = playbackModelController.previousVideo.nm_movie_detail_view;
		theDetailView.hidden = NO;
		theDetailView.alpha = 1.0f;
		viewRect = theDetailView.frame;
		viewRect.origin = controlScrollView.contentOffset;
		viewRect.origin.x -= 1024.0f;
		theDetailView.frame = viewRect;
	}
	
	if ( playbackModelController.nextVideo ) {
		theDetailView = playbackModelController.nextVideo.nm_movie_detail_view;
		theDetailView.hidden = NO;
		theDetailView.alpha = 1.0f;
		viewRect = theDetailView.frame;
		viewRect.origin = controlScrollView.contentOffset;
		viewRect.origin.x += 1024.0f;
		theDetailView.frame = viewRect;
	}
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationBeginsFromCurrentState:YES];
	if ( panelHidden ) {
		// slide in the channel view with animation
		movieXOffset = 0.0f;
		//MARK: not sure if we still need to show/hide status bar
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
		viewRect = CGRectMake(movieView.frame.origin.x + movieXOffset, 20.0f, 640.0f, 360.0f);
		movieView.frame = viewRect;
		[loadedControlView setPlaybackMode:NMHalfScreenMode animated:NO];
		// slide in
		theFrame.origin.y = self.view.bounds.size.height - channelController.panelView.frame.size.height;
		channelController.panelView.frame = theFrame;
		[channelController panelWillEnterHalfScreen:NMFullScreenPlaybackMode];
		
//		playbackModelController.currentVideo.nm_movie_detail_view.alpha = 1.0f;
	} else {
		// slide out the channel view
		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
		viewRect = CGRectMake(movieView.frame.origin.x - movieXOffset, 0.0f, 1024.0f, 768.0f);
		movieView.frame = viewRect;
		[loadedControlView setPlaybackMode:NMFullScreenPlaybackMode animated:NO];
//		loadedControlView.frame = viewRect;
		// reset offset value
		movieXOffset = 0.0f;
		// slide out
		theFrame.origin.y = 768.0;
		channelController.panelView.frame = theFrame;
		[channelController panelWillDisappear];
		
		// scale up
//		movieView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
//		controlScrollView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
	}
	[UIView commitAnimations];
	if ( panelHidden ) {
		for (theDetailView in movieDetailViewArray) {
			theDetailView.hidden = NO;
			theDetailView.alpha = 1.0f;
		}
	} else {
		for (theDetailView in movieDetailViewArray) {
			theDetailView.hidden = YES;
		}
	}
	// slide in/out the prototype channel panel
	// scale down movie control
	// scale playback view
	// slide in/out channel panel
}

- (IBAction)inspectViewStructure:(id)sender {
	// check if the detail view is showing
	NMMovieDetailView * theDetailView;
	for (theDetailView in movieDetailViewArray) {
		NSLog(@"hidden %d alpha %f super %@	frame %f %f %f %f", theDetailView.hidden, theDetailView.alpha, theDetailView.superview, theDetailView.frame.origin.x, theDetailView.frame.origin.y, theDetailView.frame.size.width, theDetailView.frame.size.height);
	}
}

- (IBAction)refreshVideoList:(id)sender {
	[nowmovTaskController issueRefreshVideoListForChannel:currentChannel delegate:self];
}

- (void)movieViewTouchUp:(id)sender {
	// show the control view
	[UIView beginAnimations:nil context:nil];
	loadedControlView.alpha = 1.0;
	[UIView commitAnimations];
}

- (void)controlsViewTouchUp:(id)sender {
	UIView * v = (UIView *)sender;
	// hide the control view
	[UIView beginAnimations:nil context:nil];
	v.alpha = 0.0;
	[UIView commitAnimations];
}

@end
