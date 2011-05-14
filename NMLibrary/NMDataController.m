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

@implementation NMDataController
@synthesize managedObjectContext, sortedVideoList;
@synthesize liveChannel;

- (id)init {
	self = [super init];
	
	operationQueue = [[NSOperationQueue alloc] init];
	notificationCenter = [NSNotificationCenter defaultCenter];
	
	channelNamePredicateTemplate = [[NSPredicate predicateWithFormat:@"channel_name like $NM_CHANNEL_NAME"] retain];
	channelNamesPredicateTemplate = [[NSPredicate predicateWithFormat:@"channel_name IN $NM_CHANNEL_NAMES"] retain];
	
	return self;
}

- (void)dealloc {
	[liveChannel release];
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
			[dict setObject:channelObj forKey:channelObj.channel_name];
		}
		[request release];
		return dict;
	}
	
	[request release];
	return nil;
}

- (NMChannel *)liveChannel {
	if ( liveChannel == nil ) {
		NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:NMChannelEntityName inManagedObjectContext:managedObjectContext]];
		[fetchRequest setPredicate:[channelNamePredicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:@"live" forKey:@"NM_CHANNEL_NAME"]]];
		[fetchRequest setReturnsObjectsAsFaults:NO];
		NSArray * result = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
		if ( result == nil || [result count] == 0 ) {
			// insert channel
			liveChannel = [[self insertNewChannel] retain];
			liveChannel.channel_name = @"live";
			liveChannel.channel_url = @"http://nowmov.com/live";
		} else {
			liveChannel = [[result objectAtIndex:0] retain];
		}
		[fetchRequest release];
	}
	return liveChannel;
}

#pragma mark Video 
- (NMVideo *)insertNewVideo {
	NMVideo * vid = (NMVideo *)[NSEntityDescription insertNewObjectForEntityForName:NMVideoEntityName inManagedObjectContext:managedObjectContext];
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
		if ( ![managedObjectContext save:&error] ) {
			NSLog(@"can't save cache %@", error);
		}
		// send notification
		[notificationCenter postNotificationName:[task didLoadNotificationName] object:self userInfo:[task userInfo]];
//	}
}

@end
