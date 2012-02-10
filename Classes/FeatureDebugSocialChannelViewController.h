//
//  FeatureDebugSocialChannelViewController.h
//  ipad
//
//  Created by Bill So on 2/10/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FeatureDebugSocialChannelViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, retain) NSNumber * channelType;
@property (nonatomic, retain) NSFetchedResultsController * fetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;

@end
