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
#import "NMVideo.h"
#import "NMVideoDetail.h"

NSInteger NM_USER_ACCOUNT_ID			= 0;
NSNumber * NM_SESSION_ID				= nil;
BOOL NM_USE_HIGH_QUALITY_VIDEO			= YES;

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
	[managedObjectContext release];
	[dataController release];
	[networkController release];
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
	NM_SESSION_ID = [NSNumber numberWithInteger:sid];
	// delete expired videos
	[dataController deleteVideosWithSessionID:sessionID - 2];
	// update all page number
	[dataController resetAllChannelsPageNumber];
}

#pragma mark Queue tasks to network controller
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

- (void)issueGetChannels {
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

- (void)issueGetVideoListForChannel:(NMChannel *)chnObj {
#if (defined DEBUG_PLAYER_DEBUG_MESSAGE || defined DEBUG_VIDEO_LIST_REFRESH)
	NSLog(@"get video list - %@ %@", chnObj.title, chnObj.nm_id);
#endif
	// if it's a new channel, we should have special handling on fail
	NMGetChannelVideoListTask * task = [[NMGetChannelVideoListTask alloc] initWithChannel:chnObj];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueGetMoreVideoForChannel:(NMChannel *)chnObj {
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

- (void)issueGetLiveChannel {
	NMGetChannelVideoListTask * task = [[NMGetChannelVideoListTask alloc] init];
	[networkController addNewConnectionForTask:task];
	[task release];
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
		[task release];
	}
	return task;
}

- (NMImageDownloadTask *)issueGetThumbnailForChannel:(NMChannel *)chnObj {
	NMImageDownloadTask * task = nil;
	if ( chnObj.thumbnail_uri ) {
		task = [[NMImageDownloadTask alloc] initWithChannel:chnObj];
		[networkController addNewConnectionForTask:task];
		[task release];
	}
	return task;
}

- (void)issueSubscribe:(BOOL)aSubscribe channel:(NMChannel *)chnObj {
	NMEventTask * task = [[NMEventTask alloc] initWithChannel:chnObj subscribe:aSubscribe];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueSendShareEventForVideo:(NMVideo *)aVideo duration:(CGFloat)vdur elapsedSeconds:(CGFloat)sec {
	NMEventTask * task = [[NMEventTask alloc] initWithEventType:NMEventShare forVideo:aVideo];
//	task.duration = vdur;
	task.elapsedSeconds = sec;
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueSendViewEventForVideo:(NMVideo *)aVideo duration:(CGFloat)vdur elapsedSeconds:(CGFloat)sec playedToEnd:(BOOL)aEnd {
	NMEventTask * task = [[NMEventTask alloc] initWithEventType:NMEventView forVideo:aVideo];
//	task.duration = vdur;
	task.playedToEnd = aEnd;
	// how long the user has watched a video
	task.elapsedSeconds = sec;
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueExamineVideo:(NMVideo *)aVideo errorCode:(NSInteger)err {
	NMEventTask * task = [[NMEventTask alloc] initWithEventType:NMEventExamine forVideo:aVideo];
	task.errorCode = err;
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueEnqueue:(BOOL)shouldQueue video:(NMVideo *)aVideo {
	NMEventType t = shouldQueue ? NMEventEnqueue : NMEventDequeue;
	NMEventTask * task = [[NMEventTask alloc] initWithEventType:t forVideo:aVideo];
	[networkController addNewConnectionForTask:task];
	[task release];
}

@end
