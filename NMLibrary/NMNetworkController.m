//
//  NMNetworkController.m
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMNetworkController.h"
#import "NMDataController.h"
#import "NMDataType.h"

#define NM_MAX_NUMBER_OF_CONCURRENT_CONNECTION		8

NSString * const NMURLConnectionErrorNotification = @"NMURLConnectionErrorNotification";

@implementation NMNetworkController

@synthesize connectionExecutionTimer;
@synthesize dataController;
@synthesize controlThread;

- (id)init {
	self = [super init];
	activeChannelThumbnailDownloadSet = [[NSMutableSet alloc] init];
	taskPool = [[NSMutableDictionary alloc] init];
	connectionPool = [[NSMutableDictionary alloc] init];
	pendingTaskBuffer = [[NSMutableArray alloc] init];
	connectionDateLog = [[NSMutableArray alloc] initWithCapacity:NM_MAX_NUMBER_OF_CONCURRENT_CONNECTION];
	networkConnectionLock = [[NSLock alloc] init];
	isDone = NO;
	maxNumberOfConnection = NM_MAX_NUMBER_OF_CONCURRENT_CONNECTION;
	defaultCenter = [[NSNotificationCenter defaultCenter] retain];
	[NSThread detachNewThreadSelector:@selector(controlThreadMain:) toTarget:self withObject:nil];
	return self;
}

