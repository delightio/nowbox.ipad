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

#define NM_MY_QUEUE_CHANNEL_ID			-20
#define NM_FAVORITE_VIDEOS_CHANNEL_ID	-10

NSString * const NMCategoryEntityName = @"NMCategory";
NSString * const NMChannelEntityName = @"NMChannel";
NSString * const NMVideoEntityName = @"NMVideo";
NSString * const NMVideoDetailEntityName = @"NMVideoDetail";

BOOL NMVideoPlaybackViewIsScrolling = NO;

@implementation NMDataController
@synthesize managedObjectContext;
@synthesize channelEntityDescription, videoEntityDescription;
@synthesize categories, categoryCacheDictionary;
@synthesize subscribedChannels, trendingChannel;
@synthesize internalSearchCategory;
@synthesize myQueueChannel, favoriteVideoChannel;

- (id)init {
	self = [super init];
	
	operationQueue = [[NSOperationQueue alloc] init];
	notificationCenter = [NSNotificationCenter defaultCenter];
	
//	channelNamePredicateTemplate = [[NSPredicate predicateWithFormat:@"title like $NM_CHANNEL_NAME"] retain];
//	channelNamesPredicateTemplate = [[NSPredicate predicateWithFormat:@"title IN $NM_CHANNEL_NAMES"] retain];
	subscribedChannelsPredicate = [[NSPredicate predicateWithFormat:@"nm_subscribed == %@ AND nm_id > 0", [NSNumber numberWithBool:YES]] retain];
	objectForIDPredicateTemplate = [[NSPredicate predicateWithFormat:@"nm_id == $OBJECT_ID"] retain];
	categoryCacheDictionary = [[NSMutableDictionary alloc] initWithCapacity:16];
	channelCacheDictionary = [[NSMutableDictionary alloc] initWithCapacity:16];
	
	return self;
}

- (void)dealloc {
	[myQueueChannel release], [favoriteVideoChannel release];
	[trendingChannel release];
	[categoryCacheDictionary release];
	[channelCacheDictionary release];
//	[channelNamePredicateTemplate release];
	[subscribedChannelsPredicate release];
	[objectForIDPredicateTemplate release];
	[managedObjectContext release];
	[operationQueue release];
	[internalSearchCategory release];
	[channelEntityDescription release], [videoEntityDescription release];
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
	} else {
		managedObjectContext = nil;
		self.channelEntityDescription = nil;
		self.videoEntityDescription = nil;
	}
}

#pragma mark Data manipulation
- (void)deleteManagedObjects:(id<NSFastEnumeration>)objs {
	NSManagedObject * mobj;
	for (mobj in objs) {
		[managedObjectContext deleteObject:mobj];
	}
	// clean up cache
	[categoryCacheDictionary removeAllObjects];
	[channelCacheDictionary removeAllObjects];
}

- (void)deleteVideoInChannel:(NMChannel *)chnObj {
	NMVideo * vdo;
	for (vdo in chnObj.videos) {
		[managedObjectContext deleteObject:vdo];
	}
}

- (void)deleteVideoInChannel:(NMChannel *)chnObj exceptVideo:(NMVideo *)aVideo {
	NMVideo * vdo;
	for (vdo in chnObj.videos) {
		if ( vdo == aVideo ) continue;
		[managedObjectContext deleteObject:vdo];
	}
}

- (void)deleteVideoInChannel:(NMChannel *)chnObj afterVideo:(NMVideo *)aVideo {
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:videoEntityDescription];
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"channel == %@", chnObj]];
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:YES];
	NSSortDescriptor * timestampDesc = [[NSSortDescriptor alloc] initWithKey:@"nm_session_id" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:timestampDesc, sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
	[sortDescriptor release];
	[timestampDesc release];
	
	NSError * error = nil;
	NSArray * results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
	
	// delete those beyond the current video
	NMVideo * theVideo;
	BOOL deleteBeyond = NO;
	for (theVideo in results) {
		if ( deleteBeyond ) {
			// delete the video object
			[managedObjectContext deleteObject:theVideo];
			continue;
		}
		if ( !deleteBeyond && theVideo == aVideo ) {
			deleteBeyond = YES;
		}
	}

}

