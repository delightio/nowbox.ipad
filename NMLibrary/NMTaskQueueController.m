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
#import "NMCategory.h"
#import "NMChannel.h"
#import "NMPreviewThumbnail.h"
#import "NMVideo.h"
#import "NMConcreteVideo.h"
#import "NMAuthor.h"
#import "NMSubscription.h"
#import "NMPersonProfile.h"
#import "Reachability.h"
#import "ipadAppDelegate.h"
#import "FBConnect.h"

#define NM_USER_SYNC_CHECK_TIMER_INTERVAL	60.0
#define NM_USER_POLLING_TIMER_INTERVAL		5.0

NSInteger NM_USER_ACCOUNT_ID				= 0;
NSDate * NM_USER_TOKEN_EXPIRY_DATE			= nil;
NSString * NM_USER_TOKEN					= nil;
NSInteger NM_USER_FAVORITES_CHANNEL_ID		= 0;
NSInteger NM_USER_WATCH_LATER_CHANNEL_ID	= 0;
NSInteger NM_USER_HISTORY_CHANNEL_ID		= 0;
NSInteger NM_USER_FACEBOOK_CHANNEL_ID		= 0;
NSInteger NM_USER_TWITTER_CHANNEL_ID		= 0;
BOOL NM_USER_YOUTUBE_SYNC_ACTIVE			= NO;
NSString * NM_USER_YOUTUBE_USER_NAME		= nil;
NSUInteger NM_USER_YOUTUBE_LAST_SYNC		= 0;
NSUInteger NM_USER_YOUTUBE_SYNC_SERVER_TIME	= 0;
BOOL NM_USER_SHOW_FAVORITE_CHANNEL			= NO;
NSInteger NM_VIDEO_QUALITY					= 0;
//BOOL NM_YOUTUBE_MOBILE_BROWSER_RESOLUTION	= YES;
NSNumber * NM_SESSION_ID					= nil;
BOOL NM_WIFI_REACHABLE						= YES;
BOOL NM_RATE_US_REMINDER_SHOWN              = NO;
NSInteger NM_RATE_US_REMINDER_DEFER_COUNT   = 0;
NSInteger NM_SHARE_COUNT                    = 0;

NSString * const NMBeginNewSessionNotification = @"NMBeginNewSessionNotification";
NSString * const NMShowErrorAlertNotification = @"NMShowErrorAlertNotification";

static NMTaskQueueController * sharedTaskQueueController_ = nil;
BOOL NMPlaybackSafeVideoQueueUpdateActive = NO;

@implementation NMTaskQueueController

