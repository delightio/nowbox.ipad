//
//  ChannelManagementViewController.m
//  ipad
//
//  Created by Bill So on 13/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "ChannelManagementViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "CategoriesOrientedTableView.h"
#import "CategoryCellView.h"
#import "CategoryTableCell.h"
#import "NMCachedImageView.h"
#import "SearchChannelViewController.h"
#import "ChannelDetailViewController.h"

NSString * const NMChannelManagementWillAppearNotification = @"NMChannelManagementWillAppearNotification";
NSString * const NMChannelManagementDidDisappearNotification = @"NMChannelManagementDidDisappearNotification";


@implementation ChannelManagementViewController
@synthesize categoriesTableView;
@synthesize channelsTableView;
@synthesize categoryFetchedResultsController;
@synthesize myChannelsFetchedResultsController;
@synthesize selectedIndexPath;
@synthesize selectedChannelArray;
@synthesize managedObjectContext;
@synthesize containerView;
@synthesize channelCell;


- (void)dealloc {
	[channelDetailViewController release];
    [myChannelsFetchedResultsController release];
    [categoriesTableView release];
    [channelsTableView release];
	[selectedChannelArray release];
	[categoryFetchedResultsController release];
	[managedObjectContext release];
	[selectedIndexPath release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
	self.title = @"Find Channels";
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(showSearchView:)];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissView:)];
	
    containerView.layer.cornerRadius = 4;

    [categoriesTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [channelsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    [categoriesTableView setFrame:CGRectMake(0, 0, 70, 530)];
    categoriesTableView.orientedTableViewDataSource = self;
    categoriesTableView.tableViewOrientation = kAGTableViewOrientationHorizontal;
    [categoriesTableView setAlwaysBounceVertical:YES];
//    [categoriesTableView setShowsVerticalScrollIndicator:NO];
    
    categoriesTableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"category-list-normal-bg-turned"]];

	// load the channel detail view
	channelDetailViewController = [[ChannelDetailViewController alloc] initWithNibName:@"ChannelDetailView" bundle:nil];

    
    NSIndexPath *indexPath=[NSIndexPath indexPathForRow:0 inSection:0];
    [categoriesTableView selectRowAtIndexPath:indexPath animated:NO  scrollPosition:UITableViewScrollPositionNone];
    [[categoriesTableView delegate] tableView:categoriesTableView didSelectRowAtIndexPath:indexPath];
    
}

- (void)viewDidUnload
{
    [self setCategoriesTableView:nil];
    [self setChannelsTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if ( !viewPushedByNavigationController ) {
		[[NSNotificationCenter defaultCenter] postNotificationName:NMChannelManagementWillAppearNotification object:self];
		// all subsequent transition happened in navigation controller should not fire channel management notification
		viewPushedByNavigationController = YES;
	}
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // listen to notification
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleDidGetChannelsNotification:) name:NMDidGetChannelsForCategoryNotification object:nil];
    
    [nc addObserver:self selector:@selector(handleWillLoadNotification:) name:NMWillSubscribeChannelNotification object:nil];
	[nc addObserver:self selector:@selector(handleWillLoadNotification:) name:NMWillUnsubscribeChannelNotification object:nil];
	[nc addObserver:self selector:@selector(handleSubscriptionNotification:) name:NMDidSubscribeChannelNotification object:nil];
	[nc addObserver:self selector:@selector(handleSubscriptionNotification:) name:NMDidUnsubscribeChannelNotification object:nil];
    
    [channelsTableView reloadData];
    
    [categoriesTableView flashScrollIndicators];

}

-(void)viewWillDisappear:(BOOL)animated {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	if ( !viewPushedByNavigationController ) {
		[[NSNotificationCenter defaultCenter] postNotificationName:NMChannelManagementDidDisappearNotification object:self];
	}
}

#pragma mark Notification handlers

- (void)handleDidGetChannelsNotification:(NSNotification *)aNotification {
	if ( selectedIndexPath ) {
		NMCategory * cat = [[aNotification userInfo] objectForKey:@"category"];
		NMCategory * selCat = [categoryFetchedResultsController objectAtIndexPath:selectedIndexPath];
		if ( selCat == cat ) {
			// same category. relaod data
			NSSet * chnSet = cat.channels;
			self.selectedChannelArray = [chnSet sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"nm_sort_order" ascending:YES]]];
			[channelsTableView reloadData];
		}
	}
}