- (void)deleteAllVideos {
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:videoEntityDescription];
	NSArray * results = [managedObjectContext executeFetchRequest:request error:nil];
	
	for (NSManagedObject * obj in results) {
		[managedObjectContext deleteObject:obj];
	}
	[request release];
}

#pragma mark First launch
- (void)setUpDatabaseForFirstLaunch {
	// create channels: my queue, favorites
	[self favoriteVideoChannel];
	[self myQueueChannel];
	[self internalSearchCategory];
}

#pragma mark Session management
- (void)deleteVideosWithSessionID:(NSInteger)sid {
	//TODO: do not delete video that are in Favorite or My Queue channels
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:videoEntityDescription];
	// nm_session_id <= %@ AND NOT ANY categories = %@
	[request setPredicate:[NSPredicate predicateWithFormat:@"nm_session_id <= %@", [NSNumber numberWithInteger:sid]]];
	[request setReturnsObjectsAsFaults:YES];
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	for (NMVideo * vid in result) {
		[managedObjectContext deleteObject:vid];
	}
}

- (void)resetAllChannelsPageNumber {
	NSArray * subChn = self.subscribedChannels;
	NSNumber * pgNum = [NSNumber numberWithInteger:1];
	for (NMChannel * chnObj in subChn) {
		// reset the page number to 1. Page number always start at 1.
		chnObj.nm_current_page = pgNum;
	}
}


#pragma mark Search Results Support
- (NMCategory *)internalSearchCategory {
	if ( internalSearchCategory == nil ) {
		// retrieve that category
		NSFetchRequest * request = [[NSFetchRequest alloc] init];
		[request setEntity:[NSEntityDescription entityForName:NMCategoryEntityName inManagedObjectContext:managedObjectContext]];
		NSNumber * searchCatID = [NSNumber numberWithInteger:-1];
		[request setPredicate:[NSPredicate predicateWithFormat:@"nm_id = %@", searchCatID]];
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
		searchResultsPredicate = [[NSPredicate predicateWithFormat:@"ANY categories = %@", self.internalSearchCategory] retain];
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

#pragma mark Channels
- (NMChannel *)insertNewChannelForID:(NSNumber *)chnID {
	// clean up the cache. channelCacheDictionary caches objects that do not exist.
	if ( chnID ) [channelCacheDictionary removeObjectForKey:chnID];
	NMChannel * channelObj = [NSEntityDescription insertNewObjectForEntityForName:NMChannelEntityName inManagedObjectContext:managedObjectContext];
	channelObj.nm_id = chnID;
	return channelObj;
}

- (NSArray *)subscribedChannels {
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:channelEntityDescription];
	[request setReturnsObjectsAsFaults:NO];
	[request setPredicate:subscribedChannelsPredicate];
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

- (BOOL)emptyChannel {
	// return bool whether there's any channel in the app at all
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:channelEntityDescription];
	[request setResultType:NSManagedObjectIDResultType];
	NSError * error = nil;
	NSArray * results = [managedObjectContext executeFetchRequest:request error:&error];
	return [results count] < 2;		// the app should, at least, contain one single channel (trending)
}

- (NMChannel *)trendingChannel {
	if ( trendingChannel == nil ) {
		NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:channelEntityDescription];
		[fetchRequest setFetchLimit:1];
		[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"nm_id > 0"]];
		
		NSSortDescriptor * sortDsrpt = [[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:YES];
		
		[fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDsrpt]];
		[sortDsrpt release];
		
		[fetchRequest setReturnsObjectsAsFaults:NO];
		NSArray * result = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
		trendingChannel = [[result objectAtIndex:0] retain];
		[fetchRequest release];
	}
	return trendingChannel;
}

