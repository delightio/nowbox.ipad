//
//  ChannelManagementViewController.h
//  ipad
//
//  Created by Bill So on 13/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChannelManagementViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate> {
	UITableView *leftTableView;
	UITableView *rightTableView;
	
	NSFetchedResultsController * categoryFetchedResultsController;
	NSManagedObjectContext * managedObjectContext;
	
	NSIndexPath * selectedIndexPath;
	NSArray * selectedChannelArray;
	
	BOOL viewPushedByNavigationController;
}

@property (retain, nonatomic) IBOutlet UITableView *leftTableView;
@property (retain, nonatomic) IBOutlet UITableView *rightTableView;
@property (nonatomic, retain) NSFetchedResultsController * categoryFetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NSIndexPath * selectedIndexPath;
@property (nonatomic, retain) NSArray * selectedChannelArray;

@end
