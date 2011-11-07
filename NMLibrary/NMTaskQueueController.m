//
//  NMTaskQueueController.m
//  Nowmov
//
//  Created by Bill So on 05/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTaskQueueController.h"
#import "NMTaskType.h"
#import "NMNetworkController.h"
#import "NMDataController.h"
#import "NMChannel.h"
#import "NMPreviewThumbnail.h"
#import "NMVideo.h"
#import "NMVideoDetail.h"
#import "Reachability.h"

NSInteger NM_USER_ACCOUNT_ID				= 0;
NSDate * NM_USER_TOKEN_EXPIRY_DATE			= nil;
NSString * NM_USER_TOKEN					= nil;
NSInteger NM_USER_FAVORITES_CHANNEL_ID		= 0;
NSInteger NM_USER_WATCH_LATER_CHANNEL_ID	= 0;
NSInteger NM_USER_HISTORY_CHANNEL_ID		= 0;
NSInteger NM_USER_FACEBOOK_CHANNEL_ID		= 0;
NSInteger NM_USER_TWITTER_CHANNEL_ID		= 0;
BOOL NM_USER_YOUTUBE_SYNC_ACTIVE			= NO;
BOOL NM_USER_SHOW_FAVORITE_CHANNEL			= NO;
NSInteger NM_VIDEO_QUALITY					= 0;
//BOOL NM_YOUTUBE_MOBILE_BROWSER_RESOLUTION	= YES;
NSNumber * NM_SESSION_ID					= nil;
BOOL NM_WIFI_REACHABLE						= YES;

NSString * const NMBeginNewSessionNotification = @"NMBeginNewSessionNotification";
NSString * const NMShowErrorAlertNotification = @"NMShowErrorAlertNotification";

static NMTaskQueueController * sharedTaskQueueController_ = nil;
BOOL NMPlaybackSafeVideoQueueUpdateActive = NO;

@implementation NMTaskQueueController

@synthesize managedObjectContext;
@synthesize networkController;
@synthesize dataController;
@synthesize pollingTimer, tokenRenewTimer;
@synthesize unpopulatedChannels;

+ (NMTaskQueueController *)sharedTaskQueueController {
	if ( sharedTaskQueueController_ == nil ) {
		sharedTaskQueueController_ = [[NMTaskQueueController alloc] init];
	}
	return sharedTaskQueueController_;
}

- (id)init {
	self = [super init];
	
	dataController = [[NMDataController alloc] init];
	networkController = [[NMNetworkController alloc] init];
	networkController.dataController = dataController;
	
	// handle keyword channel creation
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleChannelCreationNotification:) name:NMDidCreateChannelNotification object:nil];
	[nc addObserver:self selector:@selector(handleSocialMediaLoginNotificaiton:) name:NMDidVerifyUserNotification object:nil];
//	[nc addObserver:self selector:@selector(handleSocialMediaLogoutNotification:) name:NMDidSignOutUserNotification object:nil];
	// polling server for channel update
	[nc addObserver:self selector:@selector(handleChannelPollingNotification:) name:NMDidPollChannelNotification object:nil];
	[nc addObserver:self selector:@selector(handleDidGetChannelsNotification:) name:NMDidGetChannelsNotification object:nil];
	[nc addObserver:self selector:@selector(handleFailEditUserSettingsNotification:) name:NMDidFailEditUserSettingsNotification object:nil];
	[nc addObserver:self selector:@selector(handleTokenNotification:) name:NMDidRequestTokenNotification object:nil];
	[nc addObserver:self selector:@selector(handleTokenNotification:) name:NMDidFailRequestTokenNotification object:nil];
	
	// listen to subscription as well
	[nc addObserver:self selector:@selector(handleDidSubscribeChannelNotification:) name:NMDidSubscribeChannelNotification object:nil];
	
    wifiReachability = [[Reachability reachabilityWithHostName:@"api.nowbox.com"] retain];
	[wifiReachability startNotifier];
    [nc addObserver: self selector: @selector(reachabilityChanged:) name:kReachabilityChangedNotification object: nil];

	return self;
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)moc {
	if ( managedObjectContext ) {
		if ( managedObjectContext == moc ) {
			return;
		}
		[managedObjectContext release];
		managedObjectContext = nil;
		dataController.managedObjectContext = nil;
	}
	if ( moc ) {
		managedObjectContext = [moc retain];
		dataController.managedObjectContext = moc;
	}
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[managedObjectContext release];
	[dataController release];
	[networkController release];
	[NM_SESSION_ID release];
	[pollingTimer release];
	[wifiReachability stopNotifier];
	[wifiReachability release];
	[super dealloc];
}

