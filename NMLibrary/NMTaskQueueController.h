//
//  NMTaskQueueController.h
//  Nowmov
//
//  Created by Bill So on 05/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//


@class NMNetworkController;
@class NMDataController;


@interface NMTaskQueueController : NSObject {
	NSManagedObjectContext * managedObjectContext;
	
	NMNetworkController * networkController;
	NMDataController * dataController;
}

@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NMNetworkController * networkController;
@property (nonatomic, retain) NMDataController * dataController;

- (void)issueGetChannels;

@end
