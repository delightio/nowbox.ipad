//
//  HomeGridDataSource.h
//  ipad
//
//  Created by Chris Haugli on 2/7/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "GridDataSource.h"
#import "TwitterAccountPickerViewController.h"

@interface HomeGridDataSource : GridDataSource <TwitterAccountPickerViewControllerDelegate, UIAlertViewDelegate> {
    UIViewController *viewController;
    NSMutableSet *refreshingChannels;
    
    BOOL facebookButtonPressed;
}

@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

- (id)initWithGridView:(PagingGridView *)aGridView viewController:(UIViewController *)aViewController managedObjectContext:(NSManagedObjectContext *)aManagedObjectContext;

@end
