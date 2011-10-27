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

#define GP_CHANNEL_UPDATE_INTERVAL	-600.0f //-12.0 * 3600.0
#ifdef DEBUG_ONBOARD_PROCESS
#define NM_ALWAYS_SHOW_ONBOARD_PROCESS	YES
#else
#define NM_ALWAYS_SHOW_ONBOARD_PROCESS	NO
#endif

@implementation LaunchController
@synthesize view;
@synthesize viewController;
@synthesize lastFailNotificationName;
@synthesize channel;

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[view release];
	[channel release];
	[thumbnailVideoIndex release];
	[resolutionVideoIndex release];
	[lastFailNotificationName release];
	[super dealloc];
}

- (void)loadView {
	// background pattern of the whole launch view
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"playback_background_pattern"]];
	UIImage * lblBgImg = [UIImage imageNamed:@"launch-status-background"];
	[progressLabel setBackgroundImage:[lblBgImg stretchableImageWithLeftCapWidth:16 topCapHeight:0] forState:UIControlStateNormal];
	
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleDidGetChannelNotification:) name:NMDidGetChannelsNotification object:nil];
	
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NM_USER_ACCOUNT_ID = [userDefaults integerForKey:NM_USER_ACCOUNT_ID_KEY];
	NM_USER_WATCH_LATER_CHANNEL_ID = [userDefaults integerForKey:NM_USER_WATCH_LATER_CHANNEL_ID_KEY];
	NM_USER_FAVORITES_CHANNEL_ID = [userDefaults integerForKey:NM_USER_FAVORITES_CHANNEL_ID_KEY];
	NM_USER_HISTORY_CHANNEL_ID = [userDefaults integerForKey:NM_USER_HISTORY_CHANNEL_ID_KEY];
	NM_USER_TWITTER_CHANNEL_ID = [userDefaults integerForKey:NM_USER_TWITTER_CHANNEL_ID_KEY];
	NM_USER_FACEBOOK_CHANNEL_ID = [userDefaults integerForKey:NM_USER_FACEBOOK_CHANNEL_ID_KEY];
	NM_USE_HIGH_QUALITY_VIDEO = [userDefaults boolForKey:NM_USE_HIGH_QUALITY_VIDEO_KEY];
	NM_YOUTUBE_MOBILE_BROWSER_RESOLUTION = [userDefaults boolForKey:NM_YOUTUBE_MOBILE_BROWSER_RESOLUTION_KEY];
	NM_USER_SHOW_FAVORITE_CHANNEL = [userDefaults boolForKey:NM_SHOW_FAVORITE_CHANNEL_KEY];
	appFirstLaunch = [userDefaults boolForKey:NM_FIRST_LAUNCH_KEY];
	
	if ( NM_ALWAYS_SHOW_ONBOARD_PROCESS || appFirstLaunch ) {
		progressLabel.hidden = NO;
		[progressLabel setTitle:@"Creating user..." forState:UIControlStateNormal];
		NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(handleDidCreateUserNotification:) name:NMDidCreateUserNotification object:nil];
		[nc addObserver:self selector:@selector(handleLaunchFailNotification:) name:NMDidFailCreateUserNotification object:nil];
		[nc addObserver:self selector:@selector(handleLaunchFailNotification:) name:NMDidFailGetChannelsNotification object:nil];
		[nc addObserver:self selector:@selector(handleLaunchFailNotification:) name:NMDidFailGetChannelVideoListNotification object:nil];
		[nc addObserver:self selector:@selector(handleLaunchFailNotification:) name:NMDidFailDownloadImageNotification object:nil];
		// create new user
		[[NMTaskQueueController sharedTaskQueueController] issueCreateUser];
		viewController.launchModeActive = YES;
	} else {
		[self checkUpdateChannels];
	}
}

- (void)showVideoViewAnimated {
	[viewController showPlaybackView];
	// continue channel of the last session
	// If last session is not available, data controller will return the first channel user subscribed. VideoPlaybackModelController will decide to load video of the last session of the selected channel
	viewController.currentChannel = [[NMTaskQueueController sharedTaskQueueController].dataController lastSessionChannel];
	
	// set first launch to NO
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:NM_FIRST_LAUNCH_KEY];
    [[MixpanelAPI sharedAPI] track:@"Login"];
}

