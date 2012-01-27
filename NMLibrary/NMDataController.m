//
//  NMDataController.m
//  Nowmov
//
//  Created by Bill So on 05/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMDataController.h"
#import "NMTask.h"
#import "NMCategory.h"
#import "NMChannel.h"
#import "NMVideo.h"
#import "NMConcreteVideo.h"
#import "NMVideoDetail.h"
#import "NMSubscription.h"
#import "NMPersonProfile.h"
#import "NMGetChannelVideoListTask.h"


NSString * const NMCategoryEntityName = @"NMCategory";
NSString * const NMChannelEntityName = @"NMChannel";
NSString * const NMChannelDetailEntityName = @"NMChannelDetail";
NSString * const NMPreviewThumbnailEntityName = @"NMPreviewThumbnail";
NSString * const NMVideoEntityName = @"NMVideo";
NSString * const NMVideoDetailEntityName = @"NMVideoDetail";
NSString * const NMConcreteVideoEntityName = @"NMConcreteVideo";
NSString * const NMAuthorEntityName = @"NMAuthor";
NSString * const NMSubscriptionEntityName = @"NMSubscription";
NSString * const NMPersonProfileEntityName = @"NMPersonProfile";

BOOL NMVideoPlaybackViewIsScrolling = NO;

@implementation NMDataController
@synthesize managedObjectContext;
@synthesize channelEntityDescription, videoEntityDescription;
@synthesize authorEntityDescription;
@synthesize categories, categoryCacheDictionary;
@synthesize subscribedChannels;
@synthesize internalSearchCategory;
@synthesize internalSubscribedChannelsCategory;
@synthesize internalYouTubeCategory;
@synthesize myQueueChannel, favoriteVideoChannel;
@synthesize userFacebookStreamChannel, userTwitterStreamChannel;
@synthesize lastSessionVideoIDs;

- (id)init {
	self = [super init];
	
	operationQueue = [[NSOperationQueue alloc] init];
	notificationCenter = [NSNotificationCenter defaultCenter];
	
	subscribedChannelsPredicate = [[NSPredicate predicateWithFormat:@"nm_subscribed > 0 AND nm_hidden == $HIDDEN"] retain];
	cachedChannelsPredicate = [[NSPredicate predicateWithFormat:@"nm_subscribed <= 0"] retain];
	objectForIDPredicateTemplate = [[NSPredicate predicateWithFormat:@"nm_id == $OBJECT_ID"] retain];
	videoInChannelPredicateTemplate = [[NSPredicate predicateWithFormat:@"video == $VIDEO AND channel == $CHANNEL"] retain];
	channelPredicateTemplate = [[NSPredicate predicateWithFormat:@"channel == $CHANNEL"] retain];
	channelAndSessionPredicateTemplate = [[NSPredicate predicateWithFormat:@"channel == $CHANNEL AND nm_session_id == $SESSION_ID"] retain];
	concreteVideoForIDPredicateTemplate = [[NSPredicate predicateWithFormat:@"video.nm_id = $OBJECT_ID"] retain];
	usernamePredicateTemplate = [[NSPredicate predicateWithFormat:@"username like $USERNAME"] retain];

	categoryCacheDictionary = [[NSMutableDictionary alloc] initWithCapacity:16];
	channelCacheDictionary = [[NSMutableDictionary alloc] initWithCapacity:16];
	
	return self;
}

- (void)dealloc {
	[myQueueChannel release], [favoriteVideoChannel release];
	[userFacebookStreamChannel release], [userTwitterStreamChannel release];
	[lastSessionVideoIDs release];
	[categoryCacheDictionary release];
	[channelCacheDictionary release];
	[subscribedChannelsPredicate release];
	[cachedChannelsPredicate release];
	[objectForIDPredicateTemplate release];
	[videoInChannelPredicateTemplate release];
	[channelPredicateTemplate release];
	[channelAndSessionPredicateTemplate release];
	[concreteVideoForIDPredicateTemplate release];
	[usernamePredicateTemplate release];
	[managedObjectContext release];
	[operationQueue release];
	[internalSearchCategory release];
	[internalSubscribedChannelsCategory release];
	[internalYouTubeCategory release];
	[channelEntityDescription release], [videoEntityDescription release];
	[authorEntityDescription release];
	[super dealloc];
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)context {
	if ( context == managedObjectContext ) return;
	if ( managedObjectContext ) {
		[managedObjectContext release];
	}
	if ( context ) {
		managedObjectContext = [context retain];
		self.channelEntityDescription = [NSEntityDescription entityForName:NMChannelEntityName inManagedObjectContext:managedObjectContext];
		self.videoEntityDescription = [NSEntityDescription entityForName:NMVideoEntityName inManagedObjectContext:managedObjectContext];
		self.authorEntityDescription = [NSEntityDescription entityForName:NMAuthorEntityName inManagedObjectContext:managedObjectContext];
	} else {
		managedObjectContext = nil;
		self.channelEntityDescription = nil;
		self.videoEntityDescription = nil;
		self.authorEntityDescription = nil;
	}
}

#pragma mark First launch
- (void)setUpDatabaseForFirstLaunch {
	// create channels: my queue, favorites
//	[self favoriteVideoChannel];
//	[self myQueueChannel];
	[self internalSearchCategory];
}

- (void)resetDatabase {
	// delete channels
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:channelEntityDescription];
	[request setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObjects:@"videos",@"videos.video", @"videos.video.detail", nil]];
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	for (NMChannel * chnObj in result) {
		[managedObjectContext deleteObject:chnObj];
	}
	[managedObjectContext save:nil];
    [request release];    
}