- (void)cancelAllPlaybackTasksForChannel:(NMChannel *)chnObj {
	// cancel all playback related tasks created for the chnObj.
	[networkController cancelPlaybackRelatedTasksForChannel:chnObj];
	// make sure NO notification will be sent after execution of this method. tasks do not have to be wiped out here. But they must not trigger and sending of notification if those tasks belong to the chnObj
}

#pragma mark Session management
- (void)beginNewSession:(NSInteger)sid {
	sessionID = sid;
	NM_SESSION_ID = [[NSNumber alloc] initWithInteger:sid];
	// delete expired videos
#ifdef DEBUG_SESSION
	NSLog(@"session to delete: %d", sessionID - 2);
#endif
	[dataController deleteVideosWithSessionID:sessionID - 2];
	// update all page number
	[dataController resetAllChannelsPageNumber];
	// post notification
	[[NSNotificationCenter defaultCenter] postNotificationName:NMBeginNewSessionNotification object:self];
}

- (void)resumeSession:(NSInteger)sid {
	sessionID = sid;
	NM_SESSION_ID = [[NSNumber alloc] initWithInteger:sid];
}

#pragma mark Notification handler
- (void)handleChannelCreationNotification:(NSNotification *)aNotification {
	// received notification of channel creation
	NMChannel * chnObj = [[aNotification userInfo] objectForKey:@"channel"];
	[self issueSubscribe:YES channel:chnObj];
}

- (void)handleSocialMediaLoginNotificaiton:(NSNotification *)aNotificaiton {
	didFinishLogin = YES;
	// get that particular channel
	[self issueGetSubscribedChannels];
}

- (void)handleDidSubscribeChannelNotification:(NSNotification *)aNotification {
	// when user has subscribed a channel, we need to check if the channel has contents populated.
	NMChannel * chnObj = [[aNotification userInfo] objectForKey:@"channel"];
	if ( [chnObj.type integerValue] == NMChannelKeywordType && ![chnObj.nm_populated boolValue] ) {
		// this is a keyword channel. we need to check if if has been populated or not
		// fire the polling logic
		[self pollServerForChannelReadiness];
	}
}

- (void)handleDidGetChannelsNotification:(NSNotification *)aNotification {
	if ( !didFinishLogin ) return;
	
	didFinishLogin = NO;
	// check user channels
	if ( ![dataController.myQueueChannel.nm_populated boolValue] ) {
		[self issueGetMoreVideoForChannel:dataController.myQueueChannel];
	}
	if ( ![dataController.favoriteVideoChannel.nm_populated boolValue] ) {
		[self issueGetMoreVideoForChannel:dataController.favoriteVideoChannel];
	}
	// stream channel (twitter/facebook), we don't distinguish here whether the user has just logged in twitter or facebook. no harm fetching video list for 
	NMChannel * chnObj = nil;
	BOOL shouldFirePollingLogic = NO;
	if ( NM_USER_TWITTER_CHANNEL_ID ) {
		chnObj = [dataController channelForID:[NSNumber numberWithInteger:NM_USER_TWITTER_CHANNEL_ID]];
		if ( [chnObj.nm_populated boolValue] ) {
			if ( [chnObj.nm_hidden boolValue] ) {
				chnObj.nm_hidden = [NSNumber numberWithBool:NO];
			}
			// fetch the list of video in this twitter stream channel
			[self issueGetMoreVideoForChannel:chnObj];
		} else {
			// never populated before
			shouldFirePollingLogic = YES;
		}
	}
	if ( NM_USER_FACEBOOK_CHANNEL_ID ) {
		chnObj = [dataController channelForID:[NSNumber numberWithInteger:NM_USER_FACEBOOK_CHANNEL_ID]];
		if ( [chnObj.nm_populated boolValue] ) {
			if ( [chnObj.nm_hidden boolValue] ) {
				chnObj.nm_hidden = [NSNumber numberWithBool:NO];
			}
			// fetch the list of video in this twitter stream channel
			[self issueGetMoreVideoForChannel:chnObj];
		} else {
			// never populated before
			shouldFirePollingLogic = YES;
		}
	}
	if ( shouldFirePollingLogic ) {
		NSLog(@"Should schedule polling timer");
		[self pollServerForChannelReadiness];
	}
}

