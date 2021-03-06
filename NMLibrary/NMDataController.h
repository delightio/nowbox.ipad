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
	NSPredicate * cachedChannelsPredicate;
	
	// entity object
	NSEntityDescription * channelEntityDescription, * videoEntityDescription;
	
	// Core data query cache. Cache recent core data search result. The cache is for reducing number of database access round trips. Simple cache policy - first in first out.
	NSMutableDictionary * categoryCacheDictionary, * channelCacheDictionary;
	
	NSArray * lastSessionVideoIDs;
	
	// for channel search
	// the category object that contains all search result
	NMCategory * internalSearchCategory;
	// The predicate used by FRC in table view to filter a list of current search result
	NSPredicate * searchResultsPredicate;
	
	// all subscribed channels should belong to this category
	NMCategory * internalSubscribedChannelsCategory;
	// for onboard process use only. Temporarily store a channel obtained from YouTube sync to this category for displaying the reason appropriately in the onboard process UI
	NMCategory * internalYouTubeCategory;
	
	// internal channels
	NMChannel * myQueueChannel, * favoriteVideoChannel;
	NMChannel * userTwitterStreamChannel, * userFacebookStreamChannel;
}

@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NSEntityDescription * channelEntityDescription;
@property (nonatomic, retain) NSEntityDescription * videoEntityDescription;
@property (nonatomic, retain) NSMutableDictionary * categoryCacheDictionary;
@property (nonatomic, retain) NMChannel * userTwitterStreamChannel;
@property (nonatomic, retain) NMChannel * userFacebookStreamChannel;
@property (nonatomic, retain) NMCategory * internalSearchCategory;
@property (nonatomic, readonly) NSPredicate * searchResultsPredicate;
@property (nonatomic, retain) NMCategory * internalSubscribedChannelsCategory;
@property (nonatomic, retain) NMCategory * internalYouTubeCategory;
@property (nonatomic, readonly) NSArray * subscribedChannels;	// for debug purpose
@property (nonatomic, readonly) NSArray * categories;
@property (nonatomic, retain) NSArray * lastSessionVideoIDs;
@property (nonatomic, retain) NMChannel * myQueueChannel;
@property (nonatomic, retain) NMChannel * favoriteVideoChannel;

- (void)createDataParsingOperationForTask:(NMTask *)atask;

// first launch
- (void)setUpDatabaseForFirstLaunch;
- (void)resetDatabase;
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
//- (void)batchDeleteChannels:(NSArray *)chnAy;
//- (void)batchDeleteChannelForIDs:(NSArray *)idAy;
- (void)permanentDeleteMarkedChannels;
- (NSInteger)maxChannelSortOrder;
- (void)updateChannelHiddenStatus:(NMChannel *)chnObj;
- (void)updateFavoriteChannelHideStatus;
- (void)markChannelDeleteStatus:(NMChannel *)chnObj;
- (void)markChannelDeleteStatusForID:(NSInteger)chnID;
- (void)bulkMarkChannelsDeleteStatus:(NSArray *)chnAy;
- (BOOL)channelContainsVideo:(NMChannel *)chnObj;
- (NSArray *)channelsNeverPopulatedBefore;
- (NMChannel *)channelNextTo:(NMChannel *)anotherChannel;
- (void)clearChannelCache;
// channel detail
- (NSArray *)previewsForChannel:(NMChannel *)chnObj;
// video
- (NMVideo *)video:(NMVideo *)vid inChannel:(NMChannel *)chnObj;
- (NMVideo *)duplicateVideo:(NMVideo *)srcVideo;
- (NMVideo *)insertNewVideo;
- (NMVideoDetail *)insertNewVideoDetail;
- (NSArray *)sortedVideoListForChannel:(NMChannel *)chn;
- (NMVideo *)videoForID:(NSNumber *)vid;
- (NMVideo *)lastSessionVideoForChannel:(NMChannel *)chn;
- (NMVideo *)newestVideoForChannel:(NMChannel *)chn;
- (void)deleteVideo:(NMVideo *)vidObj;
- (void)batchDeleteVideos:(NSSet *)vdoSet;
- (void)deleteVideoWithID:(NSNumber *)vid fromChannel:(NMChannel *)chn;
- (void)batchUpdateVideoWithID:(NSNumber *)vid forValue:(id)val key:(NSString *)akey;
- (NSInteger)maxVideoSortOrderInChannel:(NMChannel *)chn sessionOnly:(BOOL)flag;

@end
