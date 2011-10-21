//
//  ChannelManagementViewController.h
//  ipad
//
//  Created by Bill So on 13/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMStyleUtility.h"

@class CategoriesOrientedTableView;
@class NMChannel;
@class ChannelDetailViewController;

@interface ChannelManagementViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, UIAlertViewDelegate> {
	ChannelDetailViewController * channelDetailViewController;
	CategoriesOrientedTableView *categoriesTableView;
	UITableView *channelsTableView;
	UIView *containerView;
	
	NSFetchedResultsController * categoryFetchedResultsController;
	NSFetchedResultsController * myChannelsFetchedResultsController;
	NSManagedObjectContext * managedObjectContext;
	
	NSIndexPath * selectedIndexPath;
	NSArray * selectedChannelArray;
	
	BOOL viewPushedByNavigationController;
    
    UITableViewCell *channelCell;
    
    int selectedIndex;
    
    NMChannel *channelToUnsubscribeFrom;
    UITableViewCell *cellToUnsubscribeFrom;
    UIImage * sectionTitleBackgroundImage;
	UIColor * sectionTitleColor;
	UIFont * sectionTitleFont;
	
	NMStyleUtility * styleUtility;
	NSNumberFormatter * countFormatter;
}

@property (retain, nonatomic) IBOutlet CategoriesOrientedTableView *categoriesTableView;
@property (retain, nonatomic) IBOutlet UITableView *channelsTableView;
@property (retain, nonatomic) IBOutlet UIView *containerView;
@property (nonatomic, retain) NSFetchedResultsController * categoryFetchedResultsController;
@property (nonatomic, retain) NSFetchedResultsController * myChannelsFetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NSIndexPath * selectedIndexPath;
@property (nonatomic, retain) NSArray * selectedChannelArray;
@property (nonatomic, assign) IBOutlet UITableViewCell *channelCell;
@property (nonatomic, retain) UIImage * sectionTitleBackgroundImage;
@property (nonatomic, retain) UIColor * sectionTitleColor;
@property (nonatomic, retain) UIFont * sectionTitleFont;

-(float)categoryCellWidthFromString:(NSString *)text;
-(IBAction)toggleChannelSubscriptionStatus:(id)sender;

@end
