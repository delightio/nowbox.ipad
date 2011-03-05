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

@implementation NMTaskQueueController

@synthesize managedObjectContext;
@synthesize networkController;
@synthesize dataController;

- (void)dealloc {
	[managedObjectContext release];
	[super dealloc];
}

- (void)issueGetChannels {
	NMGetChannelsTask * task = [[NMGetChannelsTask alloc] init];
	
	[task release];
}

@end
