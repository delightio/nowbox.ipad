//
//  NMDataController.m
//  Nowmov
//
//  Created by Bill So on 05/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMDataController.h"
#import "NMTask.h"


@implementation NMDataController
@synthesize managedObjectContext;

- (id)init {
	self = [super init];
	
	operationQueue = [[NSOperationQueue alloc] init];
	notificationCenter = [NSNotificationCenter defaultCenter];
	
	return self;
}

- (void)dealloc {
	[operationQueue release];
	[super dealloc];
}

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
		parsedObject = [task processDownloadedDataInBuffer];
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
