//
//  NMDataController.m
//  Nowmov
//
//  Created by Bill So on 05/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMDataController.h"
#import "NMTask.h"
#import "NMChannel.h"
#import "NMVideo.h"


NSString * const NMChannelEntityName = @"NMChannel";
NSString * const NMVideoEntityName = @"NMVideo";
NSString * const NMVideoDetailEntityName = @"NMVideoDetail";

@implementation NMDataController
@synthesize managedObjectContext, sortedVideoList;
@synthesize trendingChannel;

- (id)init {
	self = [super init];
	
	operationQueue = [[NSOperationQueue alloc] init];
	notificationCenter = [NSNotificationCenter defaultCenter];
	
	channelNamePredicateTemplate = [[NSPredicate predicateWithFormat:@"title like $NM_CHANNEL_NAME"] retain];
	channelNamesPredicateTemplate = [[NSPredicate predicateWithFormat:@"title IN $NM_CHANNEL_NAMES"] retain];
	
	return self;
}

- (void)dealloc {
	[trendingChannel release];
	[channelNamePredicateTemplate release];
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
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"channel == %@ AND nm_error == 0", chnObj]];
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

#pragma mark Channels
- (NMChannel *)insertNewChannel {
	NMChannel * channelObj = [NSEntityDescription insertNewObjectForEntityForName:NMChannelEntityName inManagedObjectContext:managedObjectContext];
	return channelObj;
}

- (NSDictionary *)fetchChannelsForNames:(NSArray *)channelAy {
	// channels are created when the app launch or after sign in. Probably don't need to optimize the operation that much
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:NMChannelEntityName inManagedObjectContext:managedObjectContext]];
	[request setReturnsObjectsAsFaults:NO];
	[request setPredicate:[channelNamesPredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:channelAy forKey:@"NM_CHANNEL_NAMES"]]];
	
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
	
	if ( task.encountersErrorDuringProcessing ) {
		// there's error, check if there's "error" object
		NSDictionary * errDict = task.errorInfo;
		NSNotification * n = [NSNotification notificationWithName:[task didFailNotificationName] object:self userInfo:errDict];
		// post notification from main thread. we must use performSelectorOnMainThread
		[notificationCenter performSelectorOnMainThread:@selector(postNotification:) withObject:n waitUntilDone:NO];
	} else {
		[self performSelectorOnMainThread:@selector(saveCacheForTask:) withObject:task waitUntilDone:NO];
	}
	
	[pool release];
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
		[notificationCenter postNotificationName:[task didLoadNotificationName] object:self userInfo:[task userInfo]];
//	}
}

@end
