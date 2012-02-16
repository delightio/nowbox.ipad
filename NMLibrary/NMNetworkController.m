//
//  NMNetworkController.m
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMNetworkController.h"
#import "NMDataController.h"
#import "NMURLConnection.h"
#import "NMDataType.h"
#import "NMTaskType.h"
#ifdef DEBUG_CONNECTION_CONTROLLER
#import "NMVideo.h"
#import "NMConcreteVideo.h"
#endif

#define NM_MAX_NUMBER_OF_CONCURRENT_CONNECTION		8
NSString * NMServiceErrorDomain = @"NMServiceErrorDomain";

@interface NMNetworkController (PrivateMethods)

// for-loop that iterates through all elements
- (BOOL)schedulePendingTasks;
- (void)createConnection;

@end

@implementation NMNetworkController

@synthesize connectionExecutionTimer;
@synthesize dataController;
@synthesize controlThread;
@synthesize errorWindowStartDate;
@synthesize tokenRenewMode;
@synthesize suspendFacebook;

- (id)init {
	self = [super init];
	facebookCommandRange = NSMakeRange(NMCommandFacebookCommandLowerBound, NMCommandFacebookCommandUpperBound - NMCommandFacebookCommandLowerBound + 1);
	commandIndexPool = [[NSMutableIndexSet alloc] init];
	pendingDeleteCommandIndexPool = [[NSMutableIndexSet alloc] init];
	connectionPool = [[NSMutableSet alloc] initWithCapacity:8];
	facebookConnectionPool = [[NSMutableSet alloc] initWithCapacity:8];
	pendingTaskBuffer = [[NSMutableArray alloc] init];
	connectionDateLog = [[NSMutableArray alloc] initWithCapacity:NM_MAX_NUMBER_OF_CONCURRENT_CONNECTION];
	networkConnectionLock = [[NSLock alloc] init];
	pendingTaskBufferLock = [[NSLock alloc] init];
	isDone = NO;
	maxNumberOfConnection = NM_MAX_NUMBER_OF_CONCURRENT_CONNECTION;
	defaultCenter = [[NSNotificationCenter defaultCenter] retain];
	[NSThread detachNewThreadSelector:@selector(controlThreadMain:) toTarget:self withObject:nil];
	self.errorWindowStartDate = [NSDate distantPast];
	
	/* By default, the Cocoa URL loading system uses a small shared memory cache.
	 We don't need this cache, so we set it to zero when the application launches. */
	
    /* turn off the NSURLCache shared cache */
	
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0
                                                            diskCapacity:0
                                                                diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];
    [sharedCache release];
	
	return self;
}

- (void)dealloc {
	isDone = YES;
	[commandIndexPool release];
	[pendingDeleteCommandIndexPool release];
	[defaultCenter release];
	[connectionPool release];
	[facebookConnectionPool release];
	[pendingTaskBuffer release];
	[networkConnectionLock release];
	[pendingTaskBufferLock release];
	[connectionDateLog release];
	[dataController release];
	[errorWindowStartDate release];
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

//- (BOOL)downloadInProgressForURLString:(NSString *)urlStr {
//	BOOL b;
//	@synchronized(activeChannelThumbnailDownloadSet) {
//		b = [activeChannelThumbnailDownloadSet containsObject:urlStr];
//	}
//	return b;
//}

- (void)debugPrintCommandPoolStatus {
	NSLog(@"======\nCommand index status");
	[commandIndexPool enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		NSLog(@"%d", idx);
	}];
	NSLog(@"======");
}

#pragma mark Connection management
- (void)addNewConnectionForTasks:(NSArray *)tasks {
	[pendingTaskBufferLock lock];
	NMTask *t;
	if ( suspendFacebook ) {
		// check if there's any facebook tasks
		for (t in tasks) {
			if ( NSLocationInRange(t.command, facebookCommandRange ) ) {
				continue;
			}
			[pendingTaskBuffer addObject:t];
			t.state = NMTaskExecutionStateWaitingInConnectionQueue;
		}
	} else {
		[pendingTaskBuffer addObjectsFromArray:tasks];
		for (t in tasks) {
			t.state = NMTaskExecutionStateWaitingInConnectionQueue;
		}
	}
	[pendingTaskBufferLock unlock];
	[self performSelector:@selector(createConnection) onThread:controlThread withObject:nil waitUntilDone:NO];
}

