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
//	NSPredicate * channelNamePredicateTemplate;
//	NSPredicate * channelNamesPredicateTemplate;
	NSPredicate * subscribedChannelsPredicate;
	NSPredicate * objectForIDPredicateTemplate;
	
	// Core data query cache. Cache recent core data search result.
	NSMutableDictionary * categoryCacheDictionary, * channelCacheDictionary;
	
	NSArray * sortedVideoList;
	NMChannel * trendingChannel;
	
	// for channel search
	NMCategory * internalSearchCategory;
	NSPredicate * searchResultsPredicate;
}

@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NSMutableDictionary * categoryCacheDictionary;
@property (nonatomic, readonly) NMCategory * internalSearchCategory;
@property (nonatomic, readonly) NSPredicate * searchResultsPredicate;
@property (nonatomic, retain) NSArray * sortedVideoList;
@property (nonatomic, readonly) NMChannel * trendingChannel;
@property (nonatomic, readonly) NSArray * subscribedChannels;
@property (nonatomic, readonly) NSArray * categories;

- (void)createDataParsingOperationForTask:(NMTask *)atask;

// general data manipulation
- (void)deleteManagedObjects:(id<NSFastEnumeration>)objs;
- (void)deleteVideoInChannel:(NMChannel *)chnObj;
- (void)deleteVideoInChannel:(NMChannel *)chnObj exceptVideo:(NMVideo *)aVideo;
- (void)deleteVideoInChannel:(NMChannel *)chnObj afterVideo:(NMVideo *)aVideo;
- (void)deleteAllVideos;
// category
//- (NMCategory *)insertNewCategory;
- (NMCategory *)insertNewCategoryForID:(NSNumber *)catID;
- (NMCategory *)categoryForID:(NSNumber *)catID;
// channels
//- (NMChannel *)insertNewChannel;
- (NMChannel *)insertNewChannelForID:(NSNumber *)chnID;
//- (NSDictionary *)fetchChannelsForNames:(NSArray *)channelAy;
- (NMChannel *)channelForID:(NSNumber *)chnID;
- (BOOL)emptyChannel;
// video
- (NMVideo *)insertNewVideo;
- (NMVideoDetail *)insertNewVideoDetail;
- (NSArray *)sortedVideoListForChannel:(NMChannel *)chn;
- (NMVideo *)videoForID:(NSNumber *)vid;
//- (NSArray *)sortedLiveChannelVideoList;

@end
