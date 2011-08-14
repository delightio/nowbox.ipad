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

NSString * const NMChannelManagementWillAppearNotification = @"NMChannelManagementWillAppearNotification";
NSString * const NMChannelManagementDidDisappearNotification = @"NMChannelManagementDidDisappearNotification";


@implementation ChannelManagementViewController
@synthesize leftTableView;
@synthesize rightTableView;
@synthesize categoryFetchedResultsController;
@synthesize selectedIndexPath;
@synthesize selectedChannelArray;
@synthesize managedObjectContext;


- (void)dealloc {
    [leftTableView release];
    [rightTableView release];
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
		
	self.title = @"Channels";
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(showSearchView:)];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissView:)];
	
	// listen to notification
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleDidGetChannelsNotification:) name:NMDidGetChannelsForCategoryNotification object:nil];
}

- (void)viewDidUnload
{
    [self setLeftTableView:nil];
    [self setRightTableView:nil];
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
			[rightTableView reloadData];
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
	if ( tableView == leftTableView ) {
		id <NSFetchedResultsSectionInfo> sectionInfo = [[self.categoryFetchedResultsController sections] objectAtIndex:section];
		return [sectionInfo numberOfObjects];
	} else {
		return [selectedChannelArray count];
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"MyRow";
    
	UITableViewCell *cell = (UITableViewCell *)[aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell.
	if ( aTableView == leftTableView ) {
		NMCategory * cat = [categoryFetchedResultsController objectAtIndexPath:indexPath];
		cell.textLabel.text = cat.title;
	} else {
		NMChannel * chn = [selectedChannelArray objectAtIndex:indexPath.row];
		cell.textLabel.text = chn.title;
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [chn.nm_subscribed boolValue] ? @"Subscribed" : @"Subscribe"];
	}
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if ( tableView == leftTableView ) {
		// refresh the right table data
		self.selectedIndexPath = indexPath;
		NMCategory * cat = [categoryFetchedResultsController objectAtIndexPath:indexPath];
		NSSet * chnSet = cat.channels;
		self.selectedChannelArray = [chnSet sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"nm_sort_order" ascending:YES]]];
		[rightTableView reloadData];
		
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
    [leftTableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [leftTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [leftTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [leftTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [leftTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            //[self configureCell:[leftTableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath retainPosition:YES];
            break;
            
        case NSFetchedResultsChangeMove:
            [leftTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [leftTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[leftTableView endUpdates];
}

@end