#pragma mark Session management
- (void)deleteVideosWithSessionID:(NSInteger)sid {
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:videoEntityDescription];
	// nm_session_id <= %@ AND NOT ANY categories = %@
	NSPredicate * thePredicate;
	if ( [lastSessionVideoIDs count] ) {
		thePredicate = [NSPredicate predicateWithFormat:@"nm_session_id < %@ AND NOT channel IN %@ AND NOT (channel.nm_id == %@ AND video.nm_id IN %@)", [NSNumber numberWithInteger:sid], [NSArray arrayWithObjects:self.myQueueChannel, self.favoriteVideoChannel, nil], [NSNumber numberWithInteger:NM_LAST_CHANNEL_ID], lastSessionVideoIDs];
	} else {
		thePredicate = [NSPredicate predicateWithFormat:@"nm_session_id < %@ AND NOT channel IN %@ AND channel.nm_id != %@", [NSNumber numberWithInteger:sid], [NSArray arrayWithObjects:self.myQueueChannel, self.favoriteVideoChannel, nil], [NSNumber numberWithInteger:NM_LAST_CHANNEL_ID]];
	}
	[request setPredicate:thePredicate];
//	[request setPredicate:[NSPredicate predicateWithFormat:@"nm_session_id < %@ AND NOT channel IN %@ AND channel.nm_id != %@", [NSNumber numberWithInteger:sid], [NSArray arrayWithObjects:self.myQueueChannel, self.favoriteVideoChannel, nil], [NSNumber numberWithInteger:NM_LAST_CHANNEL_ID]]];
	[request setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObjects:@"video", @"channel", nil]];
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	
	for (NMVideo * vid in result) {
		[managedObjectContext deleteObject:vid];
	}
	[request release];
	
	// delete videos without parent channel
	request = [[NSFetchRequest alloc] init];
	[request setEntity:videoEntityDescription];
	[request setPredicate:[NSPredicate predicateWithFormat:@"channel = nil"]];
	result = [managedObjectContext executeFetchRequest:request error:nil];
	for (NMVideo * vid in result) {
		[managedObjectContext deleteObject:vid];
	}
	[request release];
	// reset the videos
	if ( [lastSessionVideoIDs count] ) {
		request = [[NSFetchRequest alloc] init];
		[request setEntity:videoEntityDescription];
		thePredicate = [NSPredicate predicateWithFormat:@"NOT (channel.nm_id == %@ AND video.nm_id IN %@)", [NSNumber numberWithInteger:NM_LAST_CHANNEL_ID], lastSessionVideoIDs];
		[request setPredicate:thePredicate];
		[request setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"video"]];
		[request setReturnsObjectsAsFaults:NO];
		result = [managedObjectContext executeFetchRequest:request error:nil];
		for (NMVideo * vid in result) {
			if ( [vid.video.nm_error integerValue] == 0 ) {
				vid.video.nm_playback_status = 0;
				vid.video.nm_direct_url = nil;
				vid.video.nm_direct_sd_url = nil;
			}
		}
		[request release];
	}
}

- (void)resetAllChannelsPageNumber {
	NSArray * subChn = self.subscribedChannels;
	NSNumber * pgNum = [NSNumber numberWithInteger:0];
	for (NMChannel * chnObj in subChn) {
		// reset the page number to 1. Page number always start at 0.
		chnObj.nm_current_page = pgNum;
	}
}

#pragma mark Data Manipulation
- (void)deleteManagedObjects:(id<NSFastEnumeration>)objs {
	for (NSManagedObject * mobj in objs) {
		[managedObjectContext deleteObject:mobj];
	}
}

#pragma mark Search Results Support
- (NMCategory *)internalSearchCategory {
	if ( internalSearchCategory == nil ) {
		// retrieve that category
		NSFetchRequest * request = [[NSFetchRequest alloc] init];
		[request setEntity:[NSEntityDescription entityForName:NMCategoryEntityName inManagedObjectContext:managedObjectContext]];
		NSNumber * searchCatID = [NSNumber numberWithInteger:-1];
		[request setPredicate:[NSPredicate predicateWithFormat:@"nm_id == %@", searchCatID]];
		[request setReturnsObjectsAsFaults:NO];
		NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
		if ( result == nil || [result count] == 0 ) {
			// we need to create the category
			NMCategory * categoryObj = [NSEntityDescription insertNewObjectForEntityForName:NMCategoryEntityName inManagedObjectContext:managedObjectContext];
			categoryObj.title = @"Search Results - internal use only";
			categoryObj.nm_id = searchCatID;
			self.internalSearchCategory = categoryObj;
		} else {
			self.internalSearchCategory = [result objectAtIndex:0];
		}
		[request release];
	}
	return internalSearchCategory;
}

- (NSPredicate *)searchResultsPredicate {
	if ( searchResultsPredicate == nil ) {
		// create the predicate
		searchResultsPredicate = [[NSPredicate predicateWithFormat:@"ANY categories == %@ && nm_id != 0", self.internalSearchCategory] retain];
	}
	return searchResultsPredicate;
}

- (void)clearSearchResultCache {
	// remove relationship
	[internalSearchCategory removeChannels:internalSearchCategory.channels];
}

#pragma mark Categories
- (NSArray *)categories {
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:NMCategoryEntityName inManagedObjectContext:managedObjectContext]];
	[request setReturnsObjectsAsFaults:NO];
	[request setPredicate:[NSPredicate predicateWithFormat:@"nm_id > 0"]];
	
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	[request release];
	
	[categoryCacheDictionary removeAllObjects];
	if ( [result count] ) {
		for (NMCategory * cat in result) {
			[categoryCacheDictionary setObject:cat forKey:cat.nm_id];
		}
		return result;
	}
	return nil;
}

- (NMCategory *)insertNewCategoryForID:(NSNumber *)catID {
	// clean up the cache. categoryCacheDictionary caches objects that do not exist.
	[categoryCacheDictionary removeObjectForKey:catID];
	NMCategory * categoryObj = [NSEntityDescription insertNewObjectForEntityForName:NMCategoryEntityName inManagedObjectContext:managedObjectContext];
	categoryObj.nm_id = catID;
	return categoryObj;
}

