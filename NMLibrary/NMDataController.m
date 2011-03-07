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


NSString * const NMChannelEntityName = @"NMChannel";
NSString * const NMVideoEntityName = @"NMVideo";

@implementation NMDataController
@synthesize managedObjectContext;

- (id)init {
	self = [super init];
	
	operationQueue = [[NSOperationQueue alloc] init];
	notificationCenter = [NSNotificationCenter defaultCenter];
	
	channelNamePredicateTemplate = [[NSPredicate predicateWithFormat:@"channel_name like $NM_CHANNEL_NAME"] retain];
	channelNamesPredicateTemplate = [[NSPredicate predicateWithFormat:@"channel_name IN $NM_CHANNEL_NAMES"] retain];
	
	return self;
}

- (void)dealloc {
	[channelNamePredicateTemplate release];
	[managedObjectContext release];
	[operationQueue release];
	[super dealloc];
}

#pragma mark Data manipulation
- (void)deleteManagedObjects:(id<NSFastEnumeration>)objs {
	NSManagedObject * mobj;
	for (mobj in objs) {
		[managedObjectContext deleteObject:mobj];
	}
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
		return dict;
	}
	
	return nil;
}

#pragma mark Video 
- (NMVideo *)insertNewVideo {
	NMVideo * vid = (NMVideo *)[NSEntityDescription insertNewObjectForEntityForName:NMVideoEntityName inManagedObjectContext:managedObjectContext];
	return vid;
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
	id parsedObject = nil;
	if ( [task.buffer length] ) {
		// parse the JSON string
		[task processDownloadedDataInBuffer];
		// remove data buffer to save memory
		[task clearDataBuffer];
	}
	
	if ( task.encountersErrorDuringProcessing ) {
		// there's error, check if there's "error" object
		NSDictionary * errDict = [parsedObject objectForKey:@"error"];
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
