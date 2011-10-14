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
@class NMChannelDetail;
@class NMPreviewThumbnail;
@class NMVideo;
@class NMVideoDetail;

@interface NMDataController : NSObject {
	NSNotificationCenter * notificationCenter;
	NSOperationQueue * operationQueue;
	
	NSManagedObjectContext * managedObjectContext;
	NSPredicate * subscribedChannelsPredicate;
	NSPredicate * objectForIDPredicateTemplate;
	NSPredicate * videoInChannelPredicateTemplate;
	NSPredicate * channelPredicateTemplate;
	NSPredicate * channelAndSessionPredicateTemplate;
	
	// entity object
	NSEntityDescription * channelEntityDescription, * videoEntityDescription;
	
	// Core data query cache. Cache recent core data search result.
	NSMutableDictionary * categoryCacheDictionary, * channelCacheDictionary;
	
//	NMChannel * trendingChannel;
	NSArray * lastSessionVideoIDs;
	
	// for channel search
	// the category object that contains all search result
	NMCategory * internalSearchCategory;
	// The predicate used by FRC in table view to filter a list of current search result
	NSPredicate * searchResultsPredicate;
	
	// all subscribed channels should belong to this category
	NMCategory * internalSubscribedChannelsCategory;
	
	// internal channels
	NMChannel * myQueueChannel, * favoriteVideoChannel;
}

@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NSEntityDescription * channelEntityDescription;
@property (nonatomic, retain) NSEntityDescription * videoEntityDescription;
@property (nonatomic, retain) NSMutableDictionary * categoryCacheDictionary;
@property (nonatomic, retain) NMCategory * internalSearchCategory;
@property (nonatomic, readonly) NSPredicate * searchResultsPredicate;
@property (nonatomic, retain) NMCategory * internalSubscribedChannelsCategory;
//@property (nonatomic, readonly) NMChannel * trendingChannel;
@property (nonatomic, readonly) NSArray * subscribedChannels;	// for debug purpose
@property (nonatomic, readonly) NSArray * categories;
@property (nonatomic, retain) NSArray * lastSessionVideoIDs;
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
// search
- (void)clearSearchResultCache;
// category
- (NMCategory *)insertNewCategoryForID:(NSNumber *)catID;
- (NMCategory *)categoryForID:(NSNumber *)catID;
- (void)batchDeleteCategories:(NSArray *)catAy;
// channels
- (NMChannel *)insertNewChannelForID:(NSNumber *)chnID;
- (NMChannelDetail *)insertNewChannelDetail;
- (NMPreviewThumbnail *)insertNewPreviewThumbnail;
- (NMChannel *)channelForID:(NSNumber *)chnID;
- (NSArray *)hiddenSubscribedChannels;
- (NMChannel *)lastSessionChannel;
- (void)batchDeleteChannels:(NSArray *)chnAy;
- (void)batchDeleteChannelForIDs:(NSArray *)idAy;
- (NSInteger)maxChannelSortOrder;
- (void)updateMyQueueChannelHideStatus;
- (void)updateFavoriteChannelHideStatus;
- (BOOL)channelContainsVideo:(NMChannel *)chnObj;
// video
- (NMVideo *)duplicateVideo:(NMVideo *)srcVideo;
- (NMVideo *)insertNewVideo;
- (NMVideoDetail *)insertNewVideoDetail;
- (NSArray *)sortedVideoListForChannel:(NMChannel *)chn;
- (NMVideo *)videoForID:(NSNumber *)vid;
- (NMVideo *)lastSessionVideoForChannel:(NMChannel *)chn;
- (void)deleteVideo:(NMVideo *)vidObj;
- (void)batchDeleteVideos:(NSSet *)vdoSet;
- (void)deleteVideoWithID:(NSNumber *)vid fromChannel:(NMChannel *)chn;
- (void)batchUpdateVideoWithID:(NSNumber *)vid forValue:(id)val key:(NSString *)akey;
- (NSInteger)maxVideoSortOrderInChannel:(NMChannel *)chn sessionOnly:(BOOL)flag;

@end