//- (NMCategory *)insertNewCategory {
//	NMCategory * categoryObj = [NSEntityDescription insertNewObjectForEntityForName:NMCategoryEntityName inManagedObjectContext:managedObjectContext];
//	return categoryObj;
//}

- (NMCategory *)categoryForID:(NSNumber *)catID {
	id catObj = [categoryCacheDictionary objectForKey:catID];
	if ( catObj ) {
		if ( catObj == [NSNull null] ) return nil;
		return catObj;
	}
	
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:NMCategoryEntityName inManagedObjectContext:managedObjectContext]];
	[request setPredicate:[objectForIDPredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:catID forKey:@"OBJECT_ID"]]];
	[request setReturnsObjectsAsFaults:NO];
	
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	[request release];
	if ( [result count] ) {
		catObj = [result objectAtIndex:0];
		[categoryCacheDictionary setObject:catObj forKey:((NMCategory *)catObj).nm_id];
	} else {
		// this category does not exist in core data
		[categoryCacheDictionary setObject:[NSNull null] forKey:catID];
	}
	// catObj is "automatically" set to nil in objectForKey: call.
	return catObj;
}

- (void)batchDeleteCategories:(NSArray *)catAy {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	// fetch all categories and categories related objects to avoid faulting during delete
	// refer to WWDC 2010 - Session 137 - Optimizing Core Data Performance on iPhone OS
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:NMCategoryEntityName inManagedObjectContext:managedObjectContext]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"SELF in %@", catAy]];
	[request setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObjects:@"channels", @"channels.previewThumbnails", @"channels.detail", nil]];
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	if ( [result count] ) {
		NSManagedObject * mobj;
		for (mobj in result) {
			[managedObjectContext deleteObject:mobj];
		}
	}
	[request release];
	// clean up cache
	[categoryCacheDictionary removeAllObjects];
	[channelCacheDictionary removeAllObjects];
	
	[pool release];
}

- (NMCategory *)internalSubscribedChannelsCategory {
	if ( internalSubscribedChannelsCategory == nil ) {
		// retrieve that category
		NSFetchRequest * request = [[NSFetchRequest alloc] init];
		[request setEntity:[NSEntityDescription entityForName:NMCategoryEntityName inManagedObjectContext:managedObjectContext]];
		NSNumber * searchCatID = [NSNumber numberWithInteger:-2];
		[request setPredicate:[NSPredicate predicateWithFormat:@"nm_id == %@", searchCatID]];
		[request setReturnsObjectsAsFaults:NO];
		NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
		if ( result == nil || [result count] == 0 ) {
			// we need to create the category
			NMCategory * categoryObj = [NSEntityDescription insertNewObjectForEntityForName:NMCategoryEntityName inManagedObjectContext:managedObjectContext];
			categoryObj.title = @"Subscribed Channels - internal use only";
			categoryObj.nm_id = searchCatID;
			self.internalSubscribedChannelsCategory = categoryObj;
		} else {
			self.internalSubscribedChannelsCategory = [result objectAtIndex:0];
		}
		[request release];
	}
	return internalSubscribedChannelsCategory;
}

- (NMCategory *)internalYouTubeCategory {
	if ( internalYouTubeCategory == nil ) {
		// retrieve that category
		NSFetchRequest * request = [[NSFetchRequest alloc] init];
		[request setEntity:[NSEntityDescription entityForName:NMCategoryEntityName inManagedObjectContext:managedObjectContext]];
		NSNumber * searchCatID = [NSNumber numberWithInteger:-3];
		[request setPredicate:[NSPredicate predicateWithFormat:@"nm_id == %@", searchCatID]];
		[request setReturnsObjectsAsFaults:NO];
		NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
		if ( result == nil || [result count] == 0 ) {
			// we need to create the category
			NMCategory * categoryObj = [NSEntityDescription insertNewObjectForEntityForName:NMCategoryEntityName inManagedObjectContext:managedObjectContext];
			categoryObj.title = @"YouTube";
			categoryObj.nm_id = searchCatID;
			self.internalYouTubeCategory = categoryObj;
		} else {
			self.internalYouTubeCategory = [result objectAtIndex:0];
		}
		[request release];
	}
	return internalYouTubeCategory;
}

#pragma mark Channels
- (NMChannel *)insertNewChannelForID:(NSNumber *)chnID {
	// clean up the cache. channelCacheDictionary caches objects that do not exist.
	if ( chnID ) [channelCacheDictionary removeObjectForKey:chnID];
	NMChannel * channelObj = [NSEntityDescription insertNewObjectForEntityForName:NMChannelEntityName inManagedObjectContext:managedObjectContext];
	channelObj.nm_id = chnID;
	return channelObj;
}

- (NMChannel *)insertChannelWithAccount:(ACAccount *)anAccount {
	// check if the channel object exists
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:channelEntityDescription];
	[request setPredicate:[usernamePredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:anAccount.username forKey:@"USERNAME"]]];
	[request setReturnsObjectsAsFaults:NO];
	
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	
	NMChannel * chnObj = nil;
	if ( result && [result count] ) {
		chnObj = [result objectAtIndex:0];
	}
	if ( chnObj == nil ) {
		// create the channel object
		chnObj = [NSEntityDescription insertNewObjectForEntityForName:NMChannelEntityName inManagedObjectContext:managedObjectContext];
		chnObj.title = anAccount.username;
		// it's all Twitter account for iOS 5
		chnObj.type = [NSNumber numberWithInteger:NMChannelUserTwitterType];
		
		[managedObjectContext save:nil];
	}
	[request release];
	return chnObj;
}

- (NSArray *)subscribedChannels {
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:channelEntityDescription];
	[request setReturnsObjectsAsFaults:NO];
	[request setPredicate:[subscribedChannelsPredicate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"HIDDEN"]]];
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	[request release];
	return [result count] ? result : nil;
}