- (void)addNewConnectionForTask:(NMTask *)aTask {
	if ( suspendFacebook && NSLocationInRange(aTask.command, facebookCommandRange ) ) {
		return;
	}
	[pendingTaskBufferLock lock];
	[pendingTaskBuffer addObject:aTask];
	aTask.state = NMTaskExecutionStateWaitingInConnectionQueue;
	[pendingTaskBufferLock unlock];
	[self performSelector:@selector(createConnection) onThread:controlThread withObject:nil waitUntilDone:NO];
}

- (void)addNewConnectionForImmediateTask:(NMTask *)aTask {
	[pendingTaskBufferLock lock];
	[pendingTaskBuffer addObject:aTask];
	aTask.state = NMTaskExecutionStateWaitingInConnectionQueue;
	[pendingTaskBufferLock unlock];
	[self performSelector:@selector(createImmediateConnection:) onThread:controlThread withObject:aTask waitUntilDone:NO];
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
	BOOL didRunOutResource = [self schedulePendingTasks];
	if ( !didRunOutResource ) {
		[atimer invalidate];
		self.connectionExecutionTimer = nil;
	}
}

- (BOOL)schedulePendingTasks {
	// if in token renew mode, do not schedule any task
	if ( tokenRenewMode ) return NO;
	// for-loop that iterates through all elements. Return YES if we exit running out of network connection resources
	NMTask *theTask;
	NSURLRequest *request;
	NMURLConnection *conn;
	BOOL didRunOutResource = NO;
	NSMutableArray * rmTaskAy = nil;
	NSInteger taskIdx;
	[pendingTaskBufferLock lock];
	for (theTask in pendingTaskBuffer) {
		if ( theTask.state == NMTaskExecutionStateWaitingInConnectionQueue ) {
			taskIdx = [theTask commandIndex];
			// pendingDeleteCommandIndexPool - delete an item only once. This avoids the case where same 2 tasks, both not executed yet, are deleted all together.
			if ( [commandIndexPool containsIndex:taskIdx] && ![pendingDeleteCommandIndexPool containsIndex:taskIdx] ) {
				// remove the task without performing it
				if ( rmTaskAy == nil ) {
					rmTaskAy = [NSMutableArray arrayWithCapacity:2];
				}
				[pendingDeleteCommandIndexPool addIndex:taskIdx];
				[rmTaskAy addObject:theTask];
#ifdef DEBUG_CONNECTION_CONTROLLER
				NSLog(@"Network Controller: command repeated. Discard Task: %d", taskIdx);
#endif
				continue;
			} 
			if ( [self tryGetNetworkResource] ) {
#ifdef DEBUG_CONNECTION_CONTROLLER
				NSLog(@"Network Controller: added command: %d", taskIdx);
#endif
				// add command index to the pool only when we have enough resource
				[commandIndexPool addIndex:taskIdx];
				
				theTask.state = NMTaskExecutionStateConnectionActive;
				theTask.sequenceLog = taskLogCount++;
				NMCommand cmd = theTask.command;
				if ( cmd > NMCommandFacebookCommandLowerBound && cmd < NMCommandFacebookCommandUpperBound ) {
					NMFacebookTask * fbTask = (NMFacebookTask *)theTask;
					FBRequest * fbRequest = [fbTask facebookRequestForController:self];
					fbRequest.task = fbTask;
					[facebookConnectionPool addObject:fbRequest];
				} else {
					// create the connection as normal
					request = [theTask URLRequest];
					conn = [[NMURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
					conn.task = theTask;
					[connectionPool addObject:conn];
					[conn release];
					break;
				}
				
				// create notification object
				NSString * notStr = [theTask willLoadNotificationName];
				if ( notStr ) [self postNotificationOnMainThread:notStr object:self userInfo:nil];
			} else {
				didRunOutResource = YES;
				break;
			}
		}
	}
	// remove these commands
	if ( rmTaskAy ) [pendingTaskBuffer removeObjectsInArray:rmTaskAy];
	[pendingDeleteCommandIndexPool removeAllIndexes];
	[pendingTaskBufferLock unlock];
	return didRunOutResource;
}

/*!
 Run in the worker thread of TBConnectionController
 */
- (void)createConnection {
	BOOL didRunOutResource = [self schedulePendingTasks];
	if ( didRunOutResource ) {
		[self enableConnectionCreationCheck];
	}
}

- (void)createImmediateConnection:(NMTask *)theTask {
	[commandIndexPool addIndex:[theTask commandIndex]];
	
	theTask.state = NMTaskExecutionStateConnectionActive;
	NMURLConnection *conn = [[NMURLConnection alloc] initWithRequest:[theTask URLRequest] delegate:self startImmediately:YES];
	conn.task = theTask;
	[connectionPool addObject:conn];
	[conn release];
	
	// create notification object
	NSString * notStr = [theTask willLoadNotificationName];
	if ( notStr ) [self postNotificationOnMainThread:notStr object:self userInfo:nil];
}

- (void)postConnectionErrorNotificationOnMainThread:(NSError *)error forTask:(NMTask *)task {
	NSNotification * n = [NSNotification notificationWithName:[task didFailNotificationName] object:task userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error, @"error", task, @"task", nil]];
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
	[pendingTaskBufferLock lock];
	for (NMTask * task in pendingTaskBuffer) {
		if ( task.state == NMTaskExecutionStateConnectionActive ) {
			switch (task.command) {
				case NMCommandGetAllChannels:
				case NMCommandGetSubscribedChannels:
				case NMCommandGetMoreVideoForChannel:
					// cancel the task
					if ( chnObj && [task.targetID isEqualToNumber:chnObj.nm_id]) {
						task.state = NMTaskExecutionStateCanceled;
					}
					break;
				case NMCommandGetYouTubeDirectURL:
					// cancel the task
					task.state = NMTaskExecutionStateCanceled;
					break;
				default:
					break;
			}
		}
	}
	[pendingTaskBufferLock unlock];
}

- (void)cancelTaskWithCommandSet:(NSIndexSet *)aCmd {
	[pendingTaskBufferLock lock];
	// go through all existing connection objects first
	NMURLConnection * connObj;
	NMTask * task;
	for (connObj in connectionPool) {
		task = connObj.task;
		if ( [aCmd containsIndex:task.command] ) {
			task.state = NMTaskExecutionStateCanceled;
			// the task has active connection.
			[connectionPool removeObject:connObj];
			[connObj cancel];
			// release the connection, and the data object
			[commandIndexPool removeIndex:[task commandIndex]];
			// remove task
			[pendingTaskBuffer removeObject:task];
			[self returnNetworkResource];
		}
	}
	for (NMTask * task in pendingTaskBuffer) {
		if ( [aCmd containsIndex:task.command] ) {
			// remove the task
			[pendingTaskBuffer removeObject:task];
		}
	}
	[pendingTaskBufferLock unlock];
}

- (void)cancelSearchTasks {
	[pendingTaskBufferLock lock];
	for (NMTask * task in pendingTaskBuffer) {
		switch (task.command) {
			case NMCommandSearchChannels:
				// cancel the task
				if ( task.state == NMTaskExecutionStateConnectionActive ) {
					task.state = NMTaskExecutionStateCanceled;
				}
				break;
			default:
				break;
		}
	}
	[pendingTaskBufferLock unlock];
}

- (void)forceCancelAllTasks {
	// cancel the connection
	NSURLConnection * conn;
	NMTask * theTask;
	for (conn in connectionPool) {
		[conn cancel];
		[self returnNetworkResource];
		if ( [theTask didCancelNotificationName] ) {
			[self postNotificationOnMainThread:[theTask didCancelNotificationName] object:self userInfo:[theTask cancelUserInfo]];
		}
	}
	[connectionPool removeAllObjects];
	[commandIndexPool removeAllIndexes];
	// clear up tasks not yet executed
	[pendingTaskBufferLock lock];
	[pendingTaskBuffer removeAllObjects];
	[pendingTaskBufferLock unlock];
}

- (void)showAlertForError:(NSError *)error {
	// this method runs in main thread
	[[NSNotificationCenter defaultCenter] postNotificationName:NMShowErrorAlertNotification object:self userInfo:[NSDictionary dictionaryWithObject:error forKey:@"error"]];
}

- (void)setTokenRenewMode:(BOOL)abool {
	tokenRenewMode = abool;
	if ( !tokenRenewMode ) {
		// start running tasks again
		[self performSelector:@selector(createConnection) onThread:controlThread withObject:nil waitUntilDone:NO];
	} else {
		taskLogMark = taskLogCount;
	}
}

#pragma mark NSURLConnection delegate methods
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
	return nil;
}

