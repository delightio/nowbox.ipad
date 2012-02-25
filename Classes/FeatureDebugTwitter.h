//
//  FeatureDebugTwitter.h
//  ipad
//
//  Created by Bill So on 2/24/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMLibrary.h"

@interface FeatureDebugTwitter : UITableViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, retain) NSFetchedResultsController * fetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NMSocialInfo * socialInfo;

@end