- (void)handleFailEditUserSettingsNotification:(NSNotification *)aNotification {
	// fail saving settings. need to retry
	[self issueEditUserSettings];
}

- (void)reachabilityChanged:(NSNotification *)aNotification {
    NetworkStatus netStatus = [wifiReachability currentReachabilityStatus];
    BOOL connectionRequired = [wifiReachability connectionRequired];
	if ( !connectionRequired ) {
		if ( netStatus == ReachableViaWiFi ) {
			// switch to HD
			NM_WIFI_REACHABLE = YES;
			NM_URL_REQUEST_TIMEOUT = 30.0f;
		} else {
			// switch to SD
			NM_WIFI_REACHABLE = NO;
			// longer timeout value
			NM_URL_REQUEST_TIMEOUT = 60.0f;
		}
	}
	NSLog(@"########## wifi reachable %d ###########", NM_WIFI_REACHABLE);
}

#pragma mark Queue tasks to network controller
- (void)issueCreateUser; {
	NMCreateUserTask * task = [[NMCreateUserTask alloc] init];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueVerifyTwitterAccountWithURL:(NSURL *)aURL {
	NMCreateUserTask * task = [[NMCreateUserTask alloc] initTwitterVerificationWithURL:aURL];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueVerifyFacebookAccountWithURL:(NSURL *)aURL {
	NMCreateUserTask * task = [[NMCreateUserTask alloc] initFacebookVerificationWithURL:aURL];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueVerifyYoutubeAccountWithURL:(NSURL *)aURL {
	NMCreateUserTask * task = [[NMCreateUserTask alloc] initYoutubeVerificationWithURL:aURL];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueEditUserSettings {
	// user settings should be readily saved in NSUserDefaults
	NMUserSettingsTask * task = [[NMUserSettingsTask alloc] init];
	[networkController addNewConnectionForTask:task];
	[task release];
}

//- (void)issueSignOutTwitterAccount {
//	NMSignOutUserTask * task = [[NMSignOutUserTask alloc] initWithCommand:NMCommandDeauthoriseTwitterAccount];
//	[networkController addNewConnectionForTask:task];
//	[task release];
//}
//
//- (void)issueSignOutFacebookAccout {
//	NMSignOutUserTask * task = [[NMSignOutUserTask alloc] initWithCommand:NMCommandDeauthoriseFaceBookAccount];
//	[networkController addNewConnectionForTask:task];
//	[task release];
//}

- (void)issueGetFeaturedCategories {
	NMGetCategoriesTask * task = [[NMGetCategoriesTask alloc] init];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueGetChannelsForCategory:(NMCategory *)aCat {
	NMGetChannelsTask * task = [[NMGetChannelsTask alloc] initGetChannelForCategory:aCat];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueGetChannelWithID:(NSInteger)chnID {
	NMGetChannelsTask * task = [[NMGetChannelsTask alloc] initGetChannelWithID:chnID];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueGetFeaturedChannelsForCategories:(NSArray *)catArray {
	NMGetChannelsTask * task = [[NMGetChannelsTask alloc] initGetFeaturedChannelsForCategories:catArray];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueChannelSearchForKeyword:(NSString *)aKeyword {
	NMGetChannelsTask * task = [[NMGetChannelsTask alloc] initSearchChannelWithKeyword:aKeyword];
	[networkController cancelSearchTasks];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueGetSubscribedChannels {
//	NMGetChannelsTask * task = [[NMGetChannelsTask alloc] initGetFriendChannels];
//	[networkController addNewConnectionForTask:task];
//	[task release];

//	task = [[NMGetChannelsTask alloc] initGetTopicChannels];
//	[networkController addNewConnectionForTask:task];
//	[task release];

	NMGetChannelsTask * task = [[NMGetChannelsTask alloc] initGetDefaultChannels];
	[networkController addNewConnectionForTask:task];
	[task release];
}

//- (void)issueGetVideoListForChannel:(NMChannel *)chnObj {
//#if (defined DEBUG_PLAYER_DEBUG_MESSAGE || defined DEBUG_VIDEO_LIST_REFRESH)
//	NSLog(@"get video list - %@ %@", chnObj.title, chnObj.nm_id);
//#endif
//	if ( [chnObj.nm_id integerValue] < 0 ) return;
//	// if it's a new channel, we should have special handling on fail
//	NMGetChannelVideoListTask * task = [[NMGetChannelVideoListTask alloc] initWithChannel:chnObj];
//	[networkController addNewConnectionForTask:task];
//	[task release];
//}

- (void)issueGetMoreVideoForChannel:(NMChannel *)chnObj {
#if (defined DEBUG_PLAYER_DEBUG_MESSAGE || defined DEBUG_VIDEO_LIST_REFRESH)
	NSLog(@"get video list - %@ %@", chnObj.title, chnObj.nm_id);
#endif
	NMGetChannelVideoListTask * task = [[NMGetChannelVideoListTask alloc] initGetMoreVideoForChannel:chnObj];
	[networkController addNewConnectionForTask:task];
	[task release];
}

//- (void)issueGetVideoListForChannel:(NMChannel *)chnObj numberOfVideos:(NSUInteger)numVid {
//#if (defined DEBUG_PLAYER_DEBUG_MESSAGE || defined DEBUG_VIDEO_LIST_REFRESH)
//	NSLog(@"get video list - %@ %d", chnObj.title, numVid);
//#endif
//	NMGetChannelVideoListTask * task = [[NMGetChannelVideoListTask alloc] initWithChannel:chnObj];
//	task.numberOfVideoRequested = numVid;
//	[networkController addNewConnectionForTask:task];
//	[task release];
//}

//- (void)issueGetLiveChannel {
//	NMGetChannelVideoListTask * task = [[NMGetChannelVideoListTask alloc] init];
//	[networkController addNewConnectionForTask:task];
//	[task release];
//}

- (NMGetChannelDetailTask *)issueGetDetailForChannel:(NMChannel *)chnObj {
	NMGetChannelDetailTask * task = [[NMGetChannelDetailTask alloc] initWithChannel:chnObj];
	[networkController addNewConnectionForTask:task];
	return [task autorelease];
}

- (void)issueGetDirectURLForVideo:(NMVideo *)aVideo {
	NMGetYouTubeDirectURLTask * task = [[NMGetYouTubeDirectURLTask alloc] initWithVideo:aVideo];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (NMImageDownloadTask *)issueGetThumbnailForAuthor:(NMVideoDetail *)dtlObj {
	NMImageDownloadTask * task = nil;
	if ( dtlObj.author_thumbnail_uri ) {
		task = [[NMImageDownloadTask alloc] initWithAuthor:dtlObj];
		[networkController addNewConnectionForTask:task];
		[task autorelease];
	}
	return task;
}

- (NMImageDownloadTask *)issueGetThumbnailForChannel:(NMChannel *)chnObj {
	NMImageDownloadTask * task = nil;
	if ( chnObj.thumbnail_uri ) {
		task = [[NMImageDownloadTask alloc] initWithChannel:chnObj];
		[networkController addNewConnectionForTask:task];
		[task autorelease];
	}
	return task;
}

- (void)issueRefreshHiddenSubscribedChannels {
	NSArray * chns = [dataController hiddenSubscribedChannels];
	if ( chns ) {
		// loop through them and issue refresh request
		for (NMChannel * chnObj in chns) {
			[self issueGetMoreVideoForChannel:chnObj];
		}
	}
}

- (NMImageDownloadTask *)issueGetPreviewThumbnail:(NMPreviewThumbnail *)pv {
	NMImageDownloadTask * task = nil;
	if ( pv.thumbnail_uri ) {
		task = [[NMImageDownloadTask alloc] initWithPreviewThumbnail:pv];
		[networkController addNewConnectionForTask:task];
		[task autorelease];
	}
	return task;
}


- (NMImageDownloadTask *)issueGetThumbnailForVideo:(NMVideo *)vdo {
	NMImageDownloadTask * task = nil;
	if ( vdo.thumbnail_uri ) {
		task = [[NMImageDownloadTask alloc] initWithVideoThumbnail:vdo];
		[networkController addNewConnectionForTask:task];
		[task autorelease];
	}
	return task;
}

- (void)issueSubscribe:(BOOL)aSubscribe channel:(NMChannel *)chnObj {
	NMTask * task = nil;
	if ( aSubscribe && [chnObj.nm_id integerValue] == 0 ) {
		// subscribing placeholder channel
		task = [[NMCreateChannelTask alloc] initWithPlaceholderChannel:chnObj];
	} else {
		task = [[NMEventTask alloc] initWithChannel:chnObj subscribe:aSubscribe];
	}
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueSubscribeChannels:(NSArray *)chnArray {
	NMEventTask * task = nil;
	NSMutableArray * taskAy = [NSMutableArray arrayWithCapacity:[chnArray count]];
	for (NMChannel * chnObj in chnArray) {
		task = [[NMEventTask alloc] initWithChannel:chnObj subscribe:YES];
		task.bulkSubscribe = YES;
		[taskAy addObject:task];
		[task release];
	}
	[networkController addNewConnectionForTasks:taskAy];
}

- (void)issueShare:(BOOL)share video:(NMVideo *)aVideo duration:(NSInteger)vdur elapsedSeconds:(NSInteger)sec {
	NMEventType t = share ? NMEventShare : NMEventUnfavorite;
	NMEventTask * task = [[NMEventTask alloc] initWithEventType:t forVideo:aVideo];
//	task.duration = vdur;
	task.elapsedSeconds = sec;
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueShare:(BOOL)share video:(NMVideo *)aVideo duration:(NSInteger)vdur elapsedSeconds:(NSInteger)sec message:(NSString *)aString {
	NMEventType t = share ? NMEventShare : NMEventUnfavorite;
	NMEventTask * task = [[NMEventTask alloc] initWithEventType:t forVideo:aVideo];
	task.message = aString;
	task.elapsedSeconds = sec;
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueSendViewEventForVideo:(NMVideo *)aVideo elapsedSeconds:(NSInteger)sec playedToEnd:(BOOL)aEnd {
	NMEventTask * task = [[NMEventTask alloc] initWithEventType:NMEventView forVideo:aVideo];
	task.playedToEnd = aEnd;
	// how long the user has watched a video
	task.elapsedSeconds = sec;
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueSendViewEventForVideo:(NMVideo *)aVideo start:(NSInteger)aStart elapsedSeconds:(NSInteger)sec {
	NMEventTask * task = [[NMEventTask alloc] initWithEventType:NMEventView forVideo:aVideo];
	// how long the user has watched a video
	task.elapsedSeconds = sec;
	task.startSecond = aStart;
	[networkController addNewConnectionForTask:task];
	[task release];
}


- (void)issueExamineVideo:(NMVideo *)aVideo errorInfo:(NSDictionary *)errDict {
	NMEventTask * task = [[NMEventTask alloc] initWithEventType:NMEventExamine forVideo:aVideo];
	task.errorInfo = errDict;
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueEnqueue:(BOOL)shouldQueue video:(NMVideo *)aVideo {
	NMEventType t = shouldQueue ? NMEventEnqueue : NMEventDequeue;
	NMEventTask * task = [[NMEventTask alloc] initWithEventType:t forVideo:aVideo];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)cancelAllTasks {
	[networkController performSelector:@selector(forceCancelAllTasks) onThread:networkController.controlThread withObject:nil waitUntilDone:YES];
}

- (void)issueCheckUpdateForDevice:(NSString *)devType {
	NMCheckUpdateTask * task = [[NMCheckUpdateTask alloc] initWithDeviceType:devType];
	[networkController addNewConnectionForTask:task];
	[task release];
}

#pragma mark Token
- (void)issueRenewToken {
	NMTokenTask * task = [[NMTokenTask alloc] initGetToken];
	[networkController addNewConnectionForImmediateTask:task];
	[task release];
}

- (void)issueTokenTest {
	NMTokenTask * task = [[NMTokenTask alloc] initTestToken];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)checkAndRenewToken {
	NSTimeInterval t = [NM_USER_TOKEN_EXPIRY_DATE timeIntervalSinceNow];
	if ( t < 0 ) {
		// token has already expired.
		[self setTokenRenewMode:YES];
	} else if ( t < 300.0f ) {
		// if less than 5 min to expire, renew
		[self issueRenewToken];
	}
}

- (void)setTokenRenewMode:(BOOL)on {
	networkController.tokenRenewMode = on;
	[self issueRenewToken];
}

- (void)handleTokenNotification:(NSNotification *)aNotification {
	NSString * notName = [aNotification name];
	if ( [notName isEqualToString:NMDidRequestTokenNotification] ) {
		// renewed token successfully
		[self setTokenRenewMode:NO];
	} else if ( [notName isEqualToString:NMDidFailRequestTokenNotification] ) {
		[self issueRenewToken];
	}
}

#pragma mark Channel Polling
- (void)issuePollServerForChannel:(NMChannel *)chnObj {
	NMPollChannelTask * task = [[NMPollChannelTask alloc] initWithChannel:chnObj];
	[networkController addNewConnectionForTask:task];
	[task release];
	return;
}

- (void)pollServerForChannelReadiness {
	// check the list of channels
	NSArray * result = [dataController channelsNeverPopulatedBefore];
	if ( result ) {
		self.unpopulatedChannels = [NSMutableArray arrayWithArray:result];
		// run the timer method
		if ( !pollingTimer ) {
			self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(pollingTimerMethod:) userInfo:nil repeats:YES];
		} else {
			[pollingTimer fire];
		}
		// issue poll request for each channel
	}
}

- (void)stopPollingServer {
	if ( pollingTimer ) {
		NSLog(@"stop timer method");
		[pollingTimer invalidate];
		self.pollingTimer = nil;
	}
}

- (void)pollingTimerMethod:(NSTimer *)aTimer {
	NSLog(@"polling timer method called");
	for (NMChannel * chnObj in unpopulatedChannels) {
		[self issuePollServerForChannel:chnObj];
	}
}

- (void)handleChannelPollingNotification:(NSNotification *)aNotification {
	// check polling status
	NSDictionary * dict = [aNotification userInfo];
	NMChannel * chnObj = [dict objectForKey:@"channel"];
	BOOL popStatus = [[dict objectForKey:@"populated"] boolValue];
	if ( popStatus ) {
		// populated - remove from the list
		[unpopulatedChannels removeObject:chnObj];
		// fire the get channel list request
		[self issueGetMoreVideoForChannel:chnObj];
	}
	if ( [unpopulatedChannels count] == 0 ) {
		// all channels have been processed and populated
		[pollingTimer invalidate];
		self.pollingTimer = nil;
	}
}

//- (void)handleFailChannelPollingNotification:(NSNotification *)aNotification {
//	
//}

@end
