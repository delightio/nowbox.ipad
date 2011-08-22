//
//  SearchChannelViewController.h
//  ipad
//
//  Created by Tim Chen on 18/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMLibrary.h"


@interface SearchChannelViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, UISearchBarDelegate> {
    IBOutlet UISearchBar * searchBar;
    IBOutlet UITableView * tableView;
	NSManagedObjectContext * managedObjectContext;
	NSFetchedResultsController * searchFetchedResultsController;
    
    UITableViewCell *channelCell;

}

@property (nonatomic, retain) IBOutlet UISearchBar * searchBar;
@property (nonatomic, retain) IBOutlet UITableView * tableView;
@property (nonatomic, retain) NSFetchedResultsController * searchFetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;

@property (nonatomic, assign) IBOutlet UITableViewCell *channelCell;

@end