- (void)handleWillLoadNotification:(NSNotification *)aNotification {
//	NSLog(@"notification: %@", [aNotification name]);
}

- (void)handleSubscriptionNotification:(NSNotification *)aNotification {
	NSDictionary * userInfo = [aNotification userInfo];
    for (int i=0; i<[selectedChannelArray count]; i++) {
        NMChannel * chn = [selectedChannelArray objectAtIndex:i];
        if (chn == [userInfo objectForKey:@"channel"]) {
            [channelsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}


#pragma mark Target-action methods

- (void)showSearchView:(id)sender {
	SearchChannelViewController * vc = [[SearchChannelViewController alloc] init];
    [vc clearSearchResults];
	[self.navigationController pushViewController:vc animated:YES];
	[vc release];
//	TwitterLoginViewController * twitCtrl = [[TwitterLoginViewController alloc] initWithNibName:@"TwitterLoginView" bundle:nil];
//	[self.navigationController pushViewController:twitCtrl animated:YES];
//	[twitCtrl release];
}

- (void)dismissView:(id)sender {
	viewPushedByNavigationController = NO;
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if ( tableView == categoriesTableView ) {
		id <NSFetchedResultsSectionInfo> sectionInfo = [[self.categoryFetchedResultsController sections] objectAtIndex:section];
		return (([sectionInfo numberOfObjects]+1)*2)-1;
	} else {
        if (selectedIndex==0) {
            id <NSFetchedResultsSectionInfo> sectionInfo = [[self.myChannelsFetchedResultsController sections] objectAtIndex:section];
            return [sectionInfo numberOfObjects];
        } else {
            return [selectedChannelArray count];
        }
	}
}

-(float)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

-(float)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Configure the cell.
	if ( aTableView == categoriesTableView ) {
        static NSString *CellIdentifier = @"CategoryCell";
		
        CategoryTableCell *categtoryCell = (CategoryTableCell *)[categoriesTableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (categtoryCell == nil) {
            categtoryCell = [[[CategoryTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
        
        if (indexPath.row == 0) { // my channels
            [categtoryCell setCategoryTitle:nil];
            [categtoryCell setUserInteractionEnabled:YES];
        } else if (indexPath.row % 2 == 0) { // other categories
            indexPath = [NSIndexPath indexPathForRow:(indexPath.row/2)-1 inSection:indexPath.section];
            NMCategory * cat = [categoryFetchedResultsController objectAtIndexPath:indexPath];
            [categtoryCell setCategoryTitle:cat.title];
            [categtoryCell setUserInteractionEnabled:YES];
        }
        else { // separator
            if (([indexPath row] == selectedIndex+1) || ([indexPath row] == selectedIndex-1)) {
                [categtoryCell setCategoryTitle:@""];
            } else {
                [categtoryCell setCategoryTitle:@"<SEPARATOR>"];
            }
            [categtoryCell setUserInteractionEnabled:NO];
        }
        return categtoryCell;
        
	} else {
        static NSString *CellIdentifier = @"FindChannelCell";
        
        UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            [[NSBundle mainBundle] loadNibNamed:@"FindChannelTableCell" owner:self options:nil];
            cell = channelCell;
            self.channelCell = nil;
        }
        NMChannel * chn;
        if (selectedIndex == 0) {
            chn = [myChannelsFetchedResultsController objectAtIndexPath:indexPath];
        } else {
            chn = [selectedChannelArray objectAtIndex:indexPath.row];
        }

        UIImageView *backgroundView;
        UIButton *buttonView;
        NMCachedImageView *thumbnailView;
        
        thumbnailView = (NMCachedImageView *)[cell viewWithTag:10];
        [thumbnailView setImageForChannel:chn];
        
        buttonView = (UIButton *)[cell viewWithTag:11];
        backgroundView = (UIImageView *)[cell viewWithTag:14];
        if ([chn.nm_subscribed boolValue]) {
            [buttonView setImage:[UIImage imageNamed:@"find-channel-subscribed-icon"] forState:UIControlStateNormal];
            [backgroundView setImage:[UIImage imageNamed:@"find-channel-list-subscribed"]];
        } else {
            [buttonView setImage:[UIImage imageNamed:@"find-channel-not-subscribed-icon"] forState:UIControlStateNormal];
            [backgroundView setImage:[UIImage imageNamed:@"find-channel-list-normal"]];
        }
        
        UILabel *label;
        label = (UILabel *)[cell viewWithTag:12];
        label.text = chn.title;
        
        label = (UILabel *)[cell viewWithTag:13];
        label.text = [NSString stringWithFormat:@"Posted %@ videos, %@ subscribers", chn.video_count, chn.subscriber_count];
        
        UIActivityIndicatorView *actView;
        actView = (UIActivityIndicatorView *)[cell viewWithTag:15];
        [actView setAlpha:0];
        [buttonView setAlpha:1];
      
        return cell;
	}
    
}

-(float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ( tableView == categoriesTableView ) {
        if (indexPath.row == 0) { // my channels
            return 80;
        } else if (indexPath.row % 2 == 0) { // other categories
            indexPath = [NSIndexPath indexPathForRow:(indexPath.row/2)-1 inSection:indexPath.section];
            NMCategory * cat = [categoryFetchedResultsController objectAtIndexPath:indexPath];
            return [self categoryCellWidthFromString:cat.title];
        }
        else { // separator
            return 2;
        }
    } else {
        return 65;
    }
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if ( tableView == categoriesTableView ) {
        // deselect first
        
        if (selectedIndex - 1 > 0) {
            [(CategoryTableCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex-1 inSection:0]] setCategoryTitle:@"<SEPARATOR>"];
        }
        if (selectedIndex + 1 < [tableView numberOfRowsInSection:0]) {
            [(CategoryTableCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex+1 inSection:0]] setCategoryTitle:@"<SEPARATOR>"];
        }
        if (indexPath.row - 1 > 0) {
            [(CategoryTableCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row-1 inSection:0]] setCategoryTitle:@""];
        }
        if (indexPath.row + 1 < [tableView numberOfRowsInSection:0]) {
            [(CategoryTableCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row+1 inSection:0]] setCategoryTitle:@""];
        }
        
        selectedIndex = indexPath.row;

        if (indexPath.row == 0) { // my channels
            self.selectedIndexPath = 0;
            self.selectedChannelArray = nil;
            [channelsTableView reloadData];
            return;
        } else if (indexPath.row % 2 == 0) { // other categories
            // refresh the right table data
            indexPath = [NSIndexPath indexPathForRow:(indexPath.row/2)-1 inSection:indexPath.section];
            self.selectedIndexPath = indexPath;
            NMCategory * cat = [categoryFetchedResultsController objectAtIndexPath:indexPath];
            NSSet * chnSet = cat.channels;
            self.selectedChannelArray = [chnSet sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"nm_sort_order" ascending:YES]]];
            [channelsTableView reloadData];
            
            if ( [chnSet count] == 0 ) {
                // try fetching the channels from server
                [[NMTaskQueueController sharedTaskQueueController] issueGetChannelsForCategory:cat];
            }
            return;
        }
        else { // separator
            return;
        }

        
	} else {
        
        NMChannel * chn;

        if (selectedIndex == 0) {
            chn = [myChannelsFetchedResultsController objectAtIndexPath:indexPath];
        } else {
            chn = [selectedChannelArray objectAtIndex:indexPath.row];
        }
		channelDetailViewController.channel = chn;
		[self.navigationController pushViewController:channelDetailViewController animated:YES];
    }
}