- (NMChannel *)channelForID:(NSNumber *)chnID {
	id chnObj = [channelCacheDictionary objectForKey:chnID];
	if ( chnObj ) {
		if ( chnObj == [NSNull null] ) return nil;
		return chnObj;
	}
	
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:channelEntityDescription];
	[request setPredicate:[objectForIDPredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:chnID forKey:@"OBJECT_ID"]]];
	[request setReturnsObjectsAsFaults:NO];
	
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	[request release];
	
	if ( [result count] ) {
		chnObj = [result objectAtIndex:0];
		[channelCacheDictionary setObject:chnObj forKey:((NMChannel *)chnObj).nm_id];
	} else {
		[channelCacheDictionary setObject:[NSNull null] forKey:chnID];
	}
	// chnObj is "automatically" set to nil in objectForKey: call.
	return chnObj;
}

- (NSArray *)hiddenSubscribedChannels {
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:channelEntityDescription];
	[request setPredicate:[NSPredicate predicateWithFormat:@"nm_subscribed > 0 AND nm_hidden == 0 AND nm_video_last_refresh < %@", [NSDate dateWithTimeIntervalSinceNow:-600]]]; // 10 min
	[request setReturnsObjectsAsFaults:NO];
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
    [request release];    
	return [result count] == 0 ? nil : result;
}

- (NSDictionary *)fetchChannelsForNames:(NSArray *)channelAy {
	// channels are created when the app launch or after sign in. Probably don't need to optimize the operation that much
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:channelEntityDescription];
	[request setReturnsObjectsAsFaults:NO];
//	[request setPredicate:[channelNamesPredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:channelAy forKey:@"NM_CHANNEL_NAMES"]]];
	
	NSError * error = nil;
	NSArray * results = [managedObjectContext executeFetchRequest:request error:&error];
	
	NMChannel * channelObj = nil;
	NSMutableDictionary * dict = nil;
	if ( results && [results count] ) {
		dict = [NSMutableDictionary dictionary];
		for (channelObj in results) {
			[dict setObject:channelObj forKey:channelObj.title];
		}
		[request release];
		return dict;
	}
	
	[request release];
	return nil;
}

- (NMChannel *)lastSessionChannel {
	// fetch last video played
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:channelEntityDescription];
	[request setPredicate:[NSPredicate predicateWithFormat:@"nm_hidden == NO AND nm_subscribed > 0 AND nm_id == %@", [NSNumber numberWithInteger:NM_LAST_CHANNEL_ID]]];
	NSArray * results = [managedObjectContext executeFetchRequest:request error:nil];
	[request release];
	NMChannel * chnObj = nil;
	if ( [results count] ) {
		// return the video object
		chnObj = [results objectAtIndex:0];
	} else {
		// get the first channel
		request = [[NSFetchRequest alloc] init];
		[request setEntity:channelEntityDescription];
		[request setPredicate:[NSPredicate predicateWithFormat:@"nm_hidden == NO AND nm_subscribed > 0 AND nm_id > 0"]];
		NSSortDescriptor * sortDsptr = [[NSSortDescriptor alloc] initWithKey:@"nm_subscribed" ascending:YES];
		[request setSortDescriptors:[NSArray arrayWithObject:sortDsptr]];
		[sortDsptr release];
		[request setFetchLimit:1];
		results = [managedObjectContext executeFetchRequest:request error:nil];
		if ( [results count] ) {
			chnObj = [results objectAtIndex:0];
		} else {
			chnObj = nil;
		}
        [request release];
	}
	return chnObj;
}

- (NMChannel *)channelNextTo:(NMChannel *)anotherChannel {
	if ( anotherChannel == nil ) return nil;
	NMChannel * chnObj;
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:channelEntityDescription];
	[request setPredicate:[NSPredicate predicateWithFormat:@"nm_hidden == NO AND nm_subscribed > %@", anotherChannel.nm_subscribed]];
	NSSortDescriptor * sortDsptr = [[NSSortDescriptor alloc] initWithKey:@"nm_subscribed" ascending:YES];
	[request setSortDescriptors:[NSArray arrayWithObject:sortDsptr]];
	[sortDsptr release];
	[request setFetchLimit:1];
	NSArray * results = [managedObjectContext executeFetchRequest:request error:nil];
	if ( [results count] ) {
		chnObj = [results objectAtIndex:0];
	} else {
		chnObj = nil;
	}
    [request release];
	return chnObj;
}

- (NMChannel *)myQueueChannel {
	if ( myQueueChannel == nil ) {
		NSFetchRequest * request = [[NSFetchRequest alloc] init];
		[request setEntity:channelEntityDescription];
		[request setPredicate:[objectForIDPredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:NM_USER_WATCH_LATER_CHANNEL_ID] forKey:@"OBJECT_ID"]]];
		[request setReturnsObjectsAsFaults:NO];
		NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
		if ( [result count] ) {
			self.myQueueChannel = [result objectAtIndex:0];
		}
		[request release];
	}
	return myQueueChannel;
}

- (NMChannel *)favoriteVideoChannel {
	if ( favoriteVideoChannel == nil ) {
		NSFetchRequest * request = [[NSFetchRequest alloc] init];
		[request setEntity:channelEntityDescription];
		[request setPredicate:[objectForIDPredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:NM_USER_FAVORITES_CHANNEL_ID] forKey:@"OBJECT_ID"]]];
		[request setReturnsObjectsAsFaults:NO];
		NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
		if ( [result count] ) {
			self.favoriteVideoChannel = [result objectAtIndex:0];
		}
		[request release];
	}
	return favoriteVideoChannel;
}

