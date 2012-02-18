//
//  NMTaskQueueController.h
//  Nowmov
//
//  Created by Bill So on 05/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMDataType.h"
#import <Accounts/Accounts.h>

@class NMNetworkController;
@class NMDataController;
@class NMCategory;
@class NMChannel;
@class NMPreviewThumbnail;
@class NMVideo;
@class NMConcreteVideo;
@class NMVideoDetail;
@class NMAuthor;
@class NMPersonProfile;
@class NMFacebookInfo;
@class NMImageDownloadTask;
@class NMGetChannelDetailTask;
@class Reachability;

@interface NMTaskQueueController : NSObject {
	NSManagedObjectContext * managedObjectContext;
	NSInteger sessionID;
	
	NMNetworkController * networkController;
	NMDataController * dataController;
	
	// polling channel population status
	NSTimer * channelPollingTimer;
	NSTimer * youTubePollingTimer;
	NSTimer * videoImportTimer;
	NSTimer * userSyncTimer;
	NSTimer * tokenRenewTimer;
	NSTimer * socialChannelParsingTimer;
	NSMutableArray * unpopulatedChannels;
	BOOL didFinishLogin;
	NSUInteger pollingRetryCount, channelPollingRetryCount;
	
	BOOL appFirstLaunch;
	BOOL syncInProgress;
	Reachability * wifiReachability;
}

@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, readonly) NMNetworkController * networkController;
@property (nonatomic, readonly) NMDataController * dataController;
@property (nonatomic, retain) NSTimer * channelPollingTimer;
@property (nonatomic, retain) NSTimer * youTubePollingTimer;
@property (nonatomic, retain) NSTimer * videoImportTimer;
@property (nonatomic, retain) NSTimer * userSyncTimer;
@property (nonatomic, retain) NSTimer * tokenRenewTimer;
@property (nonatomic, retain) NSTimer * socialChannelParsingTimer;
@property (nonatomic, retain) NSMutableArray * unpopulatedChannels;
@property (nonatomic) BOOL syncInProgress;
@property (nonatomic) BOOL appFirstLaunch;
@property (nonatomic, readonly) ACAccountStore * accountStore;

+ (NMTaskQueueController *)sharedTaskQueueController;

- (void)cancelAllPlaybackTasksForChannel:(NMChannel *)chnObj;

// Session management
- (void)beginNewSession:(NSInteger)sid;
- (void)resumeSession:(NSInteger)sid;
// User management
- (void)issueCreateUser;
- (void)issueVerifyTwitterAccountWithURL:(NSURL *)aURL;
- (void)issueVerifyFacebookAccountWithURL:(NSURL *)aURL;
- (void)issueVerifyYouTubeAccountWithURL:(NSURL *)aURL;
- (void)issueDeauthorizeYouTube;
- (void)issueEditUserSettings;
- (void)issueSyncRequest;
// Token
- (void)issueRenewToken;
//- (void)issueTokenTest;
- (void)checkAndRenewToken;
/*!
 In token renew mode, the backend will stop executing other tasks except for the "renew token task". It will also stop popping alert pop up.
 */
- (void)setTokenRenewMode:(BOOL)on;
// Category
- (void)issueGetFeaturedCategories;
- (void)issueGetChannelsForCategory:(NMCategory *)aCat;
- (void)issueChannelSearchForKeyword:(NSString *)aKeyword;
// Channel
- (void)issueGetSubscribedChannels;
- (void)issueGetMoreVideoForChannel:(NMChannel *)chnObj;
- (void)issueGetChannelWithID:(NSInteger)chnID;
- (void)issueGetFeaturedChannelsForCategories:(NSArray *)catArray;
- (void)issueCompareSubscribedChannels;
- (NMImageDownloadTask *)issueGetThumbnailForCategory:(NMCategory *)catObj;
- (NMImageDownloadTask *)issueGetThumbnailForChannel:(NMChannel *)chnObj;
- (NMImageDownloadTask *)issueGetPreviewThumbnail:(NMPreviewThumbnail *)pv;
- (NMGetChannelDetailTask *)issueGetDetailForChannel:(NMChannel *)chnObj;
// Channel subscription
- (void)issueSubscribe:(BOOL)aSubscribe channel:(NMChannel *)chnObj;
- (void)issueSubscribeChannels:(NSArray *)chnArray;
// Polling channel
- (void)issuePollServerForChannel:(NMChannel *)chnObj;
- (void)pollServerForChannelReadiness;
- (void)stopPollingServer;
// Poll for YouTube
- (void)issuePollServerForYouTubeSyncSignal;
- (void)pollServerForYouTubeSyncSignal;
- (void)slowPollServerForYouTubeSyncSycnal;
- (void)syncYouTubeChannels;
// Get update info
- (void)issueCheckUpdateForDevice:(NSString *)devType;

// Video
- (void)issueGetDirectURLForVideo:(NMVideo *)aVideo;
- (void)issueImportVideo:(NMConcreteVideo *)aVideo;
- (NMImageDownloadTask *)issueGetThumbnailForAuthor:(NMAuthor *)anAuthor;
- (NMImageDownloadTask *)issueGetThumbnailForVideo:(NMVideo *)vdo;
/*
 Refresh channels which user has subscribed but set hidden by the app. A channel is set hidden if it's a user/stream channel and it has no video.
 */
- (void)issueRefreshHiddenSubscribedChannels;

// Event tracking
// Share video
- (void)issueShareEventForVideo:(NMVideo *)aVideo duration:(NSInteger)vdur elapsedSeconds:(NSInteger)sec;
- (void)issueMakeFavorite:(BOOL)isFav video:(NMVideo *)aVideo duration:(NSInteger)vdur elapsedSeconds:(NSInteger)sec;
- (void)issueShareWithService:(NMSocialLoginType)serType video:(NMVideo *)aVideo duration:(NSInteger)vdur elapsedSeconds:(NSInteger)sec message:(NSString *)aString;
- (void)issueSendViewEventForVideo:(NMVideo *)aVideo elapsedSeconds:(NSInteger)sec playedToEnd:(BOOL)aEnd;
- (void)issueSendViewEventForVideo:(NMVideo *)aVideo start:(NSInteger)aStart elapsedSeconds:(NSInteger)sec;
- (void)issueExamineVideo:(NMVideo *)aVideo errorInfo:(NSDictionary *)errDict;
// Watch later
- (void)issueEnqueue:(BOOL)shouldQueue video:(NMVideo *)aVideo;

// Facebook or Twitter (social)
- (void)issueProcessFeedForChannel:(NMChannel *)chnObj;
- (void)issueGetMyFacebookProfile;
- (void)issueGetProfile:(NMPersonProfile *)aProfile account:(ACAccount *)acObj;
- (void)issueSubscribePerson:(NMPersonProfile *)aProfile;
- (void)scheduleSyncSocialChannels;
- (void)scheduleImportVideos;
- (void)issuePostComment:(NSString *)msg forPost:(NMFacebookInfo *)info;
- (void)issuePostLike:(BOOL)aLike forPost:(NMFacebookInfo *)info;
- (void)prepareSignOutFacebook;
- (void)endSignOutFacebook;

// Debug task queue status
- (void)debugPrintCommandPoolStatus;

- (void)cancelAllTasks;
@end
