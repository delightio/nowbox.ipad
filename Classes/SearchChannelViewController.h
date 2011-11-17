//
//  SearchChannelViewController.h
//  ipad
//
//  Created by Tim Chen on 18/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMLibrary.h"

@class ChannelDetailViewController;


@interface SearchChannelViewController : UIViewController <NSFetchedResultsControllerDelegate, UISearchBarDelegate, UIScrollViewDelegate, UITableViewDelegate> {
    IBOutlet UISearchBar * searchBar;
    IBOutlet UITableView * tableView;
    
    UITableViewCell *channelCell;

    ChannelDetailViewController * channelDetailViewController;
	NSNumberFormatter * countFormatter;
    NSString * lastSearchQuery;
    BOOL resigningFirstResponder;
}

@property (nonatomic, retain) IBOutlet UISearchBar * searchBar;
@property (nonatomic, retain) IBOutlet UITableView * tableView;
@property (nonatomic, retain) NSFetchedResultsController * fetchedResultsController;

@property (nonatomic, assign) IBOutlet UITableViewCell *channelCell;
@property (nonatomic, retain) IBOutlet UIView *progressView;
@property (nonatomic, retain) IBOutlet UIView *noResultsView;
@property (nonatomic, retain) NSString * lastSearchQuery;

- (void)clearSearchResults;
- (void)performSearchWithText:(NSString *)searchText;

@end
