//
//  NMTaskQueueController.h
//  Nowmov
//
//  Created by Bill So on 05/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//


@class NMNetworkController;
@class NMDataController;
@class NMChannel;
@class NMVideo;
@class NMRefreshChannelVideoListTask;

@protocol NMVideoListUpdateDelegate <NSObject>

- (BOOL)task:(NMRefreshChannelVideoListTask *)vidListTask shouldBeginPlaybackSafeUpdateForChannel:(NMChannel *)chnl;
- (NMVideo *)currentVideoForTask:(NMRefreshChannelVideoListTask *)vidListTask;
- (void)taskBeginPlaybackSafeUpdate:(NMRefreshChannelVideoListTask *)vidListTask;
- (void)taskEndPlaybackSafeUpate:(NMRefreshChannelVideoListTask *)vidListTask;

@end

@interface NMTaskQueueController : NSObject {
	NSManagedObjectContext * managedObjectContext;
	
	NMNetworkController * networkController;
	NMDataController * dataController;
}

@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, readonly) NMNetworkController * networkController;
@property (nonatomic, readonly) NMDataController * dataController;

+ (NMTaskQueueController *)sharedTaskQueueController;

- (void)cancelAllPlaybackTasksForChannel:(NMChannel *)chnObj;

// Channel
- (void)issueGetChannels;
- (void)issueGetLiveChannel;
- (void)issueGetVideoListForChannel:(NMChannel *)chnObj;
- (void)issueGetVideoListForChannel:(NMChannel *)chnObj numberOfVideos:(NSUInteger)numVid;
- (void)issueRefreshVideoListForChannel:(NMChannel *)chnObj delegate:(id <NMVideoListUpdateDelegate>)del;
- (void)issueGetThumbnailForChannel:(NMChannel *)chnObj;

// Video
- (void)issueGetDirectURLForVideo:(NMVideo *)aVideo;
//- (void)issueGetVideoInfo:(NMVideo *)aVideo;

// Event tracking
- (void)issueSendUpVoteEventForVideo:(NMVideo *)aVideo duration:(CGFloat)vdur elapsedSeconds:(CGFloat)sec;
- (void)issueSendDownVoteEventForVideo:(NMVideo *)aVideo duration:(CGFloat)vdur elapsedSeconds:(CGFloat)sec;
- (void)issueSendShareEventForVideo:(NMVideo *)aVideo duration:(CGFloat)vdur elapsedSeconds:(CGFloat)sec;
- (void)issueSendViewEventForVideo:(NMVideo *)aVideo duration:(CGFloat)vdur elapsedSeconds:(CGFloat)sec playedToEnd:(BOOL)aEnd;
- (void)issueSendViewingEventForVideo:(NMVideo *)aVideo duration:(CGFloat)vdur elapsedSeconds:(CGFloat)sec;

@end
