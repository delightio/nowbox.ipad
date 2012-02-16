//
//  NMDataController.h
//  Nowmov
//
//  Created by Bill So on 05/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTask.h"
#import <Accounts/Accounts.h>

@class NMCategory;
@class NMChannel;
@class NMChannelDetail;
@class NMPreviewThumbnail;
@class NMVideo;
@class NMVideoDetail;
@class NMConcreteVideo;
@class NMAuthor;
@class NMSubscription;
@class NMPersonProfile;
@class NMFacebookInfo;
@class NMFacebookComment;

@interface NMDataController : NSObject {
	NSNotificationCenter * notificationCenter;
	NSOperationQueue * operationQueue;
	
	NSManagedObjectContext * managedObjectContext;
	// entity object
	NSEntityDescription * channelEntityDescription, * videoEntityDescription, * authorEntityDescription, * subscriptionEntityDescription;
	
	// Core data query cache. Cache recent core data search result. The cache is for reducing number of database access round trips. Simple cache policy - first in first out.
	NSMutableDictionary * categoryCacheDictionary, * channelCacheDictionary;
	
	NSArray * lastSessionVideoIDs;
	
	// for channel search
	// the category object that contains all search result
	NMCategory * internalSearchCategory;
	// The predicate used by FRC in table view to filter a list of current search result
	NSPredicate * searchResultsPredicate;
	
	// for onboard process use only. Temporarily store a channel obtained from YouTube sync to this category for displaying the reason appropriately in the onboard process UI
	NMCategory * internalYouTubeCategory;
	
	// internal channels
	NMChannel * myQueueChannel, * favoriteVideoChannel;
	NMChannel * userTwitterStreamChannel, * userFacebookStreamChannel;
}

@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NSEntityDescription * channelEntityDescription;
@property (nonatomic, retain) NSEntityDescription * videoEntityDescription;
@property (nonatomic, retain) NSEntityDescription * authorEntityDescription;
@property (nonatomic, retain) NSEntityDescription * subscriptionEntityDescription;
@property (nonatomic, retain) NSMutableDictionary * categoryCacheDictionary;
@property (nonatomic, retain) NMChannel * userTwitterStreamChannel;
@property (nonatomic, retain) NMChannel * userFacebookStreamChannel;
@property (nonatomic, retain) NMCategory * internalSearchCategory;
@property (nonatomic, readonly) NSPredicate * searchResultsPredicate;
@property (nonatomic, retain) NMCategory * internalYouTubeCategory;
@property (nonatomic, readonly) NSArray * subscribedChannels;	// for debug purpose
@property (nonatomic, readonly) NSArray * categories;
@property (nonatomic, retain) NSArray * lastSessionVideoIDs;
@property (nonatomic, retain) NMChannel * myQueueChannel;
@property (nonatomic, retain) NMChannel * favoriteVideoChannel;
@property (nonatomic, retain) NSPredicate * pendingImportVideoPredicate;
@property (nonatomic, retain) NSPredicate * pendingImportPredicate;
@property (nonatomic, retain) NSPredicate * subscribedChannelsPredicate;
@property (nonatomic, retain) NSPredicate * socialChannelsToSyncPredicate;
@property (nonatomic, retain) NSPredicate * objectForIDPredicateTemplate;
@property (nonatomic, retain) NSPredicate * videoInChannelPredicateTemplate;
@property (nonatomic, retain) NSPredicate * channelPredicateTemplate;
@property (nonatomic, retain) NSPredicate * channelAndSessionPredicateTemplate;
@property (nonatomic, retain) NSPredicate * cachedChannelsPredicate;
@property (nonatomic, retain) NSPredicate * concreteVideoForIDPredicateTemplate;
@property (nonatomic, retain) NSPredicate * concreteVideoForExternalIDPredicateTemplate;
@property (nonatomic, retain) NSPredicate * usernamePredicateTemplate;
@property (nonatomic, retain) NSPredicate * usernameOrIDPredicateTemplate;

- (void)createDataParsingOperationForTask:(NMTask *)atask;

// first launch
- (void)setUpDatabaseForFirstLaunch;
- (void)resetDatabase;
// session management
- (void)deleteVideosWithSessionID:(NSInteger)sid;
- (void)resetAllChannelsPageNumber;
// general data manipulation
- (void)deleteManagedObjects:(id<NSFastEnumeration>)objs;
- (void)deleteManagedObject:(NSManagedObject *)mObj;
// search
- (void)clearSearchResultCache;

// category
- (NMCategory *)insertNewCategoryForID:(NSNumber *)catID;
- (NMCategory *)categoryForID:(NSNumber *)catID;
- (void)batchDeleteCategories:(NSArray *)catAy;