- (void)connection:(NMURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	// network call rate control (5 calls/s)
	[connectionDateLog addObject:[NSDate date]];
	// add response object
	NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
	NMTask * task = connection.task;
	task.httpStatusCode = [httpResponse statusCode];
	switch (task.command) {
		case NMCommandGetChannelThumbnail:
		case NMCommandGetAuthorThumbnail:
		case NMCommandGetVideoThumbnail:
		case NMCommandGetPreviewThumbnail:
		{
			NMImageDownloadTask * imgTask = (NMImageDownloadTask *)task;
			imgTask.httpResponse = (NSHTTPURLResponse *)response;
			break;
		}			
		default:
			break;
	}
	// create buffer
	[task prepareDataBuffer];
#ifdef DEBUG_CONNECTION_CONTROLLER
	NSLog(@"received response %d", task.httpStatusCode);
#endif
}

- (void)connection:(NMURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to receivedData.
    // receivedData is an instance variable declared elsewhere.
	NMTask * task = connection.task;
	// check if the task has been marked canceled
	if ( task.state == NMTaskExecutionStateCanceled ) {
		[connectionPool removeObject:connection];
		[connection cancel];
		// release the connection, and the data object
		[commandIndexPool removeIndex:[task commandIndex]];
		// remove task
		[pendingTaskBufferLock lock];
		[pendingTaskBuffer removeObject:task];
		[pendingTaskBufferLock unlock];
		[self returnNetworkResource];
	} else {
		[task.buffer appendData:data];
	}
}

