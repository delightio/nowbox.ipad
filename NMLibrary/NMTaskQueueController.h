//
//  NMTaskQueueController.h
//  Nowmov
//
//  Created by Bill So on 05/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//


@class NMNetworkController;
@class NMDataController;
@class NMCategory;
@class NMChannel;
@class NMVideo;
@class NMVideoDetail;
@class NMRefreshChannelVideoListTask;
@class NMImageDownloadTask;

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

// Category
- (void)issueGetFeaturedCategories;
- (void)issueGetChannelsForCategory:(NMCategory *)aCat;
- (void)issueChannelSearchForKeyword:(NSString *)aKeyword;
// Channel
- (void)issueGetChannels;
- (void)issueGetLiveChannel;
- (void)issueGetVideoListForChannel:(NMChannel *)chnObj;
- (void)issueGetVideoListForChannel:(NMChannel *)chnObj numberOfVideos:(NSUInteger)numVid;
- (void)issueRefreshVideoListForChannel:(NMChannel *)chnObj delegate:(id <NMVideoListUpdateDelegate>)del;
- (NMImageDownloadTask *)issueGetThumbnailForChannel:(NMChannel *)chnObj;
// Channel subscription
- (void)issueSubscribe:(BOOL)aSubscribe channel:(NMChannel *)chnObj;

// Video
- (void)issueGetDirectURLForVideo:(NMVideo *)aVideo;
- (NMImageDownloadTask *)issueGetThumbnailForAuthor:(NMVideoDetail *)dtlObj;
// Watch later
- (void)issueWatchLater:(BOOL)enqueue video:(NMVideo *)aVideo;

// Event tracking
- (void)issueSendUpVoteEventForVideo:(NMVideo *)aVideo duration:(CGFloat)vdur elapsedSeconds:(CGFloat)sec;
- (void)issueSendDownVoteEventForVideo:(NMVideo *)aVideo duration:(CGFloat)vdur elapsedSeconds:(CGFloat)sec;
- (void)issueSendShareEventForVideo:(NMVideo *)aVideo duration:(CGFloat)vdur elapsedSeconds:(CGFloat)sec;
- (void)issueSendViewEventForVideo:(NMVideo *)aVideo duration:(CGFloat)vdur elapsedSeconds:(CGFloat)sec playedToEnd:(BOOL)aEnd;
//- (void)issueSendViewingEventForVideo:(NMVideo *)aVideo duration:(CGFloat)vdur elapsedSeconds:(CGFloat)sec;
- (void)issueExamineVideo:(NMVideo *)aVideo errorCode:(NSInteger)err;

@end
