//
//  SearchDebugViewController.m
//  ipad
//
//  Created by Bill So on 18/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "FeatureDebugViewController.h"
#import "VideoPlaybackViewController.h"

@implementation FeatureDebugViewController
@synthesize targetChannel, selectedChannel;
@synthesize playbackViewController;
@synthesize fetchedResultsController=fetchedResultsController_;

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

- (void)dealloc {
	[selectedChannel release];
	[targetChannel release];
	[playbackViewController release];
	[fetchedResultsController_ release];
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
	// notification
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleWillLoadNotification:) name:NMWillSearchChannelsNotification object:nil];
	[nc addObserver:self selector:@selector(handleDidSearchNotification:) name:NMDidSearchChannelsNotification object:nil];
	
	[nc addObserver:self selector:@selector(handleWillLoadNotification:) name:NMWillSubscribeChannelNotification object:nil];
	[nc addObserver:self selector:@selector(handleWillLoadNotification:) name:NMWillUnsubscribeChannelNotification object:nil];
	[nc addObserver:self selector:@selector(handleSubscriptionNotification:) name:NMDidSubscribeChannelNotification object:nil];
	[nc addObserver:self selector:@selector(handleSubscriptionNotification:) name:NMDidUnsubscribeChannelNotification object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark Notification handlers

- (void)handleWillLoadNotification:(NSNotification *)aNotification {
	NSLog(@"notification: %@", [aNotification name]);
}

- (void)handleDidSearchNotification:(NSNotification *)aNotification {
	NSLog(@"notification: %@", [aNotification name]);
	// test out search predicate
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	NMDataController * dataCtrl = [NMTaskQueueController sharedTaskQueueController].dataController;
	[request setEntity:[NSEntityDescription entityForName:NMChannelEntityName inManagedObjectContext:dataCtrl.managedObjectContext]];
	[request setPredicate:dataCtrl.searchResultsPredicate];
	NSArray * result = [dataCtrl.managedObjectContext executeFetchRequest:request error:nil];
	NSLog(@"search result %@", result);
	[request release];
}

- (void)handleSubscriptionNotification:(NSNotification *)aNotification {
	NSString * notName = [aNotification name];
	NSDictionary * userInfo = [aNotification userInfo];
	if ( [notName isEqualToString:NMDidUnsubscribeChannelNotification] ) {
		self.targetChannel = [userInfo objectForKey:@"channel"];
		NSLog(@"unsubscribed channel: %@", targetChannel.title);
	} else if ( [notName isEqualToString:NMDidSubscribeChannelNotification] ) {
		self.targetChannel = [userInfo objectForKey:@"channel"];
		NSLog(@"subscribed channel: %@", targetChannel.title);
		self.targetChannel = nil;
	}
}

#pragma mark Target action methods

- (IBAction)submitSearch:(id)sender {
	NMTaskQueueController * ctrl = [NMTaskQueueController sharedTaskQueueController];
	[ctrl.dataController clearSearchResultCache];
	[ctrl issueChannelSearchForKeyword:@"comedy"];
}

- (IBAction)submitSubscribeChannel:(id)sender {
	if ( targetChannel ) {
		[[NMTaskQueueController sharedTaskQueueController] issueSubscribe:YES channel:targetChannel];
	}
}

- (IBAction)submitUnsubscribeChannel:(id)sender {
	// unsubscribe a channel
	NMTaskQueueController * queueCtrl = [NMTaskQueueController sharedTaskQueueController];
	NSArray * results = queueCtrl.dataController.subscribedChannels;
	if ( [results count] ) {
		NMChannel * chnObj = [results objectAtIndex:0];
		[queueCtrl issueSubscribe:NO channel:chnObj];
	}
}

- (IBAction)getCurrentSubscription:(id)sender {
	NMTaskQueueController * queueCtrl = [NMTaskQueueController sharedTaskQueueController];
	NSArray * results = queueCtrl.dataController.subscribedChannels;
	NSLog(@"Subscription List:");
	for (NMChannel * chnObj in results) {
		NSLog(@"%@", chnObj.title);
	}
}

- (IBAction)fetchMoreVideoForCurrentChannel:(id)sender {
	[[NMTaskQueueController sharedTaskQueueController] issueGetMoreVideoForChannel:selectedChannel];
}

- (IBAction)debugPlaybackQueue:(id)sender {
//	NMAVQueuePlayer * qPlayer = [playbackViewController getQueuePlayer];
//	NSArray * itemsAy = qPlayer.items;
//	NSLog(@"num video in queue: %d", [itemsAy count]);
//	for (NMAVPlayerItem * item in itemsAy) {
//		NSLog(@"\t%@", item.nmVideo.title);
//	}
}

#pragma mark Table View
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath retainPosition:(BOOL)pos {
	NMChannel * chn = [self.fetchedResultsController objectAtIndexPath:indexPath];
	cell.textLabel.text = chn.title;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"MyRow";
    
	UITableViewCell *cell = (UITableViewCell *)[aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell.
	[self configureCell:cell atIndexPath:indexPath retainPosition:NO];
    
    return cell;
}

#pragma mark Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (fetchedResultsController_ != nil) {
        return fetchedResultsController_;
    }
	
	NMDataController * dataCtrl = [NMTaskQueueController sharedTaskQueueController].dataController;
	NSManagedObjectContext * managedObjectContext = dataCtrl.managedObjectContext;
    
    /*
     Set up the fetched results controller.
	 */
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:NMChannelEntityName inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
	[fetchRequest setReturnsObjectsAsFaults:NO];
	//	[fetchRequest setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"videos"]];
	
	[fetchRequest setPredicate:dataCtrl.searchResultsPredicate];
	
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:managedObjectContext sectionNameKeyPath:nil cacheName:nil];
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
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath retainPosition:YES];
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
