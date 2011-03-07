//
//  NMTaskQueueController.m
//  Nowmov
//
//  Created by Bill So on 05/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTaskQueueController.h"
#import "NMTaskType.h"
#import "NMNetworkController.h"
#import "NMDataController.h"

static NMTaskQueueController * sharedTaskQueueController_ = nil;

@implementation NMTaskQueueController

@synthesize managedObjectContext;
@synthesize networkController;
@synthesize dataController;

+ (NMTaskQueueController *)sharedTaskQueueController {
	if ( sharedTaskQueueController_ == nil ) {
		sharedTaskQueueController_ = [[NMTaskQueueController alloc] init];
	}
	return sharedTaskQueueController_;
}

- (id)init {
	self = [super init];
	
	dataController = [[NMDataController alloc] init];
	networkController = [[NMNetworkController alloc] init];
	networkController.dataController = dataController;
	
	return self;
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)moc {
	if ( managedObjectContext ) {
		if ( managedObjectContext == moc ) {
			return;
		}
		[managedObjectContext release];
		managedObjectContext = nil;
		dataController.managedObjectContext = nil;
	}
	if ( moc ) {
		managedObjectContext = [moc retain];
		dataController.managedObjectContext = moc;
	}
}

- (void)dealloc {
	[managedObjectContext release];
	[dataController release];
	[networkController release];
	[super dealloc];
}

#pragma mark Queue tasks to network controller
- (void)issueGetChannels {
	NMGetChannelsTask * task = [[NMGetChannelsTask alloc] init];
	[networkController addNewConnectionForTask:task];
	[task release];
}

- (void)issueGetVideoListForChannel:(NMChannel *)chnObj isNew:(BOOL)aNewChn {
	// if it's a new channel, we should have special handling on fail
	NMGetChannelVideosTask * task = [[NMGetChannelVideosTask alloc] init];
	[networkController addNewConnectionForTask:task];
	[task release];
}

@end