@synthesize managedObjectContext;
@synthesize networkController;
@synthesize dataController;
@synthesize youTubePollingTimer, tokenRenewTimer;
@synthesize channelPollingTimer, userSyncTimer;
@synthesize socialChannelParsingTimer, videoImportTimer;
@synthesize unpopulatedChannels;
@synthesize syncInProgress, appFirstLaunch;
@synthesize accountStore = _accountStore;

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
//	[nc addObserver:self selector:@selector(handleSocialMediaLoginNotificaiton:) name:NMDidVerifyUserNotification object:nil];
//	[nc addObserver:self selector:@selector(handleDidSyncUserNotification:) name:NMDidSynchronizeUserNotification object:nil];
//	[nc addObserver:self selector:@selector(handleSocialMediaLogoutNotification:) name:NMDidDeauthorizeUserNotification object:nil];
	// polling server for channel update
	[nc addObserver:self selector:@selector(handleChannelPollingNotification:) name:NMDidPollChannelNotification object:nil];
	[nc addObserver:self selector:@selector(handleYouTubePollingNotification:) name:NMDidPollUserNotification object:nil];
	[nc addObserver:self selector:@selector(handleDidGetChannelsNotification:) name:NMDidGetChannelsNotification object:nil];
	[nc addObserver:self selector:@selector(handleFailEditUserSettingsNotification:) name:NMDidFailEditUserSettingsNotification object:nil];
	[nc addObserver:self selector:@selector(handleTokenNotification:) name:NMDidRequestTokenNotification object:nil];
	[nc addObserver:self selector:@selector(handleTokenNotification:) name:NMDidFailRequestTokenNotification object:nil];
	
	// listen to subscription as well
	[nc addObserver:self selector:@selector(handleDidSubscribeChannelNotification:) name:NMDidSubscribeChannelNotification object:nil];
	[nc addObserver:self selector:@selector(handleDidParseFeedNotification:) name:NMDidParseFacebookFeedNotification object:nil];
	// do the same thing for twitter as well
	[nc addObserver:self selector:@selector(handleDidParseFeedNotification:) name:NMDidParseTwitterFeedNotification object:nil];

	
    wifiReachability = [[Reachability reachabilityWithHostName:@"api.nowbox.com"] retain];
	[wifiReachability startNotifier];
    [nc addObserver: self selector: @selector(reachabilityChanged:) name:kReachabilityChangedNotification object: nil];
	
	NM_USER_TOKEN = [[NSString stringWithString:@"no_token"] retain];

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
	if ( youTubePollingTimer ) {
		[youTubePollingTimer invalidate], [youTubePollingTimer release];	
	}
	if ( userSyncTimer ) {
		[userSyncTimer invalidate], [userSyncTimer release];
	}
	if ( tokenRenewTimer ) {
		[tokenRenewTimer invalidate], [tokenRenewTimer release];
	}
	if ( socialChannelParsingTimer ) {
		[socialChannelParsingTimer invalidate], [socialChannelParsingTimer release];
	}
	if ( videoImportTimer ) {
		[videoImportTimer invalidate], [videoImportTimer release];
	}
	[wifiReachability stopNotifier];
	[wifiReachability release];
	[_accountStore release];
	[super dealloc];
}

- (void)cancelAllPlaybackTasksForChannel:(NMChannel *)chnObj {
	// cancel all playback related tasks created for the chnObj.
	[networkController cancelPlaybackRelatedTasksForChannel:chnObj];
	// make sure NO notification will be sent after execution of this method. tasks do not have to be wiped out here. But they must not trigger and sending of notification if those tasks belong to the chnObj
}

- (void)debugPrintCommandPoolStatus {
	[networkController performSelector:@selector(debugPrintCommandPoolStatus) onThread:networkController.controlThread withObject:nil waitUntilDone:NO];
}

- (void)issueDebugProcessFeed {
	NSArray * allSubscriptions = [dataController allSubscriptions];
	for (NMSubscription * scrpt in allSubscriptions) {
		[self issueProcessFeedForChannel:scrpt.channel];
	}
}

- (void)issueDebugImportYouTubeVideos {
	NSArray * allSubscriptions = [dataController allSubscriptions];
	NSArray * videos;
	for (NMSubscription * scrpt in allSubscriptions) {
		// get the list of videos
		videos = [dataController pendingImportVideosForChannel:scrpt.channel];
		// issue request for each video
		if ( [videos count] ) {
			[self issueImportVideo:[videos objectAtIndex:0]];
		}
	}
}

- (ACAccountStore *)accountStore {
	if ( _accountStore == nil ) {
		_accountStore = [[ACAccountStore alloc] init];
	}
	return _accountStore;
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
	NMCreateUserTask * sender = [aNotificaiton object];
	switch (sender.command) {
		case NMCommandVerifyFacebookUser:
		case NMCommandVerifyTwitterUser:
			// get that particular channel
			if ( !appFirstLaunch ) {
				didFinishLogin = YES;
				[self issueGetSubscribedChannels];
			}
			break;
			
		case NMCommandVerifyYouTubeUser:
			if ( NM_USER_YOUTUBE_SYNC_ACTIVE ) {
				// check if it's first launch
				if ( appFirstLaunch ) {
					// need to poll the server to look for difference
					[self pollServerForYouTubeSyncSignal];
				} else {
					// immediately issue get channel
					didFinishLogin = YES;
					self.syncInProgress = YES;
					// don't call "syncYouTubeChannels" method. Cos we haven't created the watch later and favorite channel yet.
					[self issueGetSubscribedChannels];
					[self slowPollServerForYouTubeSyncSycnal];
				}
			}
			break;
		default:
			break;
	}
}