- (NMChannel *)myQueueChannel {
	if ( myQueueChannel == nil ) {
		NSFetchRequest * request = [[NSFetchRequest alloc] init];
		[request setEntity:channelEntityDescription];
		NSNumber * myChannelID = [NSNumber numberWithInteger:NM_MY_QUEUE_CHANNEL_ID];
		[request setPredicate:[NSPredicate predicateWithFormat:@"nm_id = %@", myChannelID]];
		[request setReturnsObjectsAsFaults:NO];
		NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
		if ( result == nil || [result count] == 0 ) {
			// we need to create the category
			NMChannel * chnObj = [NSEntityDescription insertNewObjectForEntityForName:NMChannelEntityName inManagedObjectContext:managedObjectContext];
			chnObj.title = @"MY QUEUE";
			chnObj.nm_id = myChannelID;
			chnObj.nm_sort_order = myChannelID;
			chnObj.nm_subscribed = [NSNumber numberWithBool:YES];
			chnObj.thumbnail_uri = [[NSBundle mainBundle] pathForResource:@"internal-channel-queue" ofType:@"png"];
			chnObj.nm_thumbnail_file_name = @"internal-channel-queue.png";
			self.myQueueChannel = chnObj;
		} else {
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
		NSNumber * myChannelID = [NSNumber numberWithInteger:NM_FAVORITE_VIDEOS_CHANNEL_ID];
		[request setPredicate:[NSPredicate predicateWithFormat:@"nm_id = %@", myChannelID]];
		[request setReturnsObjectsAsFaults:NO];
		NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
		if ( result == nil || [result count] == 0 ) {
			// we need to create the category
			NMChannel * chnObj = [NSEntityDescription insertNewObjectForEntityForName:NMChannelEntityName inManagedObjectContext:managedObjectContext];
			chnObj.title = @"MY FAVORITES";
			chnObj.nm_id = myChannelID;
			chnObj.nm_sort_order = myChannelID;
			chnObj.nm_subscribed = [NSNumber numberWithBool:YES];
			chnObj.thumbnail_uri = [[NSBundle mainBundle] pathForResource:@"internal-channel-favorites" ofType:@"png"];
			chnObj.nm_thumbnail_file_name = @"internal-channel-favorites.png";
			self.favoriteVideoChannel = chnObj;
		} else {
			self.favoriteVideoChannel = [result objectAtIndex:0];
		}
		[request release];
	}
	return favoriteVideoChannel;
}

#pragma mark Video 
- (NMVideo *)insertNewVideo {
	NMVideo * vid = (NMVideo *)[NSEntityDescription insertNewObjectForEntityForName:NMVideoEntityName inManagedObjectContext:managedObjectContext];
	return vid;
}

- (NMVideoDetail *)insertNewVideoDetail {
	NMVideoDetail * vid = (NMVideoDetail *)[NSEntityDescription insertNewObjectForEntityForName:NMVideoDetailEntityName inManagedObjectContext:managedObjectContext];
	return vid;
}

- (NSArray *)sortedVideoListForChannel:(NMChannel *)chn {
	return [chn.videos sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"nm_sort_order" ascending:YES]]];
}

- (NMVideo *)videoForID:(NSNumber *)vid {
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:videoEntityDescription];
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
		if ( task.command != NMCommandGetChannelThumbnail ) [task clearDataBuffer];
	}
	
	if ( task.executeSaveActionOnError || !task.encountersErrorDuringProcessing ) {
		if ( NMVideoPlaybackViewIsScrolling ) {
			[self performSelector:@selector(delayedSaveCacheForTask:) withObject:task afterDelay:0.25f];
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
//	if ( task.command > NMCommandImageDownloadCommandBoundary ) {
//		[cacheController showImageForTask:(JPImageDownloadTask *)task];
//	} else {
		NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		[task saveProcessedDataInController:self];
		[pool release];
		
		NSError * error = nil;
	switch (task.command) {
		case NMCommandGetAllChannels:
		case NMCommandGetSubscribedChannels:
			if ( ![managedObjectContext save:&error] ) {
				NSLog(@"can't save cache %@", error);
			}
			break;
			
		default:
			break;
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
//	}
}

@end
