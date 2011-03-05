//
//  NMDataController.h
//  Nowmov
//
//  Created by Bill So on 05/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTask.h"


@interface NMDataController : NSObject {
	NSNotificationCenter * notificationCenter;
	NSOperationQueue * operationQueue;
	NSManagedObjectContext * managedObjectContext;
}

@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;

- (void)createDataParsingOperationForTask:(NMTask *)atask;

@end