- (NMChannel *)userFacebookStreamChannel {
	if ( NM_USER_FACEBOOK_CHANNEL_ID == 0 ) {
		return nil;
	}
	if ( userFacebookStreamChannel ) return userFacebookStreamChannel;
	NMChannel * chnObj = [self channelForID:[NSNumber numberWithInteger:NM_USER_FACEBOOK_CHANNEL_ID]];
	self.userFacebookStreamChannel = chnObj;
	return chnObj;
}

- (NMChannel *)userTwitterStreamChannel {
	if ( NM_USER_TWITTER_CHANNEL_ID == 0 ) {
		return nil;
	}
	if ( userTwitterStreamChannel ) return userTwitterStreamChannel;
	NMChannel * chnObj = [self channelForID:[NSNumber numberWithInteger:NM_USER_TWITTER_CHANNEL_ID]];
	self.userTwitterStreamChannel = chnObj;
	return chnObj;
}

- (void)permanentDeleteMarkedChannels {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:channelEntityDescription];
	[request setPredicate:[subscribedChannelsPredicate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"HIDDEN"]]];
	[request setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObjects:@"categories", @"videos", nil]];
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	if ( [result count] ) {
		NSManagedObject * mobj;
		for (mobj in result) {
			[managedObjectContext deleteObject:mobj];
		}
	}
	[request release];
	// clean up cache
	[channelCacheDictionary removeAllObjects];
	
	[pool release];
}

- (NMChannelDetail *)insertNewChannelDetail {
	return [NSEntityDescription insertNewObjectForEntityForName:NMChannelDetailEntityName inManagedObjectContext:managedObjectContext];
}

- (NMPreviewThumbnail *)insertNewPreviewThumbnail {
	return [NSEntityDescription insertNewObjectForEntityForName:NMPreviewThumbnailEntityName inManagedObjectContext:managedObjectContext];
}

- (NSInteger)maxChannelSortOrder {
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setResultType:NSDictionaryResultType];
	[request setEntity:channelEntityDescription];
	[request setPredicate:[NSPredicate predicateWithFormat:@"nm_subscribed > 0"]];
	
	NSExpression * keyPathExpression = [NSExpression expressionForKeyPath:@"nm_subscribed"];
	NSExpression * maxSortOrderExpression = [NSExpression expressionForFunction:@"max:" arguments:[NSArray arrayWithObject:keyPathExpression]];
	
	NSExpressionDescription * expressionDescription = [[NSExpressionDescription alloc] init];
	[expressionDescription setName:@"sort_order"];
	[expressionDescription setExpression:maxSortOrderExpression];
	[expressionDescription setExpressionResultType:NSInteger32AttributeType];
	[request setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];
	
	// execute fetch request
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	
	[expressionDescription release];
	[request release];
	
	NSInteger theOrder = 0;
	if ( [result count] ) {
		theOrder = [[[result objectAtIndex:0] valueForKey:@"sort_order"] integerValue];
	}
	return theOrder;
}

- (void)updateChannelHiddenStatus:(NMChannel *)chnObj {
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:videoEntityDescription];
	[request setPredicate:[NSPredicate predicateWithFormat:@"channel == %@ AND video.nm_error == 0", chnObj]];
	[request setFetchLimit:1];
	[request setResultType:NSManagedObjectIDResultType];
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	
	chnObj.nm_hidden = [NSNumber numberWithBool:[result count] == 0];
	[request release];
}

- (void)updateFavoriteChannelHideStatus {
	if ( NM_USER_SHOW_FAVORITE_CHANNEL ) {
		NSFetchRequest * request = [[NSFetchRequest alloc] init];
		[request setEntity:videoEntityDescription];
		[request setPredicate:[NSPredicate predicateWithFormat:@"channel == %@ AND video.nm_error == 0", favoriteVideoChannel]];
		[request setFetchLimit:1];
		[request setResultType:NSManagedObjectIDResultType];
		NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
		favoriteVideoChannel.nm_hidden = [NSNumber numberWithBool:[result count] == 0];
		[request release];
	} else {
		// always hide the channel
		favoriteVideoChannel.nm_hidden = [NSNumber numberWithBool:YES];
	}
}

- (void)markChannelDeleteStatus:(NMChannel *)chnObj {
	chnObj.nm_hidden = [NSNumber numberWithBool:YES];
	[managedObjectContext save:nil];
}

- (void)markChannelDeleteStatusForID:(NSInteger)chnID {
	//TODO: set those channels as hidden for now. Gotta make a special status for "marked as delete"
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:channelEntityDescription];
	// don't need predicate template for now. There's not much performance concern in deleting channel
	[request setPredicate:[objectForIDPredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:chnID] forKey:@"OBJECT_ID"]]];
	[request setReturnsObjectsAsFaults:NO];
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	NSNumber * yesNum = [NSNumber numberWithBool:YES];
	for (NMChannel * chnObj in result) {
		chnObj.nm_hidden = yesNum;
	}
	// save changes
	[managedObjectContext save:nil];
	[request release];
}

- (void)bulkMarkChannelsDeleteStatus:(NSArray *)chnAy {
	NSNumber * yesNum = [NSNumber numberWithBool:YES];
	for (NMChannel * chnObj in chnAy) {
		chnObj.nm_hidden = yesNum;
	}
	[channelCacheDictionary removeAllObjects];
	[managedObjectContext save:nil];
}

- (BOOL)channelContainsVideo:(NMChannel *)chnObj {
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:videoEntityDescription];
	[request setPredicate:[NSPredicate predicateWithFormat:@"channel == %@ AND video.nm_error == 0", chnObj]];
	[request setFetchLimit:1];
	[request setResultType:NSManagedObjectIDResultType];
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	[request release];
	return [result count] > 0;
}

- (NSArray *)channelsNeverPopulatedBefore {
	// get all stream and keyword channels that have never been populated before. The backend needs to poll the server to see if videos are available in those channels
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:channelEntityDescription];
	[request setPredicate:[NSPredicate predicateWithFormat:@"type != %@ AND nm_subscribed > 0 AND populated_at < %@", [NSNumber numberWithInteger:NMChannelUserType], [NSDate dateWithTimeIntervalSince1970:10.0f]]];
	[request setReturnsObjectsAsFaults:NO];
	
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
    [request release];
    
	return [result count] ? result : nil;
}