- (void)dealloc {
	isDone = YES;
	[activeChannelThumbnailDownloadSet release];
	[defaultCenter release];
	[taskPool release];
	[connectionPool release];
	[pendingTaskBuffer release];
	[networkConnectionLock release];
	[connectionDateLog release];
	[dataController release];
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

- (void)postNotificationOnMainThread:(NSString *)notificationName object:(id)notificationSender userInfo:(NSDictionary *)userInfo {
	NSNotification * notification = [NSNotification notificationWithName:notificationName object:notificationSender userInfo:userInfo];
	[self performSelectorOnMainThread:@selector(performPostNotification:) withObject:notification waitUntilDone:NO];
}

// this method should run in main thread
- (void)performPostNotification:(id)arg {
	[[NSNotificationCenter defaultCenter] postNotification:arg];
}

- (BOOL)downloadInProgressForURLString:(NSString *)urlStr {
	BOOL b;
	@synchronized(activeChannelThumbnailDownloadSet) {
		b = [activeChannelThumbnailDownloadSet containsObject:urlStr];
	}
	return b;
}

#pragma mark Connection management
- (void)addNewConnectionForTasks:(NSArray *)tasks {
	@synchronized(pendingTaskBuffer) {
		[pendingTaskBuffer addObjectsFromArray:tasks];
		NMTask *t;
		for (t in tasks) {
			t.state = NMTaskExecutionStateWaitingInConnectionQueue;
			if ( t.command == NMCommandGetChannelThumbnail ) {
				@synchronized(activeChannelThumbnailDownloadSet) {
					NMImageDownloadTask * imgTask = (NMImageDownloadTask *)t;
					[activeChannelThumbnailDownloadSet addObject:imgTask.imageURLString];
				}
			}
		}
	}
	[self performSelector:@selector(createConnection) onThread:controlThread withObject:nil waitUntilDone:NO];
}

- (void)addNewConnectionForTask:(NMTask *)aTask {
	@synchronized(pendingTaskBuffer) {
		[pendingTaskBuffer addObject:aTask];
		aTask.state = NMTaskExecutionStateWaitingInConnectionQueue;
		if ( aTask.command == NMCommandGetChannelThumbnail ) {
			@synchronized(activeChannelThumbnailDownloadSet) {
				NMImageDownloadTask * imgTask = (NMImageDownloadTask *)aTask;
				[activeChannelThumbnailDownloadSet addObject:imgTask.imageURLString];
			}
		}
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
					[taskPool setObject:theTask forKey:key];
					[conn release];
					
					// create notification object
					NSString * notStr = [theTask willLoadNotificationName];
					if ( notStr ) [self postNotificationOnMainThread:notStr object:self userInfo:nil];
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
	NSNotification * n = [NSNotification notificationWithName:[task didFailNotificationName] object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[error localizedDescription], @"message", [NSNumber numberWithInteger:[error code]], @"code", task, @"task", nil]];
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

- (void)cancelPlaybackRelatedTasksForChannel:(NMChannel *)chnObj {
	NSString * chname = chnObj.title;
	@synchronized(pendingTaskBuffer) {
		for (NMTask * task in pendingTaskBuffer) {
			if ( task.state == NMTaskExecutionStateConnectionActive ) {
				switch (task.command) {
					case NMCommandGetAllChannels:
					case NMCommandGetFriendChannels:
					case NMCommandGetTopicChannels:
					case NMCommandGetTrendingChannels:
					case NMCommandGetChannelVideoList:
					case NMCommandGetYouTubeDirectURL:
						// cancel the task
						if ( [task.channelName isEqualToString:chname]) {
							task.state = NMTaskExecutionStateCanceled;
						}
						break;
					default:
						break;
				}
			}
		}
	}
}

#pragma mark NSURLConnection delegate methods
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	// network call rate control (5 calls/s)
	[connectionDateLog addObject:[NSDate date]];
	NSNumber *key = [NSNumber numberWithUnsignedInteger:(NSUInteger)connection];
	// add response object
	NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
	NMTask * task = [taskPool objectForKey:key];
	task.httpStatusCode = [httpResponse statusCode];
	if ( task.command == NMCommandGetChannelThumbnail ) {
		NMImageDownloadTask * imgTask = (NMImageDownloadTask *)task;
		imgTask.httpResponse = (NSHTTPURLResponse *)response;
	}
	// create buffer
	[task prepareDataBuffer];
#ifdef DEBUG_CONNECTION_CONTROLLER
	NSLog(@"received response %d", task.httpStatusCode);
#endif
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to receivedData.
    // receivedData is an instance variable declared elsewhere.
 	NSNumber *key = [NSNumber numberWithUnsignedInteger:(NSUInteger)connection];
	NMTask * task = [taskPool objectForKey:key];
	// check if the task has been marked canceled
	if ( task.state == NMTaskExecutionStateCanceled ) {
		[connectionPool removeObjectForKey:key];
		[connection cancel];
		// release the connection, and the data object
		[taskPool removeObjectForKey:key];
		// remove task
		@synchronized(pendingTaskBuffer) {
			[pendingTaskBuffer removeObject:task];
		}
	} else {
		[task.buffer appendData:data];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // release the connection, and the data object
    // receivedData is declared as a method instance elsewhere
	NSNumber *key = [NSNumber numberWithUnsignedInteger:(NSUInteger)connection];
	[connectionPool removeObjectForKey:key];
	NMTask *task = [taskPool objectForKey:key];
	// call error handling
	if ( task.state != NMTaskExecutionStateCanceled ) {
		task.state = NMTaskExecutionStateConnectionFailed;
		[self postConnectionErrorNotificationOnMainThread:error forTask:task];
	}
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
	
	if ( theTask.state == NMTaskExecutionStateCanceled ) {
		// release the connection, and the data object
		[taskPool removeObjectForKey:key];
		// remove task
		@synchronized(pendingTaskBuffer) {
			[pendingTaskBuffer removeObject:theTask];
		}
		return;
	}
	
#ifdef DEBUG_CONNECTION_CONTROLLER
    NSLog(@"Succeeded! Received %d bytes of data, response code %d",[theTask.buffer length], theTask.httpStatusCode);
	if ( [theTask.buffer length] < 200 ) {
		NSString *str = [[NSString alloc] initWithData:theTask.buffer encoding:NSUTF8StringEncoding];
		NSLog(@"%@", str);
		[str release];
	}
#endif
	
	theTask.state = NMTaskExecutionStateConnectionCompleted;
	
	if ( theTask.command == NMCommandGetChannelThumbnail ) {
		@synchronized(activeChannelThumbnailDownloadSet) {
			[activeChannelThumbnailDownloadSet removeObject:((NMImageDownloadTask *)theTask).imageURLString];
		}
	}
	
	// pass the completed task to data controller for processing
//	if ( theTask.command > NMCommandImageDownloadCommandBoundary ) {
//		[dataController storeImageForTask:(NMImageDownloadTask *)theTask];
//	} else {
	if ( theTask.httpStatusCode >= 400 ) {
		// fire error notification right here
		NSNotification * n = [NSNotification notificationWithName:[theTask didFailNotificationName] object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"HTTP status code indicates error", @"message", [NSNumber numberWithInteger:theTask.httpStatusCode], @"code", theTask, @"task", nil]];
		[defaultCenter performSelectorOnMainThread:@selector(postNotification:) withObject:n waitUntilDone:NO];
	} else {
		[dataController createDataParsingOperationForTask:theTask];
	}
	
    // release the connection, and the data object
	[taskPool removeObjectForKey:key];
	// remove task
	@synchronized(pendingTaskBuffer) {
		[pendingTaskBuffer removeObject:theTask];
	}
}

@end
