//
//  ChannelViewController.m
//  Nowmov
//
//  Created by Bill So on 03/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ChannelViewController.h"
#import "VideoPlaybackViewController.h"
#import "SocialSignInViewController.h"
#import "NMLibrary.h"
#import "ipadAppDelegate.h"

@implementation ChannelViewController

@synthesize fetchedResultsController=fetchedResultsController_, managedObjectContext=managedObjectContext_;
@synthesize videoViewController;

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	freshStart = YES;
	channelTableView.rowHeight = 218.0;
	// set inset so that the top of the channel thunbmail aligns with the left button
	channelTableView.contentInset = UIEdgeInsetsMake(15.0, 0.0, 0.0, 0.0);
    UIImage * img = [[UIImage imageNamed:@"channel_table_overlay"] stretchableImageWithLeftCapWidth:1 topCapHeight:0];
    tableOverlayImageView.image = img;
    img = [[UIImage imageNamed:@"channel_header_shadow"] stretchableImageWithLeftCapWidth:1 topCapHeight:0];
    headerOverlayImageView.image = img;
	
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
	// check number of channels
	numberOfChannels = [sectionInfo numberOfObjects];
	ipadAppDelegate * appDel = (ipadAppDelegate *)[UIApplication sharedApplication].delegate;
	self.videoViewController = appDel.viewController;
	
	if ( numberOfChannels == 0 ) {
		// get channel
		[[NMTaskQueueController sharedTaskQueueController] issueGetChannels];
	}
	NSNotificationCenter * dc = [NSNotificationCenter defaultCenter];
	[dc addObserver:self selector:@selector(handleDidGetChannelNotification:) name:NMDidGetChannelsNotification object:nil];
	
	// create a covering view
//	UIView * coveringView = [[UIView alloc] initWithFrame:self.view.bounds];
//	coveringView.backgroundColor = self.view.backgroundColor;
//	coveringView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
//	coveringView.tag = 9001;
//	[self.view addSubview:coveringView];
//	[coveringView release];
}

- (void)showVideoView {
//	[self presentModalViewController:videoViewController animated:NO];
	// always default to LIVE channel
	//MARK: debug
//	videoViewController.currentChannel = [NMTaskQueueController sharedTaskQueueController].dataController.liveChannel;
	UIView * cv = [self.view viewWithTag:9001];
	[cv removeFromSuperview];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if ( freshStart ) {
//		[self performSelector:@selector(showVideoView) withObject:nil afterDelay:0.1];
		freshStart = NO;
	}
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [headerOverlayImageView release];
    headerOverlayImageView = nil;
    [tableOverlayImageView release];
    tableOverlayImageView = nil;
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[videoViewController release];
    [fetchedResultsController_ release];
    [managedObjectContext_ release];
    [tableOverlayImageView release];
    [headerOverlayImageView release];
    [super dealloc];
}

#pragma mark Notification handler
- (void)handleDidGetChannelNotification:(NSNotification *)aNotification {
	NSLog(@"got the channels");
	// we should have the first video for live channel. show the live channel
//	NMChannel * chnObj = [[aNotification userInfo] objectForKey:@"live_channel"];
//	if ( chnObj ) {
//		ipadAppDelegate * appDel = (ipadAppDelegate *)[UIApplication sharedApplication].delegate;
//		appDel.viewController.currentChannel = chnObj;
//		[self presentModalViewController:appDel.viewController animated:NO];
//	}
}

#pragma mark Target-action methods
- (IBAction)getChannels:(id)sender {
	[[NMTaskQueueController sharedTaskQueueController] issueGetChannels];
}