- (void)connection:(NMURLConnection *)connection didFailWithError:(NSError *)error {
    // release the connection, and the data object
    // receivedData is declared as a method instance elsewhere
	[self returnNetworkResource];
	NMTask * task = connection.task;
	// call error handling
	if ( task.state != NMTaskExecutionStateCanceled ) {
		task.state = NMTaskExecutionStateConnectionFailed;
		[self postConnectionErrorNotificationOnMainThread:error forTask:task];
	}
	// release the task
	[commandIndexPool removeIndex:[task commandIndex]];
	[pendingTaskBufferLock lock];
	[pendingTaskBuffer removeObject:task];
	[pendingTaskBufferLock unlock];
	
	// inform the user
#ifdef DEBUG_CONNECTION_CONTROLLER 
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
#endif
	// prompt user for any error
	if ( !tokenRenewMode && [errorWindowStartDate timeIntervalSinceDate:[NSDate date]] < -10.0 && [error code] == NSURLErrorNotConnectedToInternet ) {
		// only prompt user if the error happens outside the 10 sec window. We don't wanna prompt user about error mutiple times
		[self performSelectorOnMainThread:@selector(showAlertForError:) withObject:error waitUntilDone:NO];
		self.errorWindowStartDate = [NSDate date];
	}
	[connectionPool removeObject:connection];
	// check if we should retry for these errors: NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorTimedOut
	// if the app is experiencing "NSURLErrorNotConnectedToInternet" error for multiple times within a 10 sec window, stop retrying
}

