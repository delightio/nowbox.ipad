//
//  FeatureDebugFacebookCommentsAndLikes.h
//  ipad
//
//  Created by Bill So on 2/13/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMLibrary.h"

@interface FeatureDebugFacebookCommentsAndLikes : UITableViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, retain) NSFetchedResultsController * likesResultsController;
@property (nonatomic, retain) NSFetchedResultsController * commentsResultsController;
@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NMFacebookInfo * socialInfo;

@end
