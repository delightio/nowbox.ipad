//
//  LaunchController.m
//  ipad
//
//  Created by Bill So on 27/9/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "LaunchController.h"
#import "VideoPlaybackViewController.h"
#import "NMLibrary.h"
#import "ipadAppDelegate.h"

#define GP_CHANNEL_UPDATE_INTERVAL	-12.0 * 3600.0
#ifdef DEBUG_ONBOARD_PROCESS
#define NM_ALWAYS_SHOW_ONBOARD_PROCESS	YES
#else
#define NM_ALWAYS_SHOW_ONBOARD_PROCESS	NO
#endif

@implementation LaunchController
@synthesize view;
@synthesize viewController;
@synthesize channel;

- (void)dealloc {
	[view release];
	[channel release];
	[thumbnailVideoIndex release];
	[resolutionVideoIndex release];
	[super dealloc];
}

- (void)loadView {
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"playback_background_pattern"]];
	[progressLabel setBackgroundImage:[[UIImage imageNamed:@"onboard-right-label-background"] stretchableImageWithLeftCapWidth:6 topCapHeight:0] forState:UIControlStateNormal];
	
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleDidGetChannelNotification:) name:NMDidGetChannelsNotification object:nil];
	
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NM_USER_ACCOUNT_ID = [userDefaults integerForKey:NM_USER_ACCOUNT_ID_KEY];
	NM_USER_WATCH_LATER_CHANNEL_ID = [userDefaults integerForKey:NM_USER_WATCH_LATER_CHANNEL_ID_KEY];
	NM_USER_FAVORITES_CHANNEL_ID = [userDefaults integerForKey:NM_USER_FAVORITES_CHANNEL_ID_KEY];
	NM_USER_HISTORY_CHANNEL_ID = [userDefaults integerForKey:NM_USER_HISTORY_CHANNEL_ID_KEY];
	NM_USE_HIGH_QUALITY_VIDEO = [userDefaults boolForKey:NM_USE_HIGH_QUALITY_VIDEO_KEY];
	NM_USER_SHOW_FAVORITE_CHANNEL = [userDefaults boolForKey:NM_SHOW_FAVORITE_CHANNEL_KEY];
	appFirstLaunch = [userDefaults boolForKey:NM_FIRST_LAUNCH_KEY];
	
	if ( NM_ALWAYS_SHOW_ONBOARD_PROCESS || appFirstLaunch ) {
		[progressLabel setTitle:@"Creating user..." forState:UIControlStateNormal];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidCreateUserNotification:) name:NMDidCreateUserNotification object:nil];
		// create new user
		[[NMTaskQueueController sharedTaskQueueController] issueCreateUser];
		viewController.launchModeActive = YES;
	} else {
		[self checkUpdateChannels];
	}
}

- (void)showVideoViewAnimated {
//	viewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
//	[self presentModalViewController:viewController animated:YES];
	[viewController showPlaybackViewWithTransitionStyle:kCATransitionFade];
	// continue channel of the last session
	// If last session is not available, data controller will return the first channel user subscribed. VideoPlaybackModelController will decide to load video of the last session of the selected channel
	viewController.currentChannel = [[NMTaskQueueController sharedTaskQueueController].dataController lastSessionChannel];
	
	// set first launch to NO
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:NM_FIRST_LAUNCH_KEY];
}

- (void)slideInVideoViewAnimated {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[viewController showPlaybackViewWithTransitionStyle:kCATransitionFromRight];
	// continue channel of the last session
	// If last session is not available, data controller will return the first channel user subscribed. VideoPlaybackModelController will decide to load video of the last session of the selected channel
//	viewController.currentChannel = [[NMTaskQueueController sharedTaskQueueController].dataController lastSessionChannel];
	
	// set first launch to NO
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:NM_FIRST_LAUNCH_KEY];
}

