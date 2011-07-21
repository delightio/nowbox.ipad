//
//  VideoRowController.m
//  ipad
//
//  Created by Bill So on 6/14/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "VideoRowController.h"
#import "PanelVideoContainerView.h"
#import "ChannelContainerView.h"
#import "VideoPlaybackViewController.h"


@implementation VideoRowController
@synthesize managedObjectContext=managedObjectContext_;
@synthesize fetchedResultsController=fetchedResultsController_;
@synthesize videoTableView;
@synthesize channel, panelController;
@synthesize indexInTable;


#define kShortVideoLengthSeconds   60
#define kMediumVideoLengthSeconds   300
#define kShortVideoCellWidth    150.0f
#define kMediumVideoCellWidth    225.0f
#define kLongVideoCellWidth    300.0f




- (id)init {
	self = [super init];
	styleUtility = [NMStyleUtility sharedStyleUtility];
	
	self.managedObjectContext = [NMTaskQueueController sharedTaskQueueController].dataController.managedObjectContext;
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleDidGetBeginPlayingVideoNotification:) name:NMWillBeginPlayingVideoNotification object:nil];
	return self;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[channel release];
	[fetchedResultsController_ release];
	[managedObjectContext_ release];
	[super dealloc];
}

#pragma mark -
#pragma mark UITableViewDelegate and UITableViewDatasource methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
	return [sectionInfo numberOfObjects];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NMVideo * theVideo = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:[indexPath row] inSection:0]];
        //TODO: seems to be bugging out other interaction, left out for now
    [panelController.videoViewController playVideo:theVideo];
    
    [panelController didSelectNewVideoWithChannelIndex:indexInTable andVideoIndex:[indexPath row]];
}

- (UITableViewCell *)tableView:(AGOrientedTableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)anIndexPath
{
    PanelVideoContainerView *result = (PanelVideoContainerView *)[aTableView dequeueReusableCellWithIdentifier:@"Reuse"];
    if (nil == result)
    {
        result = [[[PanelVideoContainerView alloc] initWithFrame:CGRectMake(0.0, 0.0, 267.0, 80.0)] autorelease];
		result.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		result.tableView = aTableView;
    }
    
	
	if ( panelController.videoViewController.currentChannel == channel && [anIndexPath row] == panelController.selectedIndex ) {
		result.highlighted = YES;
	} else {
		result.highlighted = NO;
	}
    
    NMVideo * theVideo = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:[anIndexPath row] inSection:0]];
	result.indexInTable = [anIndexPath row];
    if ([theVideo.duration intValue] <= kShortVideoLengthSeconds) {
        [result setFrame:CGRectMake(0, 0, kShortVideoCellWidth, 80)];
    }
    else if ([theVideo.duration intValue] <= kMediumVideoLengthSeconds) {
        [result setFrame:CGRectMake(0, 0, kMediumVideoCellWidth, 80)];
    }
    else {
        [result setFrame:CGRectMake(0, 0, kLongVideoCellWidth, 80)];
    }
    [result setVideoRowDelegate:self];
	[result setVideoInfo:theVideo];
    return (UITableViewCell *)result;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NMVideo * theVideo = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:[indexPath row] inSection:0]];

    if ([theVideo.duration intValue] <= kShortVideoLengthSeconds) {
        return kShortVideoCellWidth;
    }
    else if ([theVideo.duration intValue] <= kMediumVideoLengthSeconds) {
        return kMediumVideoCellWidth;
    }
    else {
        return kLongVideoCellWidth;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
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
//	static NSUInteger theCount = 0;
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


#pragma mark Notification handling
- (void)handleDidGetBeginPlayingVideoNotification:(NSNotification *)aNotification {
	NSLog(@"notification received");
    NMVideo *newVideo = [[aNotification userInfo] objectForKey:@"video"];
    
    if (newVideo) {
        if ([newVideo channel] == channel) {
            // scroll to the current channel
            [videoTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:panelController.selectedIndex inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
            
            // select / deselect cells
            [panelController didSelectNewVideoWithChannelIndex:indexInTable andVideoIndex:panelController.selectedIndex];
        }
        else {
            // let other channels deal with their own notifications
        }
    }
    
}


@end