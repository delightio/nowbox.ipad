//
//  ChannelManagementViewController.m
//  ipad
//
//  Created by Bill So on 13/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "ChannelManagementViewController.h"
#import "NMLibrary.h"
#import "TwitterLoginViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "CategoriesOrientedTableView.h"
#import "CategoryCellView.h"
#import "CategoryTableCell.h"
#import "NMCachedImageView.h"

NSString * const NMChannelManagementWillAppearNotification = @"NMChannelManagementWillAppearNotification";
NSString * const NMChannelManagementDidDisappearNotification = @"NMChannelManagementDidDisappearNotification";


@implementation ChannelManagementViewController
@synthesize categoriesTableView;
@synthesize channelsTableView;
@synthesize categoryFetchedResultsController;
@synthesize selectedIndexPath;
@synthesize selectedChannelArray;
@synthesize managedObjectContext;
@synthesize containerView;
@synthesize channelCell;


- (void)dealloc {
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
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissView:)];
	
    containerView.layer.cornerRadius = 4;

    [categoriesTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [channelsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
	// listen to notification
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleDidGetChannelsNotification:) name:NMDidGetChannelsForCategoryNotification object:nil];
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
    
    [categoriesTableView setFrame:CGRectMake(0, 0, 59, channelsTableView.frame.size.width)];
    categoriesTableView.orientedTableViewDataSource = self;
    categoriesTableView.tableViewOrientation = kAGTableViewOrientationHorizontal;
    [categoriesTableView setAlwaysBounceVertical:YES];
    [categoriesTableView setShowsVerticalScrollIndicator:NO];
    
    NSIndexPath *indexPath=[NSIndexPath indexPathForRow:1 inSection:0];
    [categoriesTableView selectRowAtIndexPath:indexPath animated:NO  scrollPosition:UITableViewScrollPositionNone];
    [[categoriesTableView delegate] tableView:categoriesTableView didSelectRowAtIndexPath:indexPath];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

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

#pragma mark Target-action methods

- (void)showSearchView:(id)sender {
	TwitterLoginViewController * twitCtrl = [[TwitterLoginViewController alloc] initWithNibName:@"TwitterLoginView" bundle:nil];
	[self.navigationController pushViewController:twitCtrl animated:YES];
	[twitCtrl release];
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
		return [sectionInfo numberOfObjects]+3;
	} else {
		return [selectedChannelArray count];
	}
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
        
		id <NSFetchedResultsSectionInfo> sectionInfo = [[self.categoryFetchedResultsController sections] objectAtIndex:indexPath.section];
        if ((indexPath.row == 0) || (indexPath.row == [sectionInfo numberOfObjects]+2)) {
            [categtoryCell setCategoryTitle:@""];
            [categtoryCell setUserInteractionEnabled:NO];
        } else if (indexPath.row == 1) {
            [categtoryCell setCategoryTitle:nil];
            [categtoryCell setUserInteractionEnabled:YES];
        } else {
            indexPath = [NSIndexPath indexPathForRow:indexPath.row-2 inSection:indexPath.section];
            NMCategory * cat = [categoryFetchedResultsController objectAtIndexPath:indexPath];
            [categtoryCell setCategoryTitle:cat.title];
            [categtoryCell setUserInteractionEnabled:YES];
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
        
        NMChannel * chn = [selectedChannelArray objectAtIndex:indexPath.row];

        if ([chn.nm_subscribed boolValue]) {
        } else {
        }

        UILabel *label;
        label = (UILabel *)[cell viewWithTag:12];
        label.text = chn.title;
        
        label = (UILabel *)[cell viewWithTag:13];
        label.text = [NSString stringWithFormat:@"Posted %d videos, %d followers", 0, 0];
        
        UIImageView *imageView, *backgroundView;
        NMCachedImageView *thumbnailView;
        
        thumbnailView = (NMCachedImageView *)[cell viewWithTag:10];
        [thumbnailView setImageForChannel:chn];
        
        imageView = (UIImageView *)[cell viewWithTag:11];
        backgroundView = (UIImageView *)[cell viewWithTag:14];
        if ([chn.nm_subscribed boolValue]) {
            [imageView setImage:[UIImage imageNamed:@"find-channel-subscribed-icon"]];
            [backgroundView setImage:[UIImage imageNamed:@"find-channel-list-subscribed"]];
        } else {
            [imageView setImage:[UIImage imageNamed:@"find-channel-not-subscribed-icon"]];
            [backgroundView setImage:[UIImage imageNamed:@"find-channel-list-normal"]];
        }
        
        return cell;
	}
    
}

-(float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ( tableView == categoriesTableView ) {
		id <NSFetchedResultsSectionInfo> sectionInfo = [[self.categoryFetchedResultsController sections] objectAtIndex:indexPath.section];
        if ((indexPath.row == 0) || (indexPath.row == [sectionInfo numberOfObjects]+2)) {
            return 10;
        } else if (indexPath.row == 1) {
            return 59;
        }
        indexPath = [NSIndexPath indexPathForRow:indexPath.row-2 inSection:indexPath.section];
		NMCategory * cat = [categoryFetchedResultsController objectAtIndexPath:indexPath];
        return [self categoryCellWidthFromString:cat.title];
    } else {
        return 65;
    }
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if ( tableView == categoriesTableView ) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.categoryFetchedResultsController sections] objectAtIndex:indexPath.section];
        if ((indexPath.row == 0) || (indexPath.row == [sectionInfo numberOfObjects]+2)) {
            return;
        } else if (indexPath.row == 1) {
            return;
        }

		// refresh the right table data
        indexPath = [NSIndexPath indexPathForRow:indexPath.row-2 inSection:indexPath.section];
		self.selectedIndexPath = indexPath;
		NMCategory * cat = [categoryFetchedResultsController objectAtIndexPath:indexPath];
		NSSet * chnSet = cat.channels;
		self.selectedChannelArray = [chnSet sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"nm_sort_order" ascending:YES]]];
		[channelsTableView reloadData];
		
		if ( [chnSet count] == 0 ) {
			// try fetching the channels from server
			[[NMTaskQueueController sharedTaskQueueController] issueGetChannelsForCategory:cat];
		}
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

#pragma mark Fetched results controller delegate methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [categoriesTableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [categoriesTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [categoriesTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    indexPath = [NSIndexPath indexPathForRow:indexPath.row+2 inSection:indexPath.section];

    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [categoriesTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [categoriesTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            //[self configureCell:[categoriesTableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath retainPosition:YES];
            break;
            
        case NSFetchedResultsChangeMove:
            [categoriesTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [categoriesTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[categoriesTableView endUpdates];
}

#pragma mark helpers
-(float)categoryCellWidthFromString:(NSString *)text {
    if (text == nil) {
        return 38;
    }
    else {
        CGSize textLabelSize = [[text uppercaseString] sizeWithFont:[UIFont fontWithName:@"Futura-CondensedMedium" size:16]];
        return textLabelSize.width+40;
    }
    return 0;
}

@end