- (void)clearChannelCache {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:channelEntityDescription];
	[request setPredicate:cachedChannelsPredicate];
	[request setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObjects:@"categories", @"videos", @"previewThumbnails", @"detail", nil]];
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	if ( [result count] ) {
		NMChannel * mobj;
		for (mobj in result) {
			[managedObjectContext deleteObject:mobj];
		}
	}
	[request release];
	// remove categories from subscribed channels. this allows channel management view to always show the progress indicator when loading channels.
	request = [[NSFetchRequest alloc] init];
	[request setEntity:channelEntityDescription];
	[request setPredicate:[subscribedChannelsPredicate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"HIDDEN"]]];
	[request setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObjects:@"categories", nil]];
	result = [managedObjectContext executeFetchRequest:request error:nil];
	if ( [result count] ) {
		NMChannel * mobj;
		for (mobj in result) {
			[mobj removeCategories:mobj.categories];
			// assign the "internal subscribed channels category" relationship back
			[mobj addCategoriesObject:self.internalSubscribedChannelsCategory];
		}
	}
	[request release];
	// reset category
	request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:NMCategoryEntityName inManagedObjectContext:managedObjectContext]];
	[request setReturnsObjectsAsFaults:NO];
	result = [managedObjectContext executeFetchRequest:request error:nil];
	if ( [result count] ) {
		NMCategory * mobj;
		NSDate * unixDate = [NSDate dateWithTimeIntervalSince1970:0.0f];
		for (mobj in result) {
			mobj.nm_last_refresh = unixDate;
		}
	}
	[request release];
	
	// clean up cache
	[channelCacheDictionary removeAllObjects];
	
	[pool release];
}

#pragma mark Channel Preview
- (NSArray *)previewsForChannel:(NMChannel *)chnObj {
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:NMPreviewThumbnailEntityName inManagedObjectContext:managedObjectContext]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"channel == %@", chnObj]];
	NSSortDescriptor * descriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:YES];
	[request setSortDescriptors:[NSArray arrayWithObject:descriptor]];
	[descriptor release];
	[request setReturnsObjectsAsFaults:NO];
	
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
    [request release];
    
	return [result count] ? result : nil;
}

#pragma mark Video 
//- (NMVideo *)video:(NMVideo *)vid inChannel:(NMChannel *)chnObj {
//	if ( vid == nil || chnObj == nil ) return nil;
//	NSFetchRequest * request = [[NSFetchRequest alloc] init];
//	[request setEntity:videoEntityDescription];
//	[request setPredicate:[NSPredicate predicateWithFormat:@"channel == %@ AND video.nm_id == %@", chnObj, vid.video.nm_id]];
//	[request setReturnsObjectsAsFaults:NO];
//	
//	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
//    [request release];
//    
//	return [result count] ? [result objectAtIndex:0] : nil;
//}

- (NMVideo *)relateChannel:(NMChannel *)chnObj withVideo:(NMVideo *)vid {
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:videoEntityDescription];
	[request setPredicate:[videoInChannelPredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:vid, @"VIDEO", chnObj, @"CHANNEL", nil]]];
	
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	NMVideo * newVid = nil;
	if ( result == nil || [result count] == 0 ) {
		// the video and channel is not related. relate now
		newVid = [self insertNewVideo];
		newVid.channel = chnObj;
		newVid.video = vid.video;
	}
	return newVid;
}

- (void)unrelateChannel:(NMChannel *)chnObj withVideo:(NMVideo *)vid {
	[self deleteVideo:vid];
}

//- (NMVideo *)duplicateVideo:(NMVideo *)srcVideo {
//	NMVideo * dupVideo = [self insertNewVideo];
//	NMVideoDetail * dupDtl = [self insertNewVideoDetail];
//	
//	dupVideo.nm_id = srcVideo.nm_id;
//	dupVideo.nm_session_id = [NSNumber numberWithInteger:INT_MAX];
//	dupVideo.nm_playback_status = srcVideo.nm_playback_status;
//	dupVideo.nm_direct_url = srcVideo.nm_direct_url;
//	dupVideo.nm_direct_sd_url = srcVideo.nm_direct_sd_url;
//	dupVideo.nm_favorite = srcVideo.nm_favorite;
//	dupVideo.nm_watch_later = srcVideo.nm_watch_later;
//	
//	dupVideo.duration = srcVideo.duration;
//	dupVideo.external_id = srcVideo.external_id;
//	dupVideo.published_at = srcVideo.published_at;
//	dupVideo.source = srcVideo.source;
//	dupVideo.thumbnail_uri = srcVideo.thumbnail_uri;
//	dupVideo.title = srcVideo.title;
//	dupVideo.view_count = srcVideo.view_count;
//	
//	NMVideoDetail * srcDtlObject = srcVideo.detail;
//	dupDtl.author_id = srcDtlObject.author_id;
//	dupDtl.author_profile_uri = srcDtlObject.author_profile_uri;
//	dupDtl.author_thumbnail_uri = srcDtlObject.author_thumbnail_uri;
//	dupDtl.author_username = srcDtlObject.author_username;
//	dupDtl.nm_description = srcDtlObject.nm_description;
//	dupDtl.nm_author_thumbnail_file_name = srcDtlObject.nm_author_thumbnail_file_name;
//	
//	dupVideo.detail = dupDtl;
//	dupDtl.video = dupVideo;
//	
//	return dupVideo;
//}

- (NMVideo *)insertNewVideo {
	NMVideo * vid = (NMVideo *)[NSEntityDescription insertNewObjectForEntityForName:NMVideoEntityName inManagedObjectContext:managedObjectContext];
	return vid;
}

