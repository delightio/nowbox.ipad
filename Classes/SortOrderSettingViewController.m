//
//  SortOrderSettingViewController.m
//  ipad
//
//  Created by Chris Haugli on 3/19/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "SortOrderSettingViewController.h"
#import "ipadAppDelegate.h"

NSString * const NMSortOrderDidChangeNotification = @"NMSortOrderDidChangeNotification";

@implementation SortOrderSettingViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"Sort Order";
    }
    return self;
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Newer First";
            if (NM_SORT_ORDER == NMSortOrderTypeNewestFirst) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            break;
        case 1:
            cell.textLabel.text = @"Older First";
            if (NM_SORT_ORDER == NMSortOrderTypeOldestFirst) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            break;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NMSortOrderType existingSortOrder = NM_SORT_ORDER;
    
    switch (indexPath.row) {
        case 0:
            NM_SORT_ORDER = NMSortOrderTypeNewestFirst;
            break;
        case 1:
            NM_SORT_ORDER = NMSortOrderTypeOldestFirst;
            break;
    }
    
    [tableView reloadData];
    [self.tableView selectRowAtIndexPath:indexPath 
                                animated:NO
                          scrollPosition:UITableViewScrollPositionNone];
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];

    if (NM_SORT_ORDER != existingSortOrder) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setInteger:NM_SORT_ORDER forKey:NM_SORT_ORDER_KEY];
        [userDefaults synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NMSortOrderDidChangeNotification object:nil];
    }
}

@end
