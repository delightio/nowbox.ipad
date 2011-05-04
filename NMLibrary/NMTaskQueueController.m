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

static NMTaskQueueController * sharedTaskQueueController_ = nil;

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

#pragma mark Queue tasks to network controller
- (void)issueGetChannels {
	NMGetChannelsTask * task = [[NMGetChannelsTask alloc] init];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueGetVideoListForChannel:(NMChannel *)chnObj {
#ifdef DEBUG_PLAYER_DEBUG_MESSAGE
	NSLog(@"get video list - %@", chnObj.channel_name);
#endif
	// if it's a new channel, we should have special handling on fail
	NMGetChannelVideoListTask * task = [[NMGetChannelVideoListTask alloc] initWithChannel:chnObj];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueGetVideoListForChannel:(NMChannel *)chnObj numberOfVideos:(NSUInteger)numVid {
#ifdef DEBUG_PLAYER_DEBUG_MESSAGE
	NSLog(@"get video list - %@", chnObj.channel_name);
#endif
	NMGetChannelVideoListTask * task = [[NMGetChannelVideoListTask alloc] initWithChannel:chnObj];
	task.numberOfVideoRequested = numVid;
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueGetLiveChannel {
	NMGetChannelVideoListTask * task = [[NMGetChannelVideoListTask alloc] init];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueGetDirectURLForVideo:(NMVideo *)aVideo {
#ifdef DEBUG_PLAYER_DEBUG_MESSAGE
	NSLog(@"resolve direct URL - %@", aVideo.vid);
#endif
	NMGetYouTubeDirectURLTask * task = [[NMGetYouTubeDirectURLTask alloc] initWithVideo:aVideo];
	[networkController addNewConnectionForTask:task];
	[task release];
}

//- (void)issueGetVideoInfo:(NMVideo *)aVideo {
//	NMGetVideoInfoTask * task = [[NMGetVideoInfoTask alloc] initWithVideo:aVideo];
//	[networkController addNewConnectionForTask:task];
//	[task release];
//}

- (void)issueGetThumbnailForChannel:(NMChannel *)chnObj {
	if ( ![networkController downloadInProgressForURLString:chnObj.thumbnail] ) {
		NMImageDownloadTask * task = [[NMImageDownloadTask alloc] initWithChannel:chnObj];
		[networkController addNewConnectionForTask:task];
		[task release];
	}
}

- (void)issueSendUpVoteEventForVideo:(NMVideo *)aVideo duration:(CGFloat)vdur elapsedSeconds:(CGFloat)sec {
	NMEventTask * task = [[NMEventTask alloc] initWithEventType:NMEventUpVote forVideo:aVideo];
	task.duration = vdur;
	task.elapsedSeconds = sec;
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueSendDownVoteEventForVideo:(NMVideo *)aVideo duration:(CGFloat)vdur elapsedSeconds:(CGFloat)sec {
	NMEventTask * task = [[NMEventTask alloc] initWithEventType:NMEventDownVote forVideo:aVideo];
	task.duration = vdur;
	task.elapsedSeconds = sec;
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueSendRewindEventForVideo:(NMVideo *)aVideo duration:(CGFloat)vdur elapsedSeconds:(CGFloat)sec {
	NMEventTask * task = [[NMEventTask alloc] initWithEventType:NMEventRewind forVideo:aVideo];
	task.duration = vdur;
	task.elapsedSeconds = sec;
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueSendShareEventForVideo:(NMVideo *)aVideo duration:(CGFloat)vdur elapsedSeconds:(CGFloat)sec {
	NMEventTask * task = [[NMEventTask alloc] initWithEventType:NMEventShare forVideo:aVideo];
	task.duration = vdur;
	task.elapsedSeconds = sec;
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueSendViewEventForVideo:(NMVideo *)aVideo duration:(CGFloat)vdur elapsedSeconds:(CGFloat)sec playedToEnd:(BOOL)aEnd {
	NMEventTask * task = [[NMEventTask alloc] initWithEventType:NMEventView forVideo:aVideo];
	task.duration = vdur;
	task.playedToEnd = aEnd;
	// how long the user has watched a video
	task.elapsedSeconds = sec;
	[networkController addNewConnectionForTask:task];
	[task release];
}

@end
