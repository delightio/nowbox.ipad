//
//  NMTaskQueueController.h
//  Nowmov
//
//  Created by Bill So on 05/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMDataType.h"

@class NMNetworkController;
@class NMDataController;
@class NMCategory;
@class NMChannel;
@class NMPreviewThumbnail;
@class NMVideo;
@class NMVideoDetail;
@class NMImageDownloadTask;
@class NMGetChannelDetailTask;
@class Reachability;

@interface NMTaskQueueController : NSObject {
	NSManagedObjectContext * managedObjectContext;
	NSInteger sessionID;
	
	NMNetworkController * networkController;
	NMDataController * dataController;
	
	// polling channel population status
	NSTimer * pollingTimer;
	NSTimer * userSyncTimer;
	NSTimer * tokenRenewTimer;
	NSMutableArray * unpopulatedChannels;
	BOOL didFinishLogin;
	NSUInteger pollingRetryCount;
	
	Reachability * wifiReachability;
}

@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, readonly) NMNetworkController * networkController;
@property (nonatomic, readonly) NMDataController * dataController;
@property (nonatomic, retain) NSTimer * pollingTimer;
@property (nonatomic, retain) NSTimer * userSyncTimer;
@property (nonatomic, retain) NSTimer * tokenRenewTimer;
@property (nonatomic, retain) NSMutableArray * unpopulatedChannels;

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
//- (void)issueSignOutTwitterAccount;
//- (void)issueSignOutFacebookAccout;
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
// Get update info
- (void)issueCheckUpdateForDevice:(NSString *)devType;

// Video
- (void)issueGetDirectURLForVideo:(NMVideo *)aVideo;
- (NMImageDownloadTask *)issueGetThumbnailForAuthor:(NMVideoDetail *)dtlObj;
- (NMImageDownloadTask *)issueGetThumbnailForVideo:(NMVideo *)vdo;
/*
 Refresh channels which user has subscribed but set hidden by the app. A channel is set hidden if it's a user/stream channel and it has no video.
 */
- (void)issueRefreshHiddenSubscribedChannels;

// Event tracking
// Share video
- (void)issueShare:(BOOL)share video:(NMVideo *)aVideo duration:(NSInteger)vdur elapsedSeconds:(NSInteger)sec;
- (void)issueShareWithService:(NMSocialLoginType)serType video:(NMVideo *)aVideo duration:(NSInteger)vdur elapsedSeconds:(NSInteger)sec message:(NSString *)aString;
- (void)issueSendViewEventForVideo:(NMVideo *)aVideo elapsedSeconds:(NSInteger)sec playedToEnd:(BOOL)aEnd;
- (void)issueSendViewEventForVideo:(NMVideo *)aVideo start:(NSInteger)aStart elapsedSeconds:(NSInteger)sec;
- (void)issueExamineVideo:(NMVideo *)aVideo errorInfo:(NSDictionary *)errDict;
// Watch later
- (void)issueEnqueue:(BOOL)shouldQueue video:(NMVideo *)aVideo;

- (void)cancelAllTasks;
@end
