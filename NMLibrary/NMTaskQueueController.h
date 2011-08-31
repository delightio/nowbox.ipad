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
@class NMImageDownloadTask;

@interface NMTaskQueueController : NSObject {
	NSManagedObjectContext * managedObjectContext;
	NSInteger sessionID;
	
	NMNetworkController * networkController;
	NMDataController * dataController;
}

@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, readonly) NMNetworkController * networkController;
@property (nonatomic, readonly) NMDataController * dataController;

+ (NMTaskQueueController *)sharedTaskQueueController;

- (void)cancelAllPlaybackTasksForChannel:(NMChannel *)chnObj;

// Session management
- (void)beginNewSession:(NSInteger)sid;
// Category
- (void)issueGetFeaturedCategories;
- (void)issueGetChannelsForCategory:(NMCategory *)aCat;
- (void)issueChannelSearchForKeyword:(NSString *)aKeyword;
// Channel
- (void)issueGetSubscribedChannels;
- (void)issueGetLiveChannel;
- (void)issueGetVideoListForChannel:(NMChannel *)chnObj;
- (void)issueGetMoreVideoForChannel:(NMChannel *)chnObj;
- (NMImageDownloadTask *)issueGetThumbnailForChannel:(NMChannel *)chnObj;
// Channel subscription
- (void)issueSubscribe:(BOOL)aSubscribe channel:(NMChannel *)chnObj;

// Video
- (void)issueGetDirectURLForVideo:(NMVideo *)aVideo;
- (NMImageDownloadTask *)issueGetThumbnailForAuthor:(NMVideoDetail *)dtlObj;
- (NMImageDownloadTask *)issueGetThumbnailForVideo:(NMVideo *)vdo;

// Event tracking
// Share video
- (void)issueShare:(BOOL)share video:(NMVideo *)aVideo duration:(NSInteger)vdur elapsedSeconds:(NSInteger)sec;
- (void)issueSendViewEventForVideo:(NMVideo *)aVideo duration:(NSInteger)vdur elapsedSeconds:(NSInteger)sec playedToEnd:(BOOL)aEnd;
- (void)issueExamineVideo:(NMVideo *)aVideo errorCode:(NSInteger)err;
// Watch later
- (void)issueEnqueue:(BOOL)shouldQueue video:(NMVideo *)aVideo;

@end
