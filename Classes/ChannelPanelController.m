//
//  ChannelPanelController.m
//  ipad
//
//  Created by Bill So on 6/13/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "ChannelPanelController.h"
#import "NMLibrary.h"
#import "VideoRowController.h"


#define VIDEO_ROW_LEFT_PADDING			168.0f
#define NM_CHANNEL_CELL_LEFT_PADDING	10.0f
#define NM_CHANNEL_CELL_TOP_PADDING		10.0f
#define NM_CHANNEL_CELL_DETAIL_TOP_MARGIN	40.0f

@implementation ChannelPanelController
@synthesize panelView;
@synthesize managedObjectContext=managedObjectContext_;
@synthesize fetchedResultsController=fetchedResultsController_;

- (void)awakeFromNib {
	styleUtility = [NMStyleUtility sharedStyleUtility];
	tableView.rowHeight = 80.0f;
	self.managedObjectContext = [NMTaskQueueController sharedTaskQueueController].managedObjectContext;
}

- (void)dealloc {
	[panelView release];
	[managedObjectContext_ release];
	[fetchedResultsController_ release];
	[super dealloc];
}

#pragma mark View transition methods
- (void)panelWillAppear {
	
}
- (void)panelWillDisappear {
	
}

- (void)panelWillBecomeFullScreen {
	
}

- (void)panelWillEnterHalfScreen:(NMPlaybackViewModeType)fromViewMode {
	
}

#pragma mark Target action methods
- (IBAction)toggleTableEditMode:(id)sender {
	[tableView setEditing:!tableView.editing animated:YES];
}

- (IBAction)debugRefreshChannel:(id)sender {
	[[NMTaskQueueController sharedTaskQueueController] issueGetChannels];
}

#pragma mark Other table methods
- (void)setupCellContentView:(UIView *)aContentView {
	// video title
	UILabel * lbl = [[UILabel alloc] initWithFrame:CGRectMake(NM_CHANNEL_CELL_LEFT_PADDING, NM_CHANNEL_CELL_TOP_PADDING, aContentView.bounds.size.width, aContentView.bounds.size.height)];
	lbl.font = styleUtility.videoTitleFont;
	lbl.backgroundColor = styleUtility.clearColor;
	lbl.textColor = styleUtility.channelPanelFontColor;
	lbl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[lbl release];
	
	// video date posted
	lbl = [[UILabel alloc] initWithFrame:CGRectMake(NM_CHANNEL_CELL_LEFT_PADDING, NM_CHANNEL_CELL_DETAIL_TOP_MARGIN, aContentView.bounds.size.width, aContentView.bounds.size.height)];
	lbl.font = styleUtility.videoDetailFont;
	lbl.backgroundColor = styleUtility.clearColor;
	lbl.textColor = styleUtility.channelPanelFontColor;
	lbl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	[lbl release];
	
	// video duration
	lbl = [[UILabel alloc] initWithFrame:CGRectMake(NM_CHANNEL_CELL_LEFT_PADDING, NM_CHANNEL_CELL_DETAIL_TOP_MARGIN, aContentView.bounds.size.width, aContentView.bounds.size.height)];
	lbl.font = styleUtility.videoDetailFont;
	lbl.backgroundColor = styleUtility.clearColor;
	lbl.textColor = styleUtility.channelPanelFontColor;
	lbl.textAlignment = UITextAlignmentRight;
	lbl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	[lbl release];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	NMChannel * theChannel = (NMChannel *)[self.fetchedResultsController objectAtIndexPath:indexPath];
	cell.textLabel.text = theChannel.title;
	CGRect theFrame = cell.contentView.bounds;
	theFrame.size.width -= VIDEO_ROW_LEFT_PADDING;
	theFrame.origin.x += VIDEO_ROW_LEFT_PADDING;
	cell.imageView.image = styleUtility.userPlaceholderImage;
	VideoRowController * rowCtrl = [[VideoRowController alloc] initWithFrame:theFrame channel:theChannel];
	[cell.contentView addSubview:rowCtrl.videoTableView];
	
	NMTaskQueueController * schdlr = [NMTaskQueueController sharedTaskQueueController];
	if ( theChannel == nil || [theChannel.videos count] == 0 ) {
		[schdlr issueGetVideoListForChannel:theChannel];
	}
}

#pragma mark -
#pragma mark Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
	UITableViewCell *cell = (UITableViewCell *)[aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.textLabel.font = styleUtility.channelNameFont;
		[self setupCellContentView:cell.contentView];
    }
    
    // Configure the cell.
	[self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleNone;
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
	//	[fetchRequest setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"videos"]];
	
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"videos.@count > 0"]];
	
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
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
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

@end