- (void)slideInVideoViewAnimated {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[viewController showPlaybackView];
	// continue channel of the last session
	// If last session is not available, data controller will return the first channel user subscribed. VideoPlaybackModelController will decide to load video of the last session of the selected channel
//	viewController.currentChannel = [[NMTaskQueueController sharedTaskQueueController].dataController lastSessionChannel];
	
	// set first launch to NO
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:NM_FIRST_LAUNCH_KEY];
    [[MixpanelAPI sharedAPI] track:@"Login"];    
}

- (void)checkUpdateChannels {
	NSUserDefaults * df = [NSUserDefaults standardUserDefaults];
	
	NSDate * lastDate = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:NM_CHANNEL_LAST_UPDATE];
	if ( NM_ALWAYS_SHOW_ONBOARD_PROCESS || appFirstLaunch || 
		[lastDate timeIntervalSinceNow] < GP_CHANNEL_UPDATE_INTERVAL
		) { 
		progressLabel.hidden = NO;
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
	// new user created, get channel
	[self checkUpdateChannels];
}

- (void)handleLaunchFailNotification:(NSNotification *)aNotification {
	// show service is down page.
	NSString * notName = [aNotification name];
	self.lastFailNotificationName = notName;
	NSError * errObj = [[aNotification userInfo] objectForKey:@"error"];
	NSString * lblStr = nil;
	if ( [[errObj domain] isEqualToString:NSURLErrorDomain] && [errObj code] == NSURLErrorNotConnectedToInternet ) {
		lblStr = @"Please connect to Wi-Fi";
	} else {
		lblStr = @"Service is down";
	}
	if ( [notName isEqualToString:NMDidFailCreateUserNotification] ) {
		[progressLabel setTitle:lblStr forState:UIControlStateNormal];
	} else if ( [notName isEqualToString:NMDidFailGetChannelsNotification] ) {
		[progressLabel setTitle:lblStr forState:UIControlStateNormal];
	} else if ( [notName isEqualToString:NMDidFailGetChannelVideoListNotification] ) {
		[progressLabel setTitle:lblStr forState:UIControlStateNormal];
	} else if ( [notName isEqualToString:NMDidFailDownloadImageNotification] ) {
		// can't download the video thumbnail. that's not important. just make sure the launch service will continue
		ignoreThumbnailDownloadIndex = YES;
	}
	CGSize theSize = [lblStr sizeWithFont:progressLabel.titleLabel.font];
	progressLabel.bounds = CGRectMake(0.0f, 0.0f, theSize.width + 32.0f, progressLabel.bounds.size.height);
	if ( !launchProcessStuck ) {
		launchProcessStuck = YES;
		// listen to application lifecycle notification
		NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(handleApplicationNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
		[nc addObserver:self selector:@selector(handleApplicationNotification:) name:UIApplicationWillTerminateNotification object:nil];
	}
}

- (void)handleApplicationNotification:(NSNotification *)aNotification {
	NSString * notName = [aNotification name];
	if ( [notName isEqualToString:UIApplicationWillEnterForegroundNotification] ) {
		// fire the launch process again
		if ( [lastFailNotificationName isEqualToString:NMDidFailCreateUserNotification] ) {
			// begin with creating new user
			[[NMTaskQueueController sharedTaskQueueController] issueCreateUser];
			[progressLabel setTitle:@"Creating user..." forState:UIControlStateNormal];
		} else if ( [lastFailNotificationName isEqualToString:NMDidFailGetChannelsNotification] ) {
			// begin with getting channels
			[[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
			[progressLabel setTitle:@"Loading videos..." forState:UIControlStateNormal];
		} else if ( [lastFailNotificationName isEqualToString:NMDidFailGetChannelVideoListNotification] ) {
			// begin with fetching video list
			self.channel = [[NMTaskQueueController sharedTaskQueueController].dataController lastSessionChannel];
			[viewController setCurrentChannel:channel startPlaying:NO];
		}
	} else if ( [notName isEqualToString:UIApplicationWillTerminateNotification] ) {
		// clean up the database
		[[NMTaskQueueController sharedTaskQueueController].dataController resetDatabase];
		NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
		[defs setInteger:NM_USER_ACCOUNT_ID forKey:NM_USER_ACCOUNT_ID_KEY];
		[defs setInteger:NM_USER_WATCH_LATER_CHANNEL_ID forKey:NM_USER_WATCH_LATER_CHANNEL_ID_KEY];
		[defs setInteger:NM_USER_FAVORITES_CHANNEL_ID forKey:NM_USER_FAVORITES_CHANNEL_ID_KEY];
		[defs setInteger:NM_USER_HISTORY_CHANNEL_ID forKey:NM_USER_HISTORY_CHANNEL_ID_KEY];
		[defs setBool:NO forKey:NM_FIRST_LAUNCH_KEY];
	}
}

- (void)handleDidGetChannelNotification:(NSNotification *)aNotification {
//	NMDataController * dataCtrl = [NMTaskQueueController sharedTaskQueueController].dataController;
	// begin new session
	NSUserDefaults * df = [NSUserDefaults standardUserDefaults];
	NSInteger sid = [df integerForKey:NM_SESSION_ID_KEY] + 1;
	[[NMTaskQueueController sharedTaskQueueController] beginNewSession:sid];
	[df setInteger:sid forKey:NM_SESSION_ID_KEY];
	if ( NM_ALWAYS_SHOW_ONBOARD_PROCESS || appFirstLaunch ) {
		NSNotificationCenter * dn = [NSNotificationCenter defaultCenter];
		[dn addObserver:self selector:@selector(handleVideoThumbnailReadyNotification:) name:NMDidDownloadImageNotification object:nil];
		[dn addObserver:self selector:@selector(handleDidResolveURLNotification:) name:NMDidGetYouTubeDirectURLNotification object:nil];
		// listen to notification of getting videos. check if the channel is empty. if so, move to the next channel. this avoids first launch from hanging in there because the first channel has no video
		[dn addObserver:self selector:@selector(handleDidGetVideoNotification:) name:NMDidGetChannelVideoListNotification object:nil];
		thumbnailVideoIndex = [[NSMutableIndexSet alloc] init];
		resolutionVideoIndex = [[NSMutableIndexSet alloc] init];
		// assign the channel to playback view controller
		self.channel = [[NMTaskQueueController sharedTaskQueueController].dataController lastSessionChannel];
		// no need to call issueGetMoreVideoForChannel explicitly here. It will be called in VideoPlaybackModelController in the method below.
		[viewController setCurrentChannel:channel startPlaying:NO];
		// wait for notification of video list. We are not waiting for "did get video list" notification. Instead, we need to wait till the video's direct URL has been resolved. i.e. wait for "did resolved URL" notification.
	} else {
		[progressLabel setTitle:@"Ready to go..." forState:UIControlStateNormal];
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:NM_CHANNEL_LAST_UPDATE];
		[self performSelector:@selector(showVideoViewAnimated) withObject:nil afterDelay:1.0f];
	}
}

- (void)handleDidResolveURLNotification:(NSNotification *)aNotification {
	NMVideo * vdo = [[aNotification userInfo] objectForKey:@"target_object"];
	[resolutionVideoIndex addIndex:[vdo.nm_id unsignedIntegerValue]];
	NSUInteger cIdx = [viewController.currentVideo.nm_id unsignedIntegerValue];
	if ( [resolutionVideoIndex containsIndex:cIdx] ) {
		// contains the direct URL, check if it contains the thumbnail as well
		if ( [thumbnailVideoIndex containsIndex:cIdx] || ignoreThumbnailDownloadIndex ) {
			[progressLabel setTitle:@"Ready to go..." forState:UIControlStateNormal];
			// ready to show the launch view
			[NSObject cancelPreviousPerformRequestsWithTarget:self];
			[self performSelector:@selector(slideInVideoViewAnimated) withObject:nil afterDelay:1.5f];
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
				[progressLabel setTitle:@"Ready to go..." forState:UIControlStateNormal];
				// ready to show launch view
				[NSObject cancelPreviousPerformRequestsWithTarget:self];
				[self performSelector:@selector(slideInVideoViewAnimated) withObject:nil afterDelay:1.5f];
			}
		}
	}
}

- (void)handleDidGetVideoNotification:(NSNotification *)aNotification {
	NSDictionary * info = [aNotification userInfo];
	if ( [[info objectForKey:@"num_video_received"] integerValue] == 0 ) {
		self.channel = [[NMTaskQueueController sharedTaskQueueController].dataController channelNextTo:channel];
		[viewController setCurrentChannel:channel startPlaying:NO];
	}
}

@end
