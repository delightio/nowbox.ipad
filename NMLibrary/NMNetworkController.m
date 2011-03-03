//
//  NMNetworkController.m
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMNetworkController.h"
#import "NMDataType.h"

#define NM_MAX_NUMBER_OF_CONCURRENT_CONNECTION		8

NSString * const NMURLConnectionErrorNotification = @"NMURLConnectionErrorNotification";

@implementation NMNetworkController

- (id)init {
	self = [super init];
	taskPool = [[NSMutableDictionary alloc] init];
	connectionPool = [[NSMutableDictionary alloc] init];
	pendingTaskBuffer = [[NSMutableArray alloc] init];
	connectionDateLog = [[NSMutableArray alloc] initWithCapacity:5];
	networkConnectionLock = [[NSLock alloc] init];
	isDone = NO;
	maxNumberOfConnection = 8;
	defaultCenter = [[NSNotificationCenter defaultCenter] retain];
	[NSThread detachNewThreadSelector:@selector(controlThreadMain:) toTarget:self withObject:nil];
	return self;
}

- (void)dealloc {
	isDone = YES;
	[defaultCenter release];
	[taskPool release];
	[connectionPool release];
	[pendingTaskBuffer release];
	[networkConnectionLock release];
	[connectionDateLog release];
	[super dealloc];
}

- (void)controlThreadMain:(id)arg {
	@try {
		NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		
		controlThread = [NSThread currentThread];
		
		while (!isDone) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
		}
		
		[pool release];
	}
	@catch(NSException *e) {
		// Do not rethrow exceptions.
#ifdef DEBUG_CONNECTION_CONTROLLER
		NSLog(@"%@", [e description]);
#endif
	}
}

#pragma mark Connection management
- (void)addNewConnectionForTasks:(NSArray *)tasks {
	@synchronized(pendingTaskBuffer) {
		[pendingTaskBuffer addObjectsFromArray:tasks];
		NMTask *t;
		for (t in tasks) {
			t.state = NMTaskExecutionStateWaitingInConnectionQueue;
		}
	}
	[self performSelector:@selector(createConnection) onThread:controlThread withObject:nil waitUntilDone:NO];
}

- (void)addNewConnectionForTask:(NMTask *)aTask {
	@synchronized(pendingTaskBuffer) {
		[pendingTaskBuffer addObject:aTask];
		aTask.state = NMTaskExecutionStateWaitingInConnectionQueue;
	}
	[self performSelector:@selector(createConnection) onThread:controlThread withObject:nil waitUntilDone:NO];
}
/*
 - (void)configureUploadURLRequest:(NSMutableURLRequest *)request forTask:(NMTask *)aTask {
 NSError *error = nil;
 // get file name
 NSString *fPath = [aTask.infoDict objectForKey:TBFilePathDictKey];
 // get file size
 NSDictionary *fDict = [[NSFileManager defaultManager] attributesOfItemAtPath:fPath error:&error];
 // open file stream for attachment
 NSInputStream * fileStream = [NSInputStream inputStreamWithFileAtPath:fPath];
 [request setHTTPBodyStream:fileStream];
 [request setValue:[NSString stringWithFormat:@"%qu", [fDict fileSize]] forHTTPHeaderField:@"Content-Length"];
 }
 */
- (void)enableConnectionCreationCheck {
	if ( connectionExecutionTimer ) return;
	self.connectionExecutionTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(connectionCreationTimerMethod:) userInfo:nil repeats:YES];
}

- (void)connectionCreationTimerMethod:(NSTimer *)atimer {
#ifdef DEBUG_CONNECTION_CONTROLLER
	NSLog(@"run additional network call");
#endif
	NMTask *theTask;
	NSMutableURLRequest *request;
	NSURLConnection *conn;
	NSNumber *key;
	BOOL transverseWholeArray = YES;
	@synchronized(pendingTaskBuffer) {
		for (theTask in pendingTaskBuffer) {
			if ( theTask.state == NMTaskExecutionStateWaitingInConnectionQueue ) {
				if ( [self tryGetNetworkResource] ) {
					theTask.state = NMTaskExecutionStateConnectionActive;
					request = [theTask URLRequest];
					//					if ( theTask.command == TBMessageTaskCommandUploadAttachment ) {
					//						[self configureUploadURLRequest:request forTask:theTask];
					//					}
					conn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
					key = [NSNumber numberWithUnsignedInteger:(NSUInteger)conn];
					[connectionPool setObject:conn forKey:key];
					[theTask prepareDataBuffer];
					[taskPool setObject:theTask forKey:key];
					[conn release];
				} else {
					transverseWholeArray = NO;
					break;
				}
			}
		}
	}
	if ( transverseWholeArray ) {
		// remove the timer
		[atimer invalidate];
		self.connectionExecutionTimer = nil;
	}
}

/*!
 Run in the worker thread of TBConnectionController
 */
