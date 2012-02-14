//
//  FeatureDebugVideoListViewController.h
//  ipad
//
//  Created by Bill So on 2/13/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMLibrary.h"

@interface FeatureDebugVideoListViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, retain) NSFetchedResultsController * fetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NMChannel * channel;

@end
