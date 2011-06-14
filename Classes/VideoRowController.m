//
//  VideoRowController.m
//  ipad
//
//  Created by Bill So on 6/14/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "VideoRowController.h"
#import "NMVideo.h"
#import "NMChannel.h"
#import "NMLibrary.h"


@implementation VideoRowController
@synthesize managedObjectContext=managedObjectContext_;
@synthesize fetchedResultsController=fetchedResultsController_;
@synthesize videoTableView;
@synthesize channel;

- (id)initWithFrame:(CGRect)aframe channel:(NMChannel *)chnObj {
	self = [super init];
	
	self.managedObjectContext = [NMTaskQueueController sharedTaskQueueController].dataController.managedObjectContext;
	self.channel = chnObj;
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
	videoTableView	= [[EasyTableView alloc] initWithFrame:aframe numberOfColumns:[sectionInfo numberOfObjects] ofWidth:98.0f];
	
	videoTableView.delegate					= self;
//	videoTableView.tableView.backgroundColor	= ;
	videoTableView.tableView.allowsSelection	= YES;
//	videoTableView.tableView.separatorColor	= [[UIColor blackColor] colorWithAlphaComponent:0.1];
//	videoTableView.cellBackgroundColor		= [[UIColor blackColor] colorWithAlphaComponent:0.1];
	videoTableView.autoresizingMask			= UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
	return self;
}

- (void)dealloc {
	[channel release];
	[videoTableView release];
	[fetchedResultsController_ release];
	[managedObjectContext_ release];
	[super dealloc];
}

#pragma mark -
#pragma mark EasyTableViewDelegate

// These delegate methods support both example views - first delegate method creates the necessary views

- (UIView *)easyTableView:(EasyTableView *)easyTableView viewForRect:(CGRect)rect {
	CGRect labelRect		= CGRectMake(10, 10, rect.size.width-20, rect.size.height-20);
	UILabel *label			= [[[UILabel alloc] initWithFrame:labelRect] autorelease];
	label.textAlignment		= UITextAlignmentCenter;
	label.textColor			= [UIColor whiteColor];
	label.font				= [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]];
	
	// Use a different color for the two different examples
	label.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.3];
	
//	UIImageView *borderView		= [[UIImageView alloc] initWithFrame:label.bounds];
//	borderView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
//	borderView.tag				= BORDER_VIEW_TAG;
//	
//	[label addSubview:borderView];
//	[borderView release];
	
	return label;
}

// Second delegate populates the views with data from a data source

- (void)easyTableView:(EasyTableView *)easyTableView setDataForView:(UIView *)view forIndex:(NSUInteger)index {
	UILabel *label	= (UILabel *)view;
	NMVideo * theVideo = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
	label.text		= theVideo.title;
	
	// selectedIndexPath can be nil so we need to test for that condition
//	BOOL isSelected = (easyTableView.selectedIndexPath) ? (easyTableView.selectedIndexPath.row == index) : NO;
//	[self borderIsSelected:isSelected forView:view];		
}

// Optional - Tracks the selection of a particular cell

- (void)easyTableView:(EasyTableView *)easyTableView selectedView:(UIView *)selectedView atIndex:(NSUInteger)index deselectedView:(UIView *)deselectedView {
//	[self borderIsSelected:YES forView:selectedView];		
//	
//	if (deselectedView) 
//		[self borderIsSelected:NO forView:deselectedView];
//	
//	UILabel *label	= (UILabel *)selectedView;
//	bigLabel.text	= label.text;
}

#pragma mark Fetched Results Controller
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
    NSEntityDescription *entity = [NSEntityDescription entityForName:NMVideoEntityName inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
	[fetchRequest setReturnsObjectsAsFaults:NO];
	
	// Make sure the condition here - predicate and sort order is EXACTLY the same as in deleteVideoInChannel:afterVideo: in data controller!!!
	// set predicate
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"channel == %@ AND nm_error == 0", channel]];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:5];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:YES];
	NSSortDescriptor * timestampDesc = [[NSSortDescriptor alloc] initWithKey:@"nm_fetch_timestamp" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:timestampDesc, sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [fetchRequest release];
    [sortDescriptor release];
	[timestampDesc release];
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

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	static NSUInteger theCount = 0;
	switch (type) {
		case NSFetchedResultsChangeDelete:
		{
			break;
		}
		case NSFetchedResultsChangeUpdate:
		case NSFetchedResultsChangeMove:
			break;
			
		default:
		{
			break;
		}
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
}



@end
