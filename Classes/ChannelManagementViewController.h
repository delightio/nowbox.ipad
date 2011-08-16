//
//  ChannelManagementViewController.h
//  ipad
//
//  Created by Bill So on 13/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CategoriesOrientedTableView;

@interface ChannelManagementViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate> {
	CategoriesOrientedTableView *categoriesTableView;
	UITableView *channelsTableView;
	UIView *containerView;
	
	NSFetchedResultsController * categoryFetchedResultsController;
	NSManagedObjectContext * managedObjectContext;
	
	NSIndexPath * selectedIndexPath;
	NSArray * selectedChannelArray;
	
	BOOL viewPushedByNavigationController;
}

@property (retain, nonatomic) IBOutlet CategoriesOrientedTableView *categoriesTableView;
@property (retain, nonatomic) IBOutlet UITableView *channelsTableView;
@property (retain, nonatomic) IBOutlet UIView *containerView;
@property (nonatomic, retain) NSFetchedResultsController * categoryFetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NSIndexPath * selectedIndexPath;
@property (nonatomic, retain) NSArray * selectedChannelArray;

-(float)categoryCellWidthFromString:(NSString *)text;

@end