- (void)connectionDidFinishLoading:(NMURLConnection *)connection {
	// return network connection resources
	[connection retain];
	[connectionPool removeObject:connection];
	[self returnNetworkResource];
	NMTask *theTask = connection.task;
	
	if ( theTask.state == NMTaskExecutionStateCanceled ) {
		[connection release];
		// release the connection, and the data object
		[commandIndexPool removeIndex:[theTask commandIndex]];
		// remove task
		[pendingTaskBufferLock lock];
		[pendingTaskBuffer removeObject:theTask];
		[pendingTaskBufferLock unlock];
		return;
	}
	
#ifdef DEBUG_CONNECTION_CONTROLLER
    NSLog(@"Succeeded! Received %d bytes of data, response code %d, cmd %d",[theTask.buffer length], theTask.httpStatusCode, theTask.command);
	if ( theTask.command == NMCommandGetYouTubeDirectURL ) {
		NMGetYouTubeDirectURLTask * uTask = (NMGetYouTubeDirectURLTask *)theTask;
		NSLog(@"video: %@ %@", uTask.video.video.title, uTask.video.video.nm_id);
	}
	if ( [theTask.buffer length] < 256 ) {
		NSString *str = [[NSString alloc] initWithData:theTask.buffer encoding:NSUTF8StringEncoding];
		NSLog(@"%@", str);
		[str release];
	}
#endif
	
	theTask.state = NMTaskExecutionStateConnectionCompleted;
	
	NSInteger scode = theTask.httpStatusCode;
	if ( scode >= 400 && !theTask.executeSaveActionOnError ) {
		if ( scode == 401 ) {
			if ( !tokenRenewMode && theTask.sequenceLog >= taskLogMark ) {
				// enable the mode 
				[[NMTaskQueueController sharedTaskQueueController] setTokenRenewMode:YES];
			}
			// ignore all error, recover the tasks
			[commandIndexPool removeIndex:[theTask commandIndex]];
			theTask.state = NMTaskExecutionStateWaitingInConnectionQueue;
			[connection release];
			return;
		} else {
			// fire error notification right here
			NSDictionary * errorInfo = [theTask failUserInfo];
			NSNotification * n = [NSNotification notificationWithName:[theTask didFailNotificationName] object:theTask userInfo:(errorInfo == nil ? [NSDictionary dictionaryWithObjectsAndKeys:@"HTTP status code indicates error", @"message", [NSNumber numberWithInteger:theTask.httpStatusCode], @"code", theTask, @"task", nil] : errorInfo)];
			[defaultCenter performSelectorOnMainThread:@selector(postNotification:) withObject:n waitUntilDone:NO];
//			NMCommand cmd = theTask.command;
//			if ( scode < 500 && scode != 404 && cmd != NMCommandSendEvent && cmd != NMCommandGetYouTubeDirectURL ) {
//				// this is authorization related error. post a pop up box to user
//				if ( [errorWindowStartDate timeIntervalSinceDate:[NSDate date]] < -10.0 ) {
//					// only prompt user if the error happens outside the 10 sec window. We don't wanna prompt user about error mutiple times
//					NSError * error = [NSError errorWithDomain:NMServiceErrorDomain code:scode userInfo:nil];
//					[self performSelectorOnMainThread:@selector(showAlertForError:) withObject:error waitUntilDone:NO];
//					self.errorWindowStartDate = [NSDate date];
//				}
//			}
		}
	} else {
		[dataController createDataParsingOperationForTask:theTask];
	}
	
    // release the connection, and the data object
	[connection release];
	[commandIndexPool removeIndex:[theTask commandIndex]];
	// remove task
	[pendingTaskBufferLock lock];
	[pendingTaskBuffer removeObject:theTask];
	[pendingTaskBufferLock unlock];
}

#pragma mark Facebook request
- (void)request:(FBRequest *)request didReceiveResponse:(NSURLResponse *)response {
//	NSLog(@"facebook call received response");
}

- (void)request:(FBRequest *)request didLoad:(id)result {
	NMFacebookTask * fbTask = request.task;
	
	if ( fbTask.state == NMTaskExecutionStateCanceled ) {
		// release the connection, and the data object
		[commandIndexPool removeIndex:[fbTask commandIndex]];
		// remove task
		[pendingTaskBufferLock lock];
		[pendingTaskBuffer removeObject:fbTask];
		[pendingTaskBufferLock unlock];
		[facebookConnectionPool removeObject:request];
		[self returnNetworkResource];
		return;
	}
	
	[fbTask setParsedObjectsForResult:result];
	[dataController createDataParsingOperationForTask:fbTask];
	
    // release the connection, and the data object
	[commandIndexPool removeIndex:[fbTask commandIndex]];
	// remove task
	[pendingTaskBufferLock lock];
	[pendingTaskBuffer removeObject:fbTask];
	[pendingTaskBufferLock unlock];
	[facebookConnectionPool removeObject:request];
	[self returnNetworkResource];
}

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
 	NMFacebookTask * fbTask = request.task;
   // release the connection, and the data object
	[commandIndexPool removeIndex:[fbTask commandIndex]];
	// remove task
	[pendingTaskBufferLock lock];
	[pendingTaskBuffer removeObject:fbTask];
	[pendingTaskBufferLock unlock];
	[facebookConnectionPool removeObject:request];
	[self returnNetworkResource];
}
@end