// channels
- (NMChannel *)insertNewChannelForID:(NSNumber *)chnID;
//- (NMChannel *)insertChannelWithAccount:(ACAccount *)anAccount;
- (NMChannelDetail *)insertNewChannelDetail;
- (NMPreviewThumbnail *)insertNewPreviewThumbnail;
- (NMChannel *)channelForID:(NSNumber *)chnID;
- (NMChannel *)previousChannel:(NMChannel *)srcChn;
- (NMChannel *)nextChannel:(NMChannel *)srcChn;
- (NSArray *)hiddenSubscribedChannels;
- (NMChannel *)lastSessionChannel;
- (void)permanentDeleteMarkedChannels;
- (NSInteger)maxSubscriptionSortOrder;
- (void)updateChannelHiddenStatus:(NMChannel *)chnObj;
- (void)updateFavoriteChannelHideStatus;
- (void)markChannelDeleteStatus:(NMChannel *)chnObj;
- (void)markChannelDeleteStatusForID:(NSInteger)chnID;
- (void)bulkMarkChannelsDeleteStatus:(NSArray *)chnAy;
- (BOOL)channelContainsVideo:(NMChannel *)chnObj;
- (NSArray *)channelsNeverPopulatedBefore;
- (NSArray *)socialChannelsForSync;
- (void)clearChannelCache;

// channel detail
- (NSArray *)previewsForChannel:(NMChannel *)chnObj;

// video
//- (NMVideo *)video:(NMVideo *)vid inChannel:(NMChannel *)chnObj;
- (NMVideo *)relateChannel:(NMChannel *)chnObj withVideo:(NMVideo *)vid;
- (void)unrelateChannel:(NMChannel *)chnObj withVideo:(NMVideo *)vid;
//- (NMVideo *)duplicateVideo:(NMVideo *)srcVideo;
- (NMVideo *)insertNewVideo;
- (NMConcreteVideo *)insertNewConcreteVideo;
- (NMVideoDetail *)insertNewVideoDetail;
- (NSArray *)sortedVideoListForChannel:(NMChannel *)chn;
- (NSArray *)pendingImportVideosForChannel:(NMChannel *)chn;
- (NSArray *)videosForSync:(NSUInteger)numVdo;
- (NMVideo *)videoForID:(NSNumber *)vid;
- (NMVideo *)lastSessionVideoForChannel:(NMChannel *)chn;
- (void)deleteVideo:(NMVideo *)vidObj;
- (void)batchDeleteVideos:(NSSet *)vdoSet;
//- (void)deleteVideoWithID:(NSNumber *)vid fromChannel:(NMChannel *)chn;
- (void)batchUpdateVideoWithID:(NSNumber *)vid forValue:(id)val key:(NSString *)akey;
- (NSInteger)maxVideoSortOrderInChannel:(NMChannel *)chn sessionOnly:(BOOL)flag;
- (NMVideoExistenceCheckResult)videoExistsWithID:(NSNumber *)vid orExternalID:(NSString *)extID channel:(NMChannel *)chn targetVideo:(NMConcreteVideo **)outRealVdo;
- (NMVideoExistenceCheckResult)videoExistsWithExternalID:(NSString *)anExtID channel:(NMChannel *)chn targetVideo:(NMConcreteVideo **)outRealVdo;

// video facebook info
- (NMFacebookInfo *)insertNewFacebookInfo;
- (NMFacebookComment *)insertNewFacebookComment;
- (void)deleteFacebookCacheForLogout;

// author
- (NMAuthor *)authorForID:(NSNumber *)authID orName:(NSString *)aName;
- (NMAuthor *)insertNewAuthor;
- (NMAuthor *)insertNewAuthorWithUsername:(NSString *)aName isNew:(BOOL *)isNewObj;

// Person profile and subscription
- (NMPersonProfile *)insertNewPersonProfileWithID:(NSString *)strID isNew:(BOOL *)isNewObj;
- (NMPersonProfile *)insertNewPersonProfileWithAccountIdentifier:(NSString *)strID isNew:(BOOL *)isNewObj;
- (NSArray *)personProfilesForSync:(NSInteger)aCount;
- (NSInteger)maxPersonProfileID;
- (NMChannel *)subscribeUserChannelWithPersonProfile:(NMPersonProfile *)aProfile;
- (void)subscribeChannel:(NMChannel *)chn;
- (NSArray *)allSubscriptions;
- (NSUInteger)numberOfSubscriptions;

/*!
 Used in Feature Debug Panel. Get the first person without subscription so that the test method there can subscribe to that method.
 */
- (NMPersonProfile *)firstAvailablePersonProfile;

@end