#pragma mark Fetched results controller
- (NSFetchedResultsController *)categoryFetchedResultsController {
    if (categoryFetchedResultsController != nil) {
        return categoryFetchedResultsController;
    }
    
    /*
     Set up the fetched results controller.
	 */
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:NMCategoryEntityName inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
	[fetchRequest setReturnsObjectsAsFaults:NO];
		
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // search results is a category but with -1 as ID, ignore that
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"nm_id > 0"]];

    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.categoryFetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [fetchRequest release];
    [sortDescriptor release];
    [sortDescriptors release];
    
    NSError *error = nil;
    if (![categoryFetchedResultsController performFetch:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return categoryFetchedResultsController;
}


- (NSFetchedResultsController *)myChannelsFetchedResultsController {
    
    if (myChannelsFetchedResultsController != nil) {
        return myChannelsFetchedResultsController;
    }
    
    /*
     Set up the fetched results controller.
	 */
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:NMChannelEntityName inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
	[fetchRequest setReturnsObjectsAsFaults:NO];
	//	[fetchRequest setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"videos"]];
	
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"nm_subscribed > 0 AND type != %@", [NSNumber numberWithInteger:NMChannelUserType]]];
	
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_subscribed" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.myChannelsFetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [fetchRequest release];
    [sortDescriptor release];
    [sortDescriptors release];
    
    NSError *error = nil;
    if (![myChannelsFetchedResultsController performFetch:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return myChannelsFetchedResultsController;
}    



#pragma mark Fetched results controller delegate methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    if (controller == categoryFetchedResultsController) {
        [categoriesTableView beginUpdates];
    }
    else {
        if (selectedIndex == 0) {
            [channelsTableView beginUpdates];
        }
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    if (controller == categoryFetchedResultsController) {
        switch(type) {
            case NSFetchedResultsChangeInsert:
                [categoriesTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeDelete:
                [categoriesTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
    }
    else {
        if (selectedIndex == 0) {
            switch(type) {
                case NSFetchedResultsChangeInsert:
                    [channelsTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                    break;
                    
                case NSFetchedResultsChangeDelete:
                    [channelsTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                    break;
            }
        }
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {

    if (controller == categoryFetchedResultsController) {
        indexPath = [NSIndexPath indexPathForRow:indexPath.row*2+1 inSection:indexPath.section];
        switch(type) {
                
            case NSFetchedResultsChangeInsert:
//                [categoriesTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                [categoriesTableView reloadData];
                break;
                
            case NSFetchedResultsChangeDelete:
//                [categoriesTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [categoriesTableView reloadData];
                break;
                
            case NSFetchedResultsChangeUpdate:
                [categoriesTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[indexPath row] inSection:[indexPath section]]] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeMove:
//                [categoriesTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
//                [categoriesTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
                [categoriesTableView reloadData];
                break;
        }
    }
    else {
        if (selectedIndex == 0) {
            switch(type) {
                case NSFetchedResultsChangeInsert:
                    [channelsTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                    break;
                    
                case NSFetchedResultsChangeDelete:
                    [channelsTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                    break;
                    
                case NSFetchedResultsChangeUpdate:
                    [channelsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                    break;
                    
                case NSFetchedResultsChangeMove:
                    [channelsTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                    [channelsTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
                    break;
            }
        }
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if (controller == categoryFetchedResultsController) {
        [categoriesTableView endUpdates];
    }
    else {
        if (selectedIndex == 0) {
            [channelsTableView endUpdates];
        }
    }
}

#pragma mark helpers
-(float)categoryCellWidthFromString:(NSString *)text {
    if (text == nil) {
        return 38;
    }
    else {
        CGSize textLabelSize;
        if ( NM_RUNNING_IOS_5 ) {
            textLabelSize = [[text uppercaseString] sizeWithFont:[UIFont fontWithName:@"Futura-CondensedMedium" size:16]];
        }
        else {
            textLabelSize = [[text uppercaseString] sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:14.0f]];
        }
        return textLabelSize.width+40;
    }
    return 0;
}

#pragma mark UIAlertView delegates
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != [alertView cancelButtonIndex]) {
        UIActivityIndicatorView *actView;
        actView = (UIActivityIndicatorView *)[cellToUnsubscribeFrom viewWithTag:15];
        [actView startAnimating];
        
        UIButton *buttonView = (UIButton *)[cellToUnsubscribeFrom viewWithTag:11];
        
        [UIView animateWithDuration:0.3
                         animations:^{
                             [actView setAlpha:1];
                             [buttonView setAlpha:0];
                         }
                         completion:^(BOOL finished) {
                         }];
        
        [[NMTaskQueueController sharedTaskQueueController] issueSubscribe:![channelToUnsubscribeFrom.nm_subscribed boolValue] channel:channelToUnsubscribeFrom];
    }
}
 
-(IBAction)toggleChannelSubscriptionStatus:(id)sender {
    UITableViewCell *cell = (UITableViewCell *)[[sender superview] superview];
    
    UIActivityIndicatorView *actView;
    actView = (UIActivityIndicatorView *)[cell viewWithTag:15];
    [actView startAnimating];
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         [actView setAlpha:1];
                         [sender setAlpha:0];
                     }
                     completion:^(BOOL finished) {
                     }];
    NMChannel * chn;
    if (selectedIndex == 0) {
        chn = [myChannelsFetchedResultsController objectAtIndexPath:[channelsTableView indexPathForCell:cell]];
    } else {
        chn = [selectedChannelArray objectAtIndex:[channelsTableView indexPathForCell:cell].row];
    }
    
    [[NMTaskQueueController sharedTaskQueueController] issueSubscribe:![chn.nm_subscribed boolValue] channel:chn];
    
}

@end