- (NMVideoDetail *)insertNewVideoDetail {
	NMVideoDetail * vid = (NMVideoDetail *)[NSEntityDescription insertNewObjectForEntityForName:NMVideoDetailEntityName inManagedObjectContext:managedObjectContext];
	return vid;
}

- (NMConcreteVideo *)insertNewConcreteVideo {
	NMConcreteVideo * info = (NMConcreteVideo *)[NSEntityDescription insertNewObjectForEntityForName:NMConcreteVideoEntityName inManagedObjectContext:managedObjectContext];
	return info;
}

- (NSArray *)sortedVideoListForChannel:(NMChannel *)chn {
	return [chn.videos sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"nm_sort_order" ascending:YES]]];
}

- (NMVideo *)videoForID:(NSNumber *)vid {
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:videoEntityDescription];
	[request setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"video"]];
	[request setReturnsObjectsAsFaults:NO];
	[request setPredicate:[objectForIDPredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:vid forKey:@"OBJECT_ID"]]];
	
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	[request release];
	NMVideo * vidObj = nil;
	if ( [result count] ) {
		vidObj = [result objectAtIndex:0];
		//[categoryCacheDictionary setObject:catObj forKey:catObj.nm_id];
	}
	return vidObj;
}

- (NMVideo *)lastSessionVideoForChannel:(NMChannel *)chn {
	// return immediately if the channel is not currently subscribed
	if ( ![chn.nm_subscribed boolValue] || [chn.nm_last_vid integerValue] == 0 ) return nil;
	// fetch last video played
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:videoEntityDescription];
	[request setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"video"]];
	[request setReturnsObjectsAsFaults:NO];
	[request setPredicate:[NSPredicate predicateWithFormat:@"channel == %@ AND channel.nm_last_vid == video.nm_id AND video.nm_error == 0", chn]];
	NSArray * results = [managedObjectContext executeFetchRequest:request error:nil];
	NMVideo * vidObj = nil;
	if ( [results count] ) {
		// return the video object
		vidObj = [results objectAtIndex:0];
	}
	[request release];
	return vidObj;
}

- (void)deleteVideo:(NMVideo *)vidObj {
	if ( vidObj == nil ) return;
	[managedObjectContext deleteObject:vidObj];
}

- (void)batchDeleteVideos:(NSSet *)vdoSet {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	// prefetch related object
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:videoEntityDescription];
	[request setPredicate:[NSPredicate predicateWithFormat:@"SELF in %@", vdoSet]];
	[request setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObjects:@"channel", @"detail", nil]];
	
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	
	if ( [result count] ) {
		for (NSManagedObject * mobj in result) {
			[managedObjectContext deleteObject:mobj];
		}
	}
	[request release];
	[pool release];
}

//- (void)deleteVideoWithID:(NSNumber *)vid fromChannel:(NMChannel *)chn {
//	NSFetchRequest * request = [[NSFetchRequest alloc] init];
//	[request setEntity:videoEntityDescription];
//	[request setPredicate:[videoInChannelPredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:vid, @"OBJECT_ID", chn, @"CHANNEL", nil]]];
//	[request setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObjects:@"detail", @"channel", nil]];
//	
//	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
//	if ( [result count] ) {
//		for (NMVideo * vdo in result) {
//			[managedObjectContext deleteObject:vdo];
//		}
//	}
//    
//    [request release];
//}

- (void)batchUpdateVideoWithID:(NSNumber *)vid forValue:(id)val key:(NSString *)akey {
	// this method is used when remove a video from favorite or watch later channel. videos are copied. Other NMVideo MOs with the same nm_id should be updated as well
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:videoEntityDescription];
	[request setPredicate:[objectForIDPredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:vid forKey:@"OBJECT_ID"]]];
	
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	[request release];
	NMVideo * vidObj = nil;
	if ( [result count] ) {
		for (vidObj in result) {
			[vidObj setValue:val forKey:akey];
		}
	}
}

- (NSInteger)maxVideoSortOrderInChannel:(NMChannel *)chn sessionOnly:(BOOL)flag {
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setResultType:NSDictionaryResultType];
	[request setEntity:videoEntityDescription];
	NSPredicate * thePredicate = nil;
	if ( flag ) {
		// take session into account
		thePredicate = [channelAndSessionPredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:chn, @"CHANNEL", NM_SESSION_ID, @"SESSION_ID", nil]];
	} else {
		// ignore session
		thePredicate = [channelPredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:chn forKey:@"CHANNEL"]];
	}
	[request setPredicate:thePredicate];
	
	NSExpression * keyPathExpression = [NSExpression expressionForKeyPath:@"nm_sort_order"];
	NSExpression * maxSortOrderExpression = [NSExpression expressionForFunction:@"max:" arguments:[NSArray arrayWithObject:keyPathExpression]];
	
	NSExpressionDescription * expressionDescription = [[NSExpressionDescription alloc] init];
	[expressionDescription setName:@"sort_order"];
	[expressionDescription setExpression:maxSortOrderExpression];
	[expressionDescription setExpressionResultType:NSInteger32AttributeType];
	[request setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];
	
	// execute fetch request
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	
	[expressionDescription release];
	[request release];
	
	NSInteger theOrder = 0;
	if ( [result count] ) {
		theOrder = [[[result objectAtIndex:0] valueForKey:@"sort_order"] integerValue];
	}
	return theOrder;
}