- (void)createConnection {
	NMTask *theTask;
	NSMutableURLRequest *request;
	NSURLConnection *conn;
	NSNumber *key;
	BOOL didRunOutResource = NO;
	@synchronized(pendingTaskBuffer) {
		for (theTask in pendingTaskBuffer) {
			if ( theTask.state == NMTaskExecutionStateWaitingInConnectionQueue ) {
				if ( [self tryGetNetworkResource] ) {
					theTask.state = NMTaskExecutionStateConnectionActive;
					request = [theTask URLRequest];
					conn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
					key = [NSNumber numberWithUnsignedInteger:(NSUInteger)conn];
					[connectionPool setObject:conn forKey:key];
					[theTask prepareDataBuffer];
					[taskPool setObject:theTask forKey:key];
					[conn release];
					
					// create notification object
					NSString * notStr = [theTask willLoadNotificationName];
					//TODO: re-enable later
//					if ( notStr ) [scheduler postNotificationOnMainThread:notStr object:self userInfo:nil];
				} else {
					didRunOutResource = YES;
					break;
				}
			}
		}
	}
	if ( didRunOutResource ) {
		[self enableConnectionCreationCheck];
	}
}

- (void)postConnectionErrorNotificationOnMainThread:(NSError *)error forTask:(NMTask *)task {
	NSNotification * n = [NSNotification notificationWithName:NMURLConnectionErrorNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[error localizedDescription], @"message", [NSNumber numberWithInteger:[error code]], @"code", nil]];
	[defaultCenter performSelectorOnMainThread:@selector(postNotification:) withObject:n waitUntilDone:NO];
}


#pragma mark Resources management
/*!
 Return the call rate in the past 1 sec.
 */
- (BOOL)isBelowMaximumRate {
	NSUInteger c = [connectionPool count];
	
	if ( c > NM_MAX_NUMBER_OF_CONCURRENT_CONNECTION - 1 ) {
		// there's 5 or more connections in the pool. it's possible that we have met the allowable connection rate
		if ( [connectionDateLog count] == 0 || [[connectionDateLog objectAtIndex:0] timeIntervalSinceNow] >= -1.0 ) {
			// we can't grant access because the earliest connection is still within 1 sec away from now.
			return NO;
		} else {
			[connectionDateLog removeObjectAtIndex:0];
		}
	}
	return YES;
}

- (BOOL)tryGetNetworkResource {
	BOOL ret = NO;
	[networkConnectionLock lock];
	if (numberOfConnections < maxNumberOfConnection && [self isBelowMaximumRate] ) {
		numberOfConnections++;
		ret = YES;
	}
	[networkConnectionLock unlock];
#ifdef DEBUG_CONNECTION_CONTROLLER
	if ( ret ) NSLog(@"obtained connection resource");
	else NSLog(@"can't get connection resource");
#endif
	return ret;
}

- (void)returnNetworkResource {
	[networkConnectionLock lock];
	numberOfConnections--;
	[networkConnectionLock unlock];
}

- (void)cancelConnectionForTasks:(NSArray *)aTasks {
	
}

#pragma mark NSURLConnection delegate methods
//- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
//	// network call rate control (5 calls/s)
//	[connectionDateLog addObject:[NSDate date]];
//	NSNumber *key = [NSNumber numberWithUnsignedInteger:(NSUInteger)connection];
//	// add response object
//	NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
//	NMTask * task = [taskPool objectForKey:key];
//	task.statusCode = [httpResponse statusCode];
//}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to receivedData.
    // receivedData is an instance variable declared elsewhere.
 	NSNumber *key = [NSNumber numberWithUnsignedInteger:(NSUInteger)connection];
	NMTask * task = [taskPool objectForKey:key];
	[task.buffer appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // release the connection, and the data object
    // receivedData is declared as a method instance elsewhere
	NSNumber *key = [NSNumber numberWithUnsignedInteger:(NSUInteger)connection];
	[connectionPool removeObjectForKey:key];
	NMTask *task = [taskPool objectForKey:key];
	NSLog(@"error received");
	// call error handling
	[self postConnectionErrorNotificationOnMainThread:error forTask:task];
	// release the task
	[taskPool removeObjectForKey:key];
	@synchronized(pendingTaskBuffer) {
		[pendingTaskBuffer removeObject:task];
	}
	
	// inform the user
#ifdef DEBUG_CONNECTION_CONTROLLER 
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
#endif
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	// return network connection resources
	NSNumber *key = [NSNumber numberWithUnsignedInteger:(NSUInteger)connection];
	[connectionPool removeObjectForKey:key];
	[self returnNetworkResource];
	NMTask *theTask = [taskPool objectForKey:key];
	
#ifdef DEBUG_CONNECTION_CONTROLLER
    NSLog(@"Succeeded! Received %d bytes of data, response code %d",[theTask.buffer length], theTask.statusCode);
	if ( [theTask.buffer length] < 200 ) {
		NSString *str = [[NSString alloc] initWithData:theTask.buffer encoding:NSUTF8StringEncoding];
		NSLog(@"%@", str);
		[str release];
	}
#endif
	
	theTask.state = NMTaskExecutionStateConnectionCompleted;
	
	// pass the completed task to data controller for processing
//	if ( theTask.command > NMCommandImageDownloadCommandBoundary ) {
//		[dataController storeImageForTask:(NMImageDownloadTask *)theTask];
//	} else {
	//TODO: re-enable later
//		[dataController createDataParsingOperationForTask:theTask];
//	}
	
    // release the connection, and the data object
	[taskPool removeObjectForKey:key];
	// remove task
	@synchronized(pendingTaskBuffer) {
		[pendingTaskBuffer removeObject:theTask];
	}
}

@end