- (IBAction)showLoginView:(id)sender {
	UIButton * btn = (UIButton *)sender;
	
	SocialSignInViewController * socialCtrl = [[SocialSignInViewController alloc] initWithNibName:@"SocialSignInView" bundle:nil];
	
	UINavigationController * navCtrl = [[UINavigationController alloc] initWithRootViewController:socialCtrl];
	
	UIPopoverController * popCtrl = [[UIPopoverController alloc] initWithContentViewController:navCtrl];
	popCtrl.popoverContentSize = CGSizeMake(320.0f, 154.0f);
	popCtrl.delegate = self;
	
	[popCtrl presentPopoverFromRect:btn.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
	
	[socialCtrl release];
	[navCtrl release];
}

- (IBAction)getFacebookProfile:(id)sender {
//	ipadAppDelegate * appDel = (ipadAppDelegate *)[UIApplication sharedApplication].delegate;
//	[appDel.facebook requestWithGraphPath:@"me" andDelegate:self];
}

- (void)request:(FBRequest *)request didLoad:(id)result {
	NSLog(@"done graph %@", result);
}

#pragma mark Popover delegate methods
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	[popoverController release];
}

#pragma mark Other table methods
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	// since each cell shows 3 channels, we need to calculate the real index path
	NSMutableArray * ay = [NSMutableArray arrayWithCapacity:3];
	NSUInteger rowIdx;
	for (NSUInteger i = 0; i < 3; i++) {
		rowIdx = i + indexPath.row * 3;
		if ( rowIdx < numberOfChannels ) {
			// fetch the channel object
			[ay addObject:[self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:rowIdx inSection:0]]];
		} else {
			break;
		}
	}
	((ChannelTableCellView *)cell).channels = ay;
}

- (void)tableViewCell:(ChannelTableCellView *)cell didSelectChannelAtIndex:(NSUInteger)index {
	NSIndexPath * idxPath = [channelTableView indexPathForCell:cell];
	NMChannel * chnObj = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:idxPath.row * 3 + index inSection:0]];
	videoViewController.currentChannel = chnObj;
	[self presentModalViewController:videoViewController animated:YES];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
	// each cell shows 3 channels
	numberOfChannels = [sectionInfo numberOfObjects];
    return numberOfChannels / 3 + ( numberOfChannels % 3 ? 1 : 0 );
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
	ChannelTableCellView *cell = (ChannelTableCellView *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[ChannelTableCellView alloc] initWithReuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.delegate = self;
    }
    
    // Configure the cell.
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}



/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the managed object for the given index path
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        // Save the context.
        NSError *error = nil;
        if (![context save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }   
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // The table view should not be re-orderable.
    return NO;
}


#pragma mark -
#pragma mark Table view delegate

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here -- for example, create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     NSManagedObject *selectedObject = [[self fetchedResultsController] objectAtIndexPath:indexPath];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
//}


#pragma mark -
#pragma mark Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (fetchedResultsController_ != nil) {
        return fetchedResultsController_;
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
	[fetchRequest setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"videos"]];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [fetchRequest release];
    [sortDescriptor release];
    [sortDescriptors release];
    
    NSError *error = nil;
    if (![fetchedResultsController_ performFetch:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return fetchedResultsController_;
}    


#pragma mark -
#pragma mark Fetched results controller delegate


//- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
//    [channelTableView beginUpdates];
//}
//
//
//- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
//           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
//    
//    switch(type) {
//        case NSFetchedResultsChangeInsert:
//            [channelTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeDelete:
//            [channelTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//    }
//}
//
//
//- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
//       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
//      newIndexPath:(NSIndexPath *)newIndexPath {
//    
//    UITableView *tableView = channelTableView;
//	// one row == 3 channels
//	NSIndexPath * realNewIndexPath, * realSrcIndexPath;
//	realNewIndexPath = [NSIndexPath indexPathForRow:indexPath.row / 3 inSection:0];
//	realSrcIndexPath = [NSIndexPath indexPathForRow:indexPath.row / 3 inSection:0];
//    
//    switch(type) {
//            
//        case NSFetchedResultsChangeInsert:
//            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:realNewIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeDelete:
//            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:realSrcIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeUpdate:
//            [self configureCell:[tableView cellForRowAtIndexPath:realSrcIndexPath] atIndexPath:realSrcIndexPath];
//            break;
//            
//        case NSFetchedResultsChangeMove:
//            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:realSrcIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:realNewIndexPath]withRowAnimation:UITableViewRowAnimationFade];
//            break;
//    }
//}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [channelTableView reloadData];
}


/*
 // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
 // In the simplest, most efficient, case, reload the table view.
 [channelTableView reloadData];
 }
 */

@end
