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

NSInteger NM_USER_ACCOUNT_ID				= 0;
NSInteger NM_USER_FAVORITES_CHANNEL_ID		= 0;
NSInteger NM_USER_WATCH_LATER_CHANNEL_ID	= 0;
NSInteger NM_USER_HISTORY_CHANNEL_ID		= 0;
NSInteger NM_USER_FACEBOOK_CHANNEL_ID		= 0;
NSInteger NM_USER_TWITTER_CHANNEL_ID		= 0;
BOOL NM_USER_SHOW_FAVORITE_CHANNEL			= NO;
BOOL NM_USE_HIGH_QUALITY_VIDEO				= YES;
BOOL NM_YOUTUBE_MOBILE_BROWSER_RESOLUTION	= NO;
NSNumber * NM_SESSION_ID					= nil;

NSString * const NMBeginNewSessionNotification = @"NMBeginNewSessionNotification";

static NMTaskQueueController * sharedTaskQueueController_ = nil;
BOOL NMPlaybackSafeVideoQueueUpdateActive = NO;

@implementation NMTaskQueueController

@synthesize managedObjectContext;
@synthesize networkController;
@synthesize dataController;

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
	// get that particular channel
	[self issueGetSubscribedChannels];
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

- (void)issueChannelSearchForKeyword:(NSString *)aKeyword {
	NMGetChannelsTask * task = [[NMGetChannelsTask alloc] initSearchChannelWithKeyword:aKeyword];
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

- (void)issueShare:(BOOL)share video:(NMVideo *)aVideo duration:(NSInteger)vdur elapsedSeconds:(NSInteger)sec {
	NMEventType t = share ? NMEventShare : NMEventUnfavorite;
	NMEventTask * task = [[NMEventTask alloc] initWithEventType:t forVideo:aVideo];
//	task.duration = vdur;
	task.elapsedSeconds = sec;
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueSendViewEventForVideo:(NMVideo *)aVideo duration:(NSInteger)vdur elapsedSeconds:(NSInteger)sec playedToEnd:(BOOL)aEnd {
	NMEventTask * task = [[NMEventTask alloc] initWithEventType:NMEventView forVideo:aVideo];
//	task.duration = vdur;
	task.playedToEnd = aEnd;
	// how long the user has watched a video
	task.elapsedSeconds = sec;
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

@end