- (void)handleDidGetPersonProfile:(NSNotification *)aNotification {
	/*
	 Listen to this notificaiton only when the user signs in Twitter or Facebook.
	 
	 For Facebook, we set this task queue schedule to listen to notification in the NMAccountManager. When user has successfully granted this app access to his/her Facebook account, NMAccountManager will get called (the facebook delegate)
	*/
	NMPersonProfile * theProfile = [[aNotification userInfo] objectForKey:@"target_object"];
	if ( [theProfile.nm_me boolValue] ) {
		// trigger feed parsing
		[self scheduleSyncSocialChannels];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:[aNotification name] object:nil];
	}
}

- (void)handleDidParseFeedNotification:(NSNotification *)aNotification {
	NSDictionary * infoDict = [aNotification userInfo];
	if ( [[infoDict objectForKey:@"num_video_added"] integerValue] ) {
		// we found new video in the news feed
		if ( videoImportTimer == nil ) {
			[self scheduleImportVideos];
		}
	}
	NMChannel * chnObj = [infoDict objectForKey:@"channel"];
	switch ([chnObj.type integerValue]) {
		case NMChannelUserTwitterType:
		{
			NMParseTwitterFeedTask * task = [[NMParseTwitterFeedTask alloc] initWithInfo:infoDict];
			[networkController addNewConnectionForTask:task];
			[task release];
			break;
		}
		case NMChannelUserFacebookType:
		{
			NSString * urlStr = [infoDict objectForKey:@"next_url"];
			if ( urlStr ) {
				NMParseFacebookFeedTask * task = [[NMParseFacebookFeedTask alloc] initWithChannel:chnObj directURLString:urlStr];
				[networkController addNewConnectionForTask:task];
				[task release];
			}
			break;
		}	
		default:
			break;
	}
}

- (void)handleDidSubscribeChannelNotification:(NSNotification *)aNotification {
	// when user has subscribed a channel, we need to check if the channel has contents populated.
	NMChannel * chnObj = [[aNotification userInfo] objectForKey:@"channel"];
	if ( [chnObj.type integerValue] == NMChannelKeywordType && ![chnObj.populated_at boolValue] ) {
		// this is a keyword channel. we need to check if if has been populated or not
		// fire the polling logic
		[self pollServerForChannelReadiness];
	}
}

