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
@property (nonatomic, readonly) NMNetworkController * networkController;
@property (nonatomic, readonly) NMDataController * dataController;

+ (NMTaskQueueController *)sharedTaskQueueController;

- (void)issueGetChannels;

@end
