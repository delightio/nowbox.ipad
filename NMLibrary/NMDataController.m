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


NSString * const NMCategoryEntityName = @"NMCategory";
NSString * const NMChannelEntityName = @"NMChannel";
NSString * const NMVideoEntityName = @"NMVideo";
NSString * const NMVideoDetailEntityName = @"NMVideoDetail";

BOOL NMVideoPlaybackViewIsScrolling = NO;

@implementation NMDataController
@synthesize managedObjectContext, sortedVideoList;
@synthesize categories, categoryCacheDictionary;
@synthesize subscribedChannels, trendingChannel;

- (id)init {
	self = [super init];
	
	operationQueue = [[NSOperationQueue alloc] init];
	notificationCenter = [NSNotificationCenter defaultCenter];
	
//	channelNamePredicateTemplate = [[NSPredicate predicateWithFormat:@"title like $NM_CHANNEL_NAME"] retain];
//	channelNamesPredicateTemplate = [[NSPredicate predicateWithFormat:@"title IN $NM_CHANNEL_NAMES"] retain];
	subscribedChannelsPredicate = [[NSPredicate predicateWithFormat:@"nm_subscribed == %@", [NSNumber numberWithBool:YES]] retain];
	objectForIDPredicateTemplate = [[NSPredicate predicateWithFormat:@"nm_id == $OBJECT_ID"] retain];
	categoryCacheDictionary = [[NSMutableDictionary alloc] initWithCapacity:16];
	
	return self;
}

- (void)dealloc {
	[trendingChannel release];
	[categoryCacheDictionary release];
//	[channelNamePredicateTemplate release];
	[subscribedChannelsPredicate release];
	[objectForIDPredicateTemplate release];
	[managedObjectContext release];
	[operationQueue release];
	[sortedVideoList release];
	[super dealloc];
}

#pragma mark Data manipulation
- (void)deleteManagedObjects:(id<NSFastEnumeration>)objs {
	NSManagedObject * mobj;
	for (mobj in objs) {
		[managedObjectContext deleteObject:mobj];
	}
	// clean up cache
	[categoryCacheDictionary removeAllObjects];
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
	[fetchRequest setEntity:[NSEntityDescription entityForName:NMVideoEntityName inManagedObjectContext:managedObjectContext]];
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"channel == %@", chnObj]];
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:YES];
	NSSortDescriptor * timestampDesc = [[NSSortDescriptor alloc] initWithKey:@"nm_fetch_timestamp" ascending:YES];
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
	[request setEntity:[NSEntityDescription entityForName:NMVideoEntityName inManagedObjectContext:managedObjectContext]];
	NSArray * results = [managedObjectContext executeFetchRequest:request error:nil];
	
	for (NSManagedObject * obj in results) {
		[managedObjectContext deleteObject:obj];
	}
	[request release];
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

- (NMCategory *)insertNewCategory {
	NMCategory * categoryObj = [NSEntityDescription insertNewObjectForEntityForName:NMCategoryEntityName inManagedObjectContext:managedObjectContext];
	return categoryObj;
}

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
		NMCategory * catObj = [result objectAtIndex:0];
		[categoryCacheDictionary setObject:catObj forKey:catObj.nm_id];
	} else {
		// this category does not exist in core data
		[categoryCacheDictionary setObject:[NSNull null] forKey:catID];
	}
	return catObj;
}

#pragma mark Channels
- (NMChannel *)insertNewChannel {
	NMChannel * channelObj = [NSEntityDescription insertNewObjectForEntityForName:NMChannelEntityName inManagedObjectContext:managedObjectContext];
	return channelObj;
}

- (NSArray *)subscribedChannels {
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:NMChannelEntityName inManagedObjectContext:managedObjectContext]];
	[request setReturnsObjectsAsFaults:NO];
	[request setPredicate:subscribedChannelsPredicate];
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	[request release];
	return [result count] ? result : nil;
}

- (NMChannel *)channelForID:(NSNumber *)chnID {
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:NMChannelEntityName inManagedObjectContext:managedObjectContext]];
	[request setPredicate:[objectForIDPredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:chnID forKey:@"OBJECT_ID"]]];
	[request setReturnsObjectsAsFaults:NO];
	
	NSArray * result = [managedObjectContext executeFetchRequest:request error:nil];
	[request release];
	
	return [result count] ? [result objectAtIndex:0] : nil;
}

- (NSDictionary *)fetchChannelsForNames:(NSArray *)channelAy {
	// channels are created when the app launch or after sign in. Probably don't need to optimize the operation that much
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:NMChannelEntityName inManagedObjectContext:managedObjectContext]];
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
	[request setEntity:[NSEntityDescription entityForName:NMChannelEntityName inManagedObjectContext:managedObjectContext]];
	[request setResultType:NSManagedObjectIDResultType];
	NSError * error = nil;
	NSArray * results = [managedObjectContext executeFetchRequest:request error:&error];
	return [results count] < 2;		// the app should, at least, contain one single channel (trending)
}

- (NMChannel *)trendingChannel {
	if ( trendingChannel == nil ) {
		NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:NMChannelEntityName inManagedObjectContext:managedObjectContext]];
		[fetchRequest setFetchLimit:1];
		
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

//- (NSArray *)sortedLiveChannelVideoList {
//	if ( sortedVideoList ) return sortedVideoList;
//	NSFetchRequest * request = [[NSFetchRequest alloc] init];
//	[request setEntity:[NSEntityDescription entityForName:NMVideoEntityName inManagedObjectContext:managedObjectContext]];
//	[request setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"nm_sort_order" ascending:YES]]];
//	[request setReturnsObjectsAsFaults:NO];
//	
//	self.sortedVideoList = [managedObjectContext executeFetchRequest:request error:nil];
//	return sortedVideoList;
//}

- (NMVideo *)videoForID:(NSNumber *)vid {
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:NMVideoEntityName inManagedObjectContext:managedObjectContext]];
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
		NSNotification * n = [NSNotification notificationWithName:[task didFailNotificationName] object:self userInfo:errDict];
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
		case NMCommandGetDefaultChannels:
			if ( ![managedObjectContext save:&error] ) {
				NSLog(@"can't save cache %@", error);
			}
			break;
			
		default:
			break;
	}
		// send notification
	if ( task.encountersErrorDuringProcessing == NO ) {
		NSString * notifyStr = [task didLoadNotificationName];
		if ( notifyStr ) [notificationCenter postNotificationName:notifyStr object:task userInfo:[task userInfo]];
	}
//	}
}

@end