- (void)checkUpdateChannels {
	NSUserDefaults * df = [NSUserDefaults standardUserDefaults];
	
	NSDate * lastDate = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:NM_CHANNEL_LAST_UPDATE];
	if ( NM_ALWAYS_SHOW_ONBOARD_PROCESS || appFirstLaunch || 
		[lastDate timeIntervalSinceNow] < GP_CHANNEL_UPDATE_INTERVAL // 12 hours
		) { 
		// get channel
		[[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
		[progressLabel setTitle:@"Loading videos..." forState:UIControlStateNormal];
	} else {
		[self performSelector:@selector(showVideoViewAnimated) withObject:nil afterDelay:0.5];
		NSInteger sid = [df integerForKey:NM_SESSION_ID_KEY] + 1;
		[[NMTaskQueueController sharedTaskQueueController] beginNewSession:sid];
		[df setInteger:sid forKey:NM_SESSION_ID_KEY];
	}
}

#pragma mark Notification
- (void)handleDidCreateUserNotification:(NSNotification *)aNotification {
	NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
	[defs setInteger:NM_USER_ACCOUNT_ID forKey:NM_USER_ACCOUNT_ID_KEY];
	[defs setInteger:NM_USER_WATCH_LATER_CHANNEL_ID forKey:NM_USER_WATCH_LATER_CHANNEL_ID_KEY];
	[defs setInteger:NM_USER_FAVORITES_CHANNEL_ID forKey:NM_USER_FAVORITES_CHANNEL_ID_KEY];
	[defs setInteger:NM_USER_HISTORY_CHANNEL_ID forKey:NM_USER_HISTORY_CHANNEL_ID_KEY];
	NSLog(@"Created new user: %d", NM_USER_ACCOUNT_ID);
	// new user created, get channel
	[self checkUpdateChannels];
}

- (void)handleDidGetChannelNotification:(NSNotification *)aNotification {
	NMDataController * dataCtrl = [NMTaskQueueController sharedTaskQueueController].dataController;
	// begin new session
	NSUserDefaults * df = [NSUserDefaults standardUserDefaults];
	NSInteger sid = [df integerForKey:NM_SESSION_ID_KEY] + 1;
	[[NMTaskQueueController sharedTaskQueueController] beginNewSession:sid];
	[df setInteger:sid forKey:NM_SESSION_ID_KEY];
	// set the user channels to hide
	NSNumber * yesNum = [NSNumber numberWithBool:YES];
	dataCtrl.myQueueChannel.nm_hidden = yesNum;
	dataCtrl.favoriteVideoChannel.nm_hidden = yesNum;
	if ( NM_ALWAYS_SHOW_ONBOARD_PROCESS || appFirstLaunch ) {
		NSNotificationCenter * dn = [NSNotificationCenter defaultCenter];
//		[dn addObserver:self selector:@selector(handleGetVideosNotification:) name:NMDidGetChannelVideoListNotification object:nil];
//		[dn addObserver:self selector:@selector(handleGetVideosNotification:) name:NMDidFailGetChannelVideoListNotification object:nil];
		[dn addObserver:self selector:@selector(handleVideoThumbnailReadyNotification:) name:NMDidDownloadImageNotification object:nil];
		[dn addObserver:self selector:@selector(handleDidResolveURLNotification:) name:NMDidGetYouTubeDirectURLNotification object:nil];
		thumbnailVideoIndex = [[NSMutableIndexSet alloc] init];
		resolutionVideoIndex = [[NSMutableIndexSet alloc] init];
		// assign the channel to playback view controller
		self.channel = [[NMTaskQueueController sharedTaskQueueController].dataController lastSessionChannel];
		[viewController setCurrentChannel:channel startPlaying:NO];
		// wait for notification of video list
	} else {
		[progressLabel setTitle:@"Ready to go..." forState:UIControlStateNormal];
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:NM_CHANNEL_LAST_UPDATE];
		[self performSelector:@selector(showVideoViewAnimated) withObject:nil afterDelay:1.0f];
	}
}

//- (void)handleGetVideosNotification:(NSNotification *)aNotification {
//	if ( [[aNotification name] isEqualToString:NMDidGetChannelVideoListNotification] ) {
//		// download video thumbnail
//		NSDictionary * info = [aNotification userInfo];
//		NMChannel * chnObj = [info objectForKey:@"channel"];
//		if ( [chnObj isEqual:channel] && [[info objectForKey:@"num_video_received"] integerValue]) {
//			// assign the channel to the playback view controller
//			[viewController setCurrentChannel:chnObj startPlaying:NO];
//		}
//	}
//}

- (void)handleDidResolveURLNotification:(NSNotification *)aNotification {
	NMVideo * vdo = [[aNotification userInfo] objectForKey:@"target_object"];
	[resolutionVideoIndex addIndex:[vdo.nm_id unsignedIntegerValue]];
	NSUInteger cIdx = [viewController.currentVideo.nm_id unsignedIntegerValue];
	if ( [resolutionVideoIndex containsIndex:cIdx] ) {
		// contains the direct URL, check if it contains the thumbnail as well
		if ( [thumbnailVideoIndex containsIndex:cIdx] ) {
			// ready to show the launch view
			[NSObject cancelPreviousPerformRequestsWithTarget:self];
			[self performSelector:@selector(slideInVideoViewAnimated) withObject:nil afterDelay:1.75f];
		}
	}
}

- (void)handleVideoThumbnailReadyNotification:(NSNotification *)aNotification {
	NMTask * theTask = (NMTask *)[aNotification object];
	if ( theTask.command == NMCommandGetVideoThumbnail ) {
		NMVideo * targetVdo = [[aNotification userInfo] objectForKey:@"target_object"];
		// store all indexes. the order of downloading video thumbnail is not guaranteed. need to check against all indexes downloaded. 
		[thumbnailVideoIndex addIndex:[targetVdo.nm_id unsignedIntegerValue]];
		NSUInteger cIdx = [viewController.currentVideo.nm_id unsignedIntegerValue];
		if ( [thumbnailVideoIndex containsIndex:cIdx] ) {
			if ( [resolutionVideoIndex containsIndex:cIdx] ) {
				// ready to show launch view
				[NSObject cancelPreviousPerformRequestsWithTarget:self];
				[self performSelector:@selector(slideInVideoViewAnimated) withObject:nil afterDelay:1.75f];
			}
		}
	}
}

@end
