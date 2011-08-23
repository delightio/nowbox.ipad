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
	NSPredicate * subscribedChannelsPredicate;
	NSPredicate * objectForIDPredicateTemplate;
	
	// entity object
	NSEntityDescription * channelEntityDescription, * videoEntityDescription;
	
	// Core data query cache. Cache recent core data search result.
	NSMutableDictionary * categoryCacheDictionary, * channelCacheDictionary;
	
	NMChannel * trendingChannel;
	
	// for channel search
	// the category object that contains all search result
	NMCategory * internalSearchCategory;
	// The predicate used by FRC in table view to filter a list of current search result
	NSPredicate * searchResultsPredicate;
	
	// internal channels
	NMChannel * myQueueChannel, * favoriteVideoChannel;
}

@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NSEntityDescription * channelEntityDescription;
@property (nonatomic, retain) NSEntityDescription * videoEntityDescription;
@property (nonatomic, retain) NSMutableDictionary * categoryCacheDictionary;
@property (nonatomic, retain) NMCategory * internalSearchCategory;
@property (nonatomic, readonly) NSPredicate * searchResultsPredicate;
@property (nonatomic, readonly) NMChannel * trendingChannel;
@property (nonatomic, readonly) NSArray * subscribedChannels;
@property (nonatomic, readonly) NSArray * categories;
@property (nonatomic, retain) NMChannel * myQueueChannel;
@property (nonatomic, retain) NMChannel * favoriteVideoChannel;

- (void)createDataParsingOperationForTask:(NMTask *)atask;

// first launch
- (void)setUpDatabaseForFirstLaunch;
// session management
- (void)deleteVideosWithSessionID:(NSInteger)sid;
- (void)resetAllChannelsPageNumber;
// general data manipulation
- (void)deleteManagedObjects:(id<NSFastEnumeration>)objs;
- (void)deleteVideoInChannel:(NMChannel *)chnObj;
- (void)deleteVideoInChannel:(NMChannel *)chnObj exceptVideo:(NMVideo *)aVideo;
- (void)deleteVideoInChannel:(NMChannel *)chnObj afterVideo:(NMVideo *)aVideo;
- (void)deleteAllVideos;
// search
- (void)clearSearchResultCache;
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