- (NMVideoExistenceCheckResult)videoExistsWithID:(NSNumber *)vid channel:(NMChannel *)chn targetVideo:(NMConcreteVideo **)outRealVdo {
	*outRealVdo = nil;
	// check whether the video exists in the given channel
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:videoEntityDescription];
	[request setPredicate:[concreteVideoForIDPredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:vid forKey:@"OBJECT_ID"]]];
	[request setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"video"]];
	[request setReturnsObjectsAsFaults:NO];
	
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	NMVideoExistenceCheckResult checkResult = NMVideoDoesNotExist;
	if ( result && [result count] ) {
		BOOL vdoInChn = NO;
		NMVideo * vdo = nil;
		// check whether the video is in the channel
		for (vdo in result) {
			if ( [vdo.channel isEqual:chn] ) {
				// video already exists in the current channel
				vdoInChn = YES;
				break;
			}
		}
		if ( vdoInChn ) {
			checkResult = NMVideoExistsAndInChannel;
		} else {
			*outRealVdo = vdo.video;
			// video exists but not in "chn" channel. We just need to create the NMVideo object.
			checkResult = NMVideoExistsButNotInChannel;
		}
	}
	[request release];
	// should return a result object which contains the video object (if necessary) and the comparison result
	return checkResult;
}

- (NMVideo *)insertVideoWithExternalID:(NSString *)anExtID {
	
}

#pragma mark Author
- (NMAuthor *)authorForID:(NSNumber *)authID {
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setPredicate:[objectForIDPredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:authID forKey:@"OBJECT_ID"]]];
	[request setEntity:authorEntityDescription];
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	NMAuthor * theAuthor = nil;
	if ( result && [result count] ) {
		theAuthor = [result objectAtIndex:0];
	}
	[request release];
	return theAuthor;
}

- (NMAuthor *)insertNewAuthor {
	return [NSEntityDescription insertNewObjectForEntityForName:NMAuthorEntityName inManagedObjectContext:managedObjectContext];
}

#pragma mark Subscription and Profile
- (NMPersonProfile *)insertNewPersonProfileWithID:(NSString *)strID isNew:(BOOL *)isNewObj {
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:NMPersonProfileEntityName inManagedObjectContext:managedObjectContext]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"nm_user_id like %@", strID]];
	
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	NMPersonProfile * profileObj = nil;
	if ( result && [result count] ) {
		profileObj = [result objectAtIndex:0];
		*isNewObj = NO;
	} else {
		profileObj = [NSEntityDescription insertNewObjectForEntityForName:NMPersonProfileEntityName inManagedObjectContext:managedObjectContext];
		profileObj.nm_user_id = strID;
		*isNewObj = YES;
	}
	[request release];
	return profileObj;
}

- (NMChannel *)subscribeUserChannelWithPersonProfile:(NMPersonProfile *)aProfile {
	NMChannel * chnObj = aProfile.subscription.channel;
	if ( chnObj == nil ) {
		// the user channel does not exist. create and subscribe it.
		chnObj = [NSEntityDescription insertNewObjectForEntityForName:NMChannelEntityName inManagedObjectContext:managedObjectContext];
		chnObj.type = aProfile.nm_type;
		chnObj.nm_is_new = (NSNumber *)kCFBooleanTrue;
		chnObj.title = aProfile.first_name;
		chnObj.thumbnail_uri = aProfile.picture;
		// create subscription
		NMSubscription * subtObj = [NSEntityDescription insertNewObjectForEntityForName:NMSubscriptionEntityName inManagedObjectContext:managedObjectContext];
		subtObj.channel = chnObj;
		subtObj.personProfile = aProfile;
	}
	return chnObj;
}

- (NSArray *)subscribedFacebookUserChannels {
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:channelEntityDescription];
	[request setPredicate:[NSPredicate predicateWithFormat:@"type == %@", [NSNumber numberWithInteger:NMChannelUserFacebookType]]];
	
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	[request release];
	return result;
}

#pragma mark Data parsing
- (void)createDataParsingOperationForTask:(NMTask *)atask {
	NSInvocationOperation * op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(parseAndProcessData:) object:atask];
	[operationQueue addOperation:op];
	[op release];
}

- (void)parseAndProcessData:(id)data { 
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NMTask * task = (NMTask *)data;
	if ( [task.buffer length] ) {
		// parse the JSON string
		[task processDownloadedDataInBuffer];
		// remove data buffer to save memory
		/*if ( task.command != NMCommandGetChannelThumbnail )*/ [task clearDataBuffer];
	}
	
	if ( task.executeSaveActionOnError || !task.encountersErrorDuringProcessing ) {
		if ( NMVideoPlaybackViewIsScrolling ) {
			[self performSelector:@selector(delayedSaveCacheForTask:) withObject:task afterDelay:0.25];
		} else {
			[self performSelectorOnMainThread:@selector(saveCacheForTask:) withObject:task waitUntilDone:NO];
		}
	} else {
		// there's error, check if there's "error" object
		NSDictionary * errDict = task.errorInfo;
		NSNotification * n = [NSNotification notificationWithName:[task didFailNotificationName] object:task userInfo:errDict];
		// post notification from main thread. we must use performSelectorOnMainThread
		[notificationCenter performSelectorOnMainThread:@selector(postNotification:) withObject:n waitUntilDone:NO];
	}
	
	[pool release];
}

- (void)delayedSaveCacheForTask:(NMTask *)task {
	[self performSelectorOnMainThread:@selector(saveCacheForTask:) withObject:task waitUntilDone:NO];
}

- (void)saveCacheForTask:(NMTask *)task {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	BOOL shouldSave = [task saveProcessedDataInController:self];
	[pool release];
		
	NSError * error = nil;
	if ( shouldSave ) {
		if ( ![managedObjectContext save:&error] ) {
			NSLog(@"can't save cache %@", error);
		}
	}
	// send notification
	NSString * notifyStr;
	if ( !task.encountersErrorDuringProcessing ) {
		notifyStr = [task didLoadNotificationName];
		if ( notifyStr ) [notificationCenter postNotificationName:notifyStr object:task userInfo:[task userInfo]];
	} else if ( task.executeSaveActionOnError ) {
		notifyStr = [task didFailNotificationName];
		if ( notifyStr ) [notificationCenter postNotificationName:notifyStr object:task userInfo:[task userInfo]];
	}
}

@end
