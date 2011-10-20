//
//  NMNetworkController.h
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTaskType.h"
#import "NMChannel.h"


@class NMDataController;

@interface NMNetworkController : NSObject {
	NSMutableDictionary * connectionPool;
	NSMutableDictionary * taskPool;
	NSMutableArray * pendingTaskBuffer;
	NSLock * pendingTaskBufferLock;
	
	//TODO: not sure if needed
//	NMTaskQueueScheduler * scheduler;
	NMDataController * dataController;
	
	NSThread *controlThread;
	BOOL isDone;
	NSTimer *connectionExecutionTimer;
	NSNotificationCenter * defaultCenter;
	
	// network connection resources control
	NSLock *networkConnectionLock;
	NSInteger numberOfConnections, maxNumberOfConnection;
	NSMutableArray *connectionDateLog;
	
	NSMutableIndexSet * commandIndexPool;
	
	NSDate * errorWindowStartDate;
	
	// channel thumbnail_uri cache
//	NSMutableSet * activeChannelThumbnailDownloadSet;
}

@property (nonatomic, retain) NSTimer *connectionExecutionTimer;
//@property (nonatomic, assign) NMTaskQueueScheduler *scheduler;
@property (nonatomic, retain) NMDataController * dataController;
@property (nonatomic, assign) NSThread *controlThread;

@property (nonatomic, retain) NSDate * errorWindowStartDate;

//- (BOOL)downloadInProgressForURLString:(NSString *)urlStr;

- (void)addNewConnectionForTasks:(NSArray *)tasks;
/*!
 add a connection to the connection queue
 */
- (void)addNewConnectionForTask:(NMTask *)aTask;
/*!
 Network connection resources management. All operations should call getNetworkResource to get a permission to create network connection. This gives control to JPDataController the control over how many network connections the system can have at the same time.
 */
- (BOOL)tryGetNetworkResource;
- (void)returnNetworkResource;

//- (void)tryCancelImageDownloadWithURLStringsNotIn:(NSArray *)urlAy;
//- (void)tryCancelDownloadWithCaller:(id)aCaller;

- (void)postConnectionErrorNotificationOnMainThread:(NSError *)error forTask:(NMTask *)task;

- (void)cancelPlaybackRelatedTasksForChannel:(NMChannel *)chnObj;
- (void)forceCancelAllTasks;

@end
