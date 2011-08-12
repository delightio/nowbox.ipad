//
//  NMDataController.h
//  Nowmov
//
//  Created by Bill So on 05/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTask.h"

@class NMCategory;
@class NMChannel;
@class NMVideo;
@class NMVideoDetail;

@interface NMDataController : NSObject {
	NSNotificationCenter * notificationCenter;
	NSOperationQueue * operationQueue;
	
	NSManagedObjectContext * managedObjectContext;
	NSPredicate * channelNamePredicateTemplate;
	NSPredicate * channelNamesPredicateTemplate;
	
	NSArray * sortedVideoList;
	NMChannel * trendingChannel;
}

@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NSArray * sortedVideoList;
@property (nonatomic, readonly) NMChannel * trendingChannel;
@property (nonatomic, readonly) NSArray * categories;

- (void)createDataParsingOperationForTask:(NMTask *)atask;

// general data manipulation
- (void)deleteManagedObjects:(id<NSFastEnumeration>)objs;
- (void)deleteVideoInChannel:(NMChannel *)chnObj;
- (void)deleteVideoInChannel:(NMChannel *)chnObj exceptVideo:(NMVideo *)aVideo;
- (void)deleteVideoInChannel:(NMChannel *)chnObj afterVideo:(NMVideo *)aVideo;
- (void)deleteAllVideos;
// category
- (NMCategory *)insertNewCategory;
// channels
- (NMChannel *)insertNewChannel;
- (NSDictionary *)fetchChannelsForNames:(NSArray *)channelAy;
- (BOOL)emptyChannel;
// video
- (NMVideo *)insertNewVideo;
- (NMVideoDetail *)insertNewVideoDetail;
- (NSArray *)sortedVideoListForChannel:(NMChannel *)chn;
//- (NSArray *)sortedLiveChannelVideoList;

@end
