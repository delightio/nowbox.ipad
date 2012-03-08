//
//  FeatureDebugMentionsViewController.h
//  ipad
//
//  Created by Bill So on 3/6/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMLibrary.h"

@interface FeatureDebugMentionsViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, retain) NSFetchedResultsController * fetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NMConcreteVideo * concreteVideo;

@end
