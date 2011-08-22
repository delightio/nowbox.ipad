//
//  SearchChannelViewController.m
//  ipad
//
//  Created by Tim Chen on 18/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "SearchChannelViewController.h"
#import "CategoryTableCell.h"
#import "NMCachedImageView.h"


@implementation SearchChannelViewController

@synthesize searchBar, tableView, searchFetchedResultsController, managedObjectContext, channelCell;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Search Channels";
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[searchBar.subviews objectAtIndex:0] removeFromSuperview];
    searchBar.backgroundColor = [UIColor clearColor];
    searchBar.opaque = NO;
    
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleWillLoadNotification:) name:NMWillSearchChannelsNotification object:nil];
	[nc addObserver:self selector:@selector(handleDidSearchNotification:) name:NMDidSearchChannelsNotification object:nil];

    [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    

}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)dealloc {
	[searchFetchedResultsController release];
	[managedObjectContext release];
    [super dealloc];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.searchFetchedResultsController sections] count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.searchFetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

-(float)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 10;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIImageView *theView = [[[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 70, 10)] autorelease];
    theView.image = [UIImage imageNamed:@"category-list-normal-bg-turned"];
    return theView;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"FindChannelCell";
    
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"FindChannelTableCell" owner:self options:nil];
        cell = channelCell;
        self.channelCell = nil;
    }
    
    NMChannel * chn = [searchFetchedResultsController objectAtIndexPath:indexPath];
    
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
    
    UIActivityIndicatorView *actView;
    actView = (UIActivityIndicatorView *)[cell viewWithTag:15];
    [actView setAlpha:0];
    [imageView setAlpha:1];
    
    return cell;
    
}

-(float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    UIActivityIndicatorView *actView;
    actView = (UIActivityIndicatorView *)[cell viewWithTag:15];
    [actView startAnimating];
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:11];
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         [actView setAlpha:1];
                         [imageView setAlpha:0];
                     }
                     completion:^(BOOL finished) {
                     }];
    
    NMChannel * chn = [searchFetchedResultsController objectAtIndexPath:indexPath];
    
    [[NMTaskQueueController sharedTaskQueueController] issueSubscribe:![chn.nm_subscribed boolValue] channel:chn];
    
}



#pragma mark Notification handlers

- (void)handleWillLoadNotification:(NSNotification *)aNotification {
	NSLog(@"notification: %@", [aNotification name]);
}

- (void)handleDidSearchNotification:(NSNotification *)aNotification {
    self.searchFetchedResultsController = nil;
	NSLog(@"notification: %@", [aNotification name]);
//	// test out search predicate
//	NSFetchRequest * request = [[NSFetchRequest alloc] init];
//	NMDataController * dataCtrl = [NMTaskQueueController sharedTaskQueueController].dataController;
//	[request setEntity:[NSEntityDescription entityForName:NMChannelEntityName inManagedObjectContext:dataCtrl.managedObjectContext]];
//	[request setPredicate:dataCtrl.searchResultsPredicate];
//	NSArray * result = [dataCtrl.managedObjectContext executeFetchRequest:request error:nil];
//	NSLog(@"search result %@", result);
//	[request release];
}

#pragma mark Fetched results controller
- (NSFetchedResultsController *)searchFetchedResultsController {
    if (searchFetchedResultsController != nil) {
        return searchFetchedResultsController;
    }
    
    /*
     Set up the fetched results controller.
	 */
    // Create the fetch request for the entity.
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
	NMDataController * dataCtrl = [NMTaskQueueController sharedTaskQueueController].dataController;
	[request setEntity:[NSEntityDescription entityForName:NMChannelEntityName inManagedObjectContext:dataCtrl.managedObjectContext]];
	[request setPredicate:dataCtrl.searchResultsPredicate];

    [request setFetchBatchSize:20];
    NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:YES] autorelease];
    NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortDescriptor, nil] autorelease];
    [request setSortDescriptors:sortDescriptors];
    
    
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.searchFetchedResultsController = aFetchedResultsController;
	
    [request release];
    
    NSError *error = nil;
    if (![searchFetchedResultsController performFetch:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return searchFetchedResultsController;
}


#pragma mark Fetched results controller delegate methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    indexPath = [NSIndexPath indexPathForRow:indexPath.row+2 inSection:indexPath.section];
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[tableView endUpdates];
}


#pragma mark UISearchBarDelegate methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    NMTaskQueueController * ctrl = [NMTaskQueueController sharedTaskQueueController];
	[ctrl.dataController clearSearchResultCache];
	[ctrl issueChannelSearchForKeyword:searchText];
}

@end