- (void)handleDidGetChannelsNotification:(NSNotification *)aNotification {
	if ( didFinishLogin ) {
		didFinishLogin = NO;
		// check user channels
		if ( ![dataController.myQueueChannel.populated_at boolValue] ) {
			[self issueGetMoreVideoForChannel:dataController.myQueueChannel];
		}
		if ( ![dataController.favoriteVideoChannel.populated_at boolValue] ) {
			[self issueGetMoreVideoForChannel:dataController.favoriteVideoChannel];
		}
		// stream channel (twitter/facebook), we don't distinguish here whether the user has just logged in twitter or facebook. no harm fetching video list for 
		NMChannel * chnObj = nil;
		NMSubscription * subtObj = nil;
		BOOL shouldFirePollingLogic = NO;
		if ( NM_USER_TWITTER_CHANNEL_ID ) {
			chnObj = dataController.userTwitterStreamChannel;//[dataController channelForID:[NSNumber numberWithInteger:NM_USER_TWITTER_CHANNEL_ID]];
			subtObj = chnObj.subscription;
			if ( [chnObj.populated_at boolValue] ) {
				if ( [subtObj.nm_hidden boolValue] ) {
					subtObj.nm_hidden = (NSNumber *)kCFBooleanFalse;
				}
				// fetch the list of video in this twitter stream channel
				[self issueGetMoreVideoForChannel:chnObj];
			} else {
				// never populated before
				shouldFirePollingLogic = YES;
			}
		}
		if ( NM_USER_FACEBOOK_CHANNEL_ID ) {
			chnObj = dataController.userFacebookStreamChannel;//[dataController channelForID:[NSNumber numberWithInteger:NM_USER_FACEBOOK_CHANNEL_ID]];
			subtObj = chnObj.subscription;
			if ( [chnObj.populated_at boolValue] ) {
				if ( [subtObj.nm_hidden boolValue] ) {
					subtObj.nm_hidden = (NSNumber *)kCFBooleanFalse;
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
	} else {
		self.syncInProgress = NO;
	}
	// check if there's any channel being deleted
	NSDictionary * info = [aNotification userInfo];
	if ( [[info objectForKey:@"num_channel_deleted"] unsignedIntegerValue] ) {
		// some channels are "deleted", perform the delete after a 5s chilling period.
		[dataController performSelector:@selector(permanentDeleteMarkedChannels) withObject:nil afterDelay:5.0];
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
//	NSLog(@"########## wifi reachable %d ###########", NM_WIFI_REACHABLE);
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

- (void)issueVerifyYouTubeAccountWithURL:(NSURL *)aURL {
	NMCreateUserTask * task = [[NMCreateUserTask alloc] initYouTubeVerificationWithURL:aURL];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueDeauthorizeYouTube {
	NMDeauthorizeUserTask * task = [[NMDeauthorizeUserTask alloc] initForYouTube];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueEditUserSettings {
	// user settings should be readily saved in NSUserDefaults
	NMUserSettingsTask * task = [[NMUserSettingsTask alloc] init];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueSyncRequest {
	NMUserSynchronizeTask * task = [[NMUserSynchronizeTask alloc] init];
	[networkController addNewConnectionForTask:task];
	[task release];
}

//- (void)issueSignOutTwitterAccount {
//	NMDeauthorizeUserTask * task = [[NMDeauthorizeUserTask alloc] initWithCommand:NMCommandDeauthoriseTwitterAccount];
//	[networkController addNewConnectionForTask:task];
//	[task release];
//}
//
//- (void)issueSignOutFacebookAccout {
//	NMDeauthorizeUserTask * task = [[NMDeauthorizeUserTask alloc] initWithCommand:NMCommandDeauthoriseFaceBookAccount];
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

- (void)issueCompareSubscribedChannels {
	NMGetChannelsTask * task = [[NMGetChannelsTask alloc] initCompareSubscribedChannels];
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
	self.syncInProgress = YES;
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
	if ( sessionID ) {
		NMGetChannelVideoListTask * task = [[NMGetChannelVideoListTask alloc] initGetMoreVideoForChannel:chnObj];
		[networkController addNewConnectionForTask:task];
		[task release];
	}
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

- (void)issueImportVideo:(NMConcreteVideo *)aVideo {
	NMGetYouTubeDirectURLTask * task = [[NMGetYouTubeDirectURLTask alloc] initImportVideo:aVideo];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (NMImageDownloadTask *)issueGetThumbnailForAuthor:(NMAuthor *)anAuthor {
	NMImageDownloadTask * task = nil;
	if ( anAuthor.thumbnail_uri ) {
		task = [[NMImageDownloadTask alloc] initWithAuthor:anAuthor];
		[networkController addNewConnectionForTask:task];
		[task autorelease];
	}
	return task;
}

- (NMImageDownloadTask *)issueGetThumbnailForCategory:(NMCategory *)catObj {
	NMImageDownloadTask * task = nil;
	if ( catObj.thumbnail_uri ) {
		task = [[NMImageDownloadTask alloc] initWithCategory:catObj];
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
	if ( vdo.video.thumbnail_uri ) {
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

- (void)issueShareEventForVideo:(NMVideo *)aVideo duration:(NSInteger)vdur elapsedSeconds:(NSInteger)sec {
	NMEventTask * task = [[NMEventTask alloc] initWithEventType:NMEventShare forVideo:aVideo];
	//	task.duration = vdur;
	task.elapsedSeconds = sec;
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueMakeFavorite:(BOOL)isFav video:(NMVideo *)aVideo duration:(NSInteger)vdur elapsedSeconds:(NSInteger)sec {
	NMEventTask * task = [[NMEventTask alloc] initWithEventType:(isFav ? NMEventFavorite : NMEventUnfavorite) forVideo:aVideo];
	//	task.duration = vdur;
	task.elapsedSeconds = sec;
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueShareWithService:(NMSocialLoginType)serType video:(NMVideo *)aVideo duration:(NSInteger)vdur elapsedSeconds:(NSInteger)sec message:(NSString *)aString {
	NMPostSharingTask * task = [[NMPostSharingTask alloc] initWithType:serType video:aVideo];
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

- (void)issueProcessFeedForChannel:(NMChannel *)chnObj {
	switch ([chnObj.type integerValue]) {
		case NMChannelUserTwitterType:
		{
			NMParseTwitterFeedTask * task = [[NMParseTwitterFeedTask alloc] initWithChannel:chnObj account:[self.accountStore accountWithIdentifier:chnObj.subscription.personProfile.nm_account_identifier]];
			[networkController addNewConnectionForTask:task];
			[task release];
			break;
		}	
		case NMChannelUserFacebookType:
		{
			NMParseFacebookFeedTask * task = [[NMParseFacebookFeedTask alloc] initWithChannel:chnObj];
			[networkController addNewConnectionForTask:task];
			[task release];
			break;
		}				
		default:
			break;
	}
}

- (void)issueGetMyFacebookProfile {
	NMGetFacebookProfileTask * task = [[NMGetFacebookProfileTask alloc] initGetMe];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueGetProfile:(NMPersonProfile *)aProfile account:(ACAccount *)acObj {
	if ( acObj == nil ) {
		NMGetFacebookProfileTask * task = [[NMGetFacebookProfileTask alloc] initWithProfile:aProfile];
		[networkController addNewConnectionForTask:task];
		[task release];
	} else {
		// only support Twitter for now
		NMGetTwitterProfileTask * task = [[NMGetTwitterProfileTask alloc] initWithProfile:aProfile account:acObj];
		[networkController addNewConnectionForTask:task];
		[task release];
	}
}

- (void)issueSubscribePerson:(NMPersonProfile *)aProfile {
	if ( aProfile.subscription ) return;
	NMChannel * chn = [dataController subscribeUserChannelWithPersonProfile:aProfile];
	[self issueProcessFeedForChannel:chn];
}

- (void)scheduleSyncSocialChannels {
	// get the qualified channels
	NSArray * theChannels = [dataController socialChannelsForSync];
	NSUInteger c = [theChannels count];
	for (NSUInteger i = 0; (i < c && i < 5); i++) {
		[self issueProcessFeedForChannel:[theChannels objectAtIndex:i]];
	}
	if ( c > 5 && socialChannelParsingTimer == nil ) {
		// schedule a timer task to process other channels
		self.socialChannelParsingTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(scheduleSyncSocialChannels) userInfo:nil repeats:YES];
	} else if ( socialChannelParsingTimer ) {
		[socialChannelParsingTimer invalidate], self.socialChannelParsingTimer = nil;
	}
}

- (void)scheduleImportVideos {
#ifdef DEBUG_FACEBOOK_IMPORT
	NSLog(@"scheduleImportVideos");
#endif
	// get the qualified videos
	NSArray * theProfiles = [dataController personProfilesForSync:2];
	NSInteger cnt = 4;
	if ( theProfiles ) cnt = 2;
	NSArray * theVideos = [dataController videosForSync:cnt];
	
	if ( theVideos == nil && theProfiles == nil ) {
		// stop the timer task
		if ( videoImportTimer ) {
			[videoImportTimer invalidate];
			self.videoImportTimer = nil;
#ifdef DEBUG_FACEBOOK_IMPORT
			NSLog(@"stop video import timer");
#endif
		}
#ifdef DEBUG_FACEBOOK_IMPORT
		NSLog(@"no more video or profiles to import");
#endif
		// return immediately if no video
		return;
	}
	for (NMConcreteVideo * vdo in theVideos) {
		[self issueImportVideo:vdo];
	}
	for (NMPersonProfile * pfo in theProfiles) {
		[self issueGetProfile:pfo account:nil];
	}
	if ( videoImportTimer == nil ) self.videoImportTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(scheduleImportVideos) userInfo:nil repeats:YES];
}

- (void)issuePostComment:(NSString *)msg forPost:(NMFacebookInfo *)info {
	// save the comment
	NMFacebookComment * cmtObj = [dataController insertNewFacebookComment];
	cmtObj.facebookInfo = info;
	cmtObj.message = msg;
	cmtObj.created_time = [NSNumber numberWithFloat:[[NSDate date] timeIntervalSince1970]];
	// send it to facebook
	NMFacebookCommentTask * task = [[NMFacebookCommentTask alloc] initWithInfo:info message:msg];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issuePostLike:(BOOL)aLike forPost:(NMFacebookInfo *)info {
	NMFacebookLikeTask * task = [[NMFacebookLikeTask alloc] initWithInfo:info like:aLike];
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

- (void)syncYouTubeChannels {
	[self issueGetSubscribedChannels];
	[self issueGetMoreVideoForChannel:dataController.favoriteVideoChannel];
	[self issueGetMoreVideoForChannel:dataController.myQueueChannel];

}

#pragma mark Token
- (void)issueRenewToken {
	NMTokenTask * task = [[NMTokenTask alloc] initGetToken];
	[networkController addNewConnectionForImmediateTask:task];
	[task release];
}

//- (void)issueTokenTest {
//	NMTokenTask * task = [[NMTokenTask alloc] initTestToken];
//	[networkController addNewConnectionForTask:task];
//	[task release];
//}

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
	if ( on ) {
		[self issueRenewToken];
	}
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

#pragma mark Server Polling
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
		if ( channelPollingTimer ) {
			[channelPollingTimer fire];
		} else {
			channelPollingRetryCount = 0;
			self.channelPollingTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(pollingTimerMethod:) userInfo:nil repeats:YES];
		}
		// issue poll request for each channel
	}
}

- (void)stopPollingServer {
	if ( youTubePollingTimer ) {
		[youTubePollingTimer invalidate], self.youTubePollingTimer = nil;	
	}
	if ( userSyncTimer ) {
		[userSyncTimer invalidate], self.userSyncTimer = nil;
	}
	if ( tokenRenewTimer ) {
		[tokenRenewTimer invalidate], self.tokenRenewTimer = nil;
	}
	if ( channelPollingTimer ) {
		[channelPollingTimer invalidate], self.channelPollingTimer = nil;
	}
	if ( videoImportTimer ) {
		[videoImportTimer invalidate], self.videoImportTimer = nil;
	}
	if ( socialChannelParsingTimer ) {
		[socialChannelParsingTimer invalidate], self.socialChannelParsingTimer = nil;
	}
	NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
	[defs setObject:[NSNumber numberWithUnsignedInteger:NM_USER_YOUTUBE_LAST_SYNC] forKey:NM_USER_YOUTUBE_LAST_SYNC_KEY];
}

- (void)pollingTimerMethod:(NSTimer *)aTimer {
	for (NMChannel * chnObj in unpopulatedChannels) {
		[self issuePollServerForChannel:chnObj];
	}
}

- (void)handleChannelPollingNotification:(NSNotification *)aNotification {
	channelPollingRetryCount++;
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
	if ( [unpopulatedChannels count] == 0 || channelPollingRetryCount > 5 ) {
		// all channels have been processed and populated
		[channelPollingTimer invalidate];
		self.channelPollingTimer = nil;
	}
}

- (void)issuePollServerForYouTubeSyncSignal {
	NMPollUserTask * task = [[NMPollUserTask alloc] init];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)pollServerForYouTubeSyncSignal {
	// we assue the backend will only activate pollingTimer for only 1 service - YouTube, Facebook or Twitter.
	if ( youTubePollingTimer ) {
		[youTubePollingTimer fire];
	} else {
		pollingRetryCount = 0;
		self.youTubePollingTimer = [NSTimer scheduledTimerWithTimeInterval:NM_USER_POLLING_TIMER_INTERVAL target:self selector:@selector(performYouTubePollingForTimer:) userInfo:nil repeats:YES];
		//MARK: we may need to fire the timer once here so that we don't have the initial wait.
	}
}

- (void)performYouTubePollingForTimer:(NSTimer *)aTimer {
	[self issuePollServerForYouTubeSyncSignal];
}

- (void)handleYouTubePollingNotification:(NSNotification *)aNotification {
	if ( appFirstLaunch ) {
		// refresh app launch
		if ( !appFirstLaunch ) {
			// this is the case where the user has finished up the onboard process with a YouTube login. However, the onboard is done before the polling work finish. In this case, we don't need to perform the sync anymore
			// invalidate the timer
			[youTubePollingTimer invalidate];
			self.youTubePollingTimer = nil;
			
			return;
		}
		pollingRetryCount++;
		if ( NM_USER_YOUTUBE_SYNC_SERVER_TIME > 0 ) {
			// the account is synced. get the list of channel
			[self issueCompareSubscribedChannels];
			[youTubePollingTimer invalidate];
			self.youTubePollingTimer = nil;
			NM_USER_YOUTUBE_LAST_SYNC = NM_USER_YOUTUBE_SYNC_SERVER_TIME;
			[[NSUserDefaults standardUserDefaults] setInteger:NM_USER_YOUTUBE_LAST_SYNC forKey:NM_USER_YOUTUBE_LAST_SYNC_KEY];
		} else if ( pollingRetryCount > 5 ) {
			[youTubePollingTimer invalidate];
			self.youTubePollingTimer = nil;
		}
	} else {
		if ( NM_USER_YOUTUBE_SYNC_ACTIVE ) {
			pollingRetryCount++;
			if ( NM_USER_YOUTUBE_SYNC_SERVER_TIME > NM_USER_YOUTUBE_LAST_SYNC  ) {
				[self syncYouTubeChannels];
				[userSyncTimer invalidate];
				self.userSyncTimer = nil;
				self.syncInProgress = NO;
				NM_USER_YOUTUBE_LAST_SYNC = NM_USER_YOUTUBE_SYNC_SERVER_TIME;
				[[NSUserDefaults standardUserDefaults] setInteger:NM_USER_YOUTUBE_LAST_SYNC forKey:NM_USER_YOUTUBE_LAST_SYNC_KEY];
			} else if ( pollingRetryCount > 5 ) {
				[userSyncTimer invalidate];
				self.userSyncTimer = nil;
				self.syncInProgress = NO;
			}
		} else {
			// it's possible that the YouTube polling process is happening after the user has signed out.
			[userSyncTimer invalidate];
			self.userSyncTimer = nil;
			self.syncInProgress = NO;
		}
	}
}

- (void)slowPollServerForYouTubeSyncSycnal {
	if ( userSyncTimer ) {
		[userSyncTimer fire];
	} else {
		pollingRetryCount = 0;
		// create timer
		self.userSyncTimer = [NSTimer scheduledTimerWithTimeInterval:NM_USER_SYNC_CHECK_TIMER_INTERVAL target:self selector:@selector(performYouTubePollingForTimer:) userInfo:nil repeats:YES];
		[userSyncTimer fire];
	}
}

- (void)handleDidSyncUserNotification:(NSNotification *)aNotification {
	[self slowPollServerForYouTubeSyncSycnal];
}

@end
