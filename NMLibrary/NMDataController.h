//
//  NMDataController.h
//  Nowmov
//
//  Created by Bill So on 05/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTask.h"

@class NMChannel;

@interface NMDataController : NSObject {
	NSNotificationCenter * notificationCenter;
	NSOperationQueue * operationQueue;
	
	NSManagedObjectContext * managedObjectContext;
	NSPredicate * channelNamePredicateTemplate;
	NSPredicate * channelNamesPredicateTemplate;
}

@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;

- (void)createDataParsingOperationForTask:(NMTask *)atask;

// general data manipulation
- (void)deleteManagedObjects:(NSArray *)objs;
// channels
- (NMChannel *)insertNewChannel;
- (NSDictionary *)fetchChannelsForNames:(NSArray *)channelAy;

@end
