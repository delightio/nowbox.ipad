//
//  ChannelPanelController.m
//  ipad
//
//  Created by Bill So on 6/13/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "ChannelPanelController.h"
#import "NMLibrary.h"
#import "VideoPlaybackViewController.h"
#import "VideoRowController.h"
#import "ChannelContainerView.h"
#import "AGOrientedTableView.h"
#import "PanelVideoContainerView.h"
#import "SettingsViewController.h"
#import "ChannelManagementViewController.h"
#import "FeatureDebugViewController.h"

#define VIDEO_ROW_LEFT_PADDING			167.0f
#define NM_CHANNEL_CELL_LEFT_PADDING	10.0f
#define NM_CHANNEL_CELL_TOP_PADDING		10.0f
#define NM_CHANNEL_CELL_DETAIL_TOP_MARGIN	40.0f
#define NM_CONTAINER_VIEW_POOL_SIZE		8

@implementation ChannelPanelController
@synthesize panelView, tableView;
@synthesize managedObjectContext=managedObjectContext_;
@synthesize fetchedResultsController=fetchedResultsController_;
@synthesize videoViewController;
@synthesize selectedIndex;
@synthesize highlightedChannelIndex, highlightedVideoIndex;

- (void)awakeFromNib {
	styleUtility = [NMStyleUtility sharedStyleUtility];
	tableView.rowHeight = NM_VIDEO_CELL_HEIGHT;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//	tableView.separatorColor = [UIColor clearColor];
//	tableView.separatorColor = styleUtility.channelBorderColor;
	tableView.backgroundColor = [UIColor viewFlipsideBackgroundColor];
	self.managedObjectContext = [NMTaskQueueController sharedTaskQueueController].managedObjectContext;
	containerViewPool = [[NSMutableArray alloc] initWithCapacity:NM_CONTAINER_VIEW_POOL_SIZE];
    
    UIPanGestureRecognizer *panningGesture = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(customPanning:)] autorelease];
    panningGesture.delegate = self;
    [tableView addGestureRecognizer:panningGesture];
}

- (void)dealloc {
	[containerViewPool release];
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
- (IBAction)showFeatureDebugView:(id)sender {
#ifdef DEBUG_PLAYER_NAVIGATION
	FeatureDebugViewController * featureCtrl = [[FeatureDebugViewController alloc] initWithNibName:@"FeatureDebugView" bundle:nil];
	featureCtrl.selectedChannel = videoViewController.currentChannel;
	featureCtrl.playbackViewController = videoViewController;
	UINavigationController * navCtrl = [[UINavigationController alloc] initWithRootViewController:featureCtrl];
	
	UIPopoverController * popover = [[UIPopoverController alloc] initWithContentViewController:navCtrl];
	
	[featureCtrl release];
	[navCtrl release];
	popover.popoverContentSize = CGSizeMake(320.0f, 320.0f);
	[popover presentPopoverFromRect:filterButton.frame inView:panelView permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
	popover.delegate = self;
#endif
}

- (IBAction)toggleTableEditMode:(id)sender {
	[tableView setEditing:!tableView.editing animated:YES];
}

- (IBAction)debugRefreshChannel:(id)sender {
	[[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
}

- (IBAction)showSettingsView:(id)sender {
//	SettingsViewController * settingCtrl = [[SettingsViewController alloc] initWithNibName:@"SettingsView" bundle:nil];
	SettingsViewController * settingCtrl = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
	UINavigationController * navCtrl = [[UINavigationController alloc] initWithRootViewController:settingCtrl];
	navCtrl.navigationBar.barStyle = UIBarStyleBlack;
	navCtrl.modalPresentationStyle = UIModalPresentationFormSheet;
	
	[videoViewController presentModalViewController:navCtrl animated:YES];
	
//	UIPopoverController * popover = [[UIPopoverController alloc] initWithContentViewController:navCtrl];
	[settingCtrl release];
	[navCtrl release];
//	popover.popoverContentSize = CGSizeMake(320.0f, 480.0f);
//	[popover presentPopoverFromRect:settingButton.frame inView:panelView permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
//	popover.delegate = self;
}

- (IBAction)showChannelManagementView:(id)sender {	
	ChannelManagementViewController * chnMngCtrl = [[ChannelManagementViewController alloc] init];
	chnMngCtrl.managedObjectContext = videoViewController.managedObjectContext;
	UINavigationController * navCtrl = [[UINavigationController alloc] initWithRootViewController:chnMngCtrl];
	navCtrl.navigationBar.barStyle = UIBarStyleBlack;
	navCtrl.modalPresentationStyle = UIModalPresentationFormSheet;
	[videoViewController presentModalViewController:navCtrl animated:YES];
	
	[navCtrl release];
	[chnMngCtrl release];
}

//- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
//	[popoverController release];
//}

- (void)queueColumnView:(UIView *)vw {
    if ([containerViewPool count] >= NM_CONTAINER_VIEW_POOL_SIZE) {
        return;
    }
    [containerViewPool addObject:vw];
}

- (UIView *)dequeueColumnView {
    UIView *vw = [[containerViewPool lastObject] retain];
    if (vw) {
        [containerViewPool removeLastObject];
		[vw autorelease];
    }
    return vw;
}

#pragma mark Other table methods
- (void)setupCellContentView:(UIView *)aContentView {
	ChannelContainerView * ctnView = [[ChannelContainerView alloc] initWithHeight:aContentView.bounds.size.height];
	ctnView.tag = 1001;
    [ctnView setNeedsDisplay];
	[aContentView addSubview:ctnView];
	// create horizontal table controller
	VideoRowController * vdoCtrl = [[VideoRowController alloc] init];
	vdoCtrl.panelController = self;
	// create horizontal table view
	CGRect theFrame = aContentView.bounds;
	theFrame.size.width -= VIDEO_ROW_LEFT_PADDING;
	theFrame.origin.x += VIDEO_ROW_LEFT_PADDING;
	AGOrientedTableView * videoTableView = [[AGOrientedTableView alloc] init];
	videoTableView.frame = theFrame;
    videoTableView.separatorColor = styleUtility.channelBorderColor;

    videoTableView.orientedTableViewDataSource = vdoCtrl;
    [videoTableView setTableViewOrientation:kAGTableViewOrientationHorizontal];
    [videoTableView setShowsVerticalScrollIndicator:NO];
    [videoTableView setShowsHorizontalScrollIndicator:NO];
    
    [videoTableView setAlwaysBounceVertical:YES];
    
    videoTableView.allowsSelection = NO;
    videoTableView.delegate	= vdoCtrl;
	videoTableView.tableController = vdoCtrl;
	vdoCtrl.videoTableView = videoTableView;
	
	videoTableView.tag = 1009;
	[aContentView insertSubview:videoTableView belowSubview:ctnView];
    
    UIView *loadingOverlayView = [[UIView alloc]initWithFrame:theFrame];
    loadingOverlayView.tag = 1008;
    [loadingOverlayView setBackgroundColor:styleUtility.channelPanelBackgroundColor];
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityView.center = CGPointMake(425, 44);
    [activityView startAnimating];
    [loadingOverlayView addSubview:activityView];
    [activityView release];
    [aContentView insertSubview:loadingOverlayView aboveSubview:videoTableView];
    [loadingOverlayView release];
    
    UIView *bottomSeparatorView = [[UIView alloc]initWithFrame:CGRectMake(167, aContentView.bounds.size.height-1, aContentView.bounds.size.width-167, 1)];
    bottomSeparatorView.opaque = YES;
    bottomSeparatorView.backgroundColor = styleUtility.channelBorderColor;
    
    [aContentView addSubview:bottomSeparatorView];
    [bottomSeparatorView release];
    
    UIImageView *videoListLeftShadow = [[UIImageView alloc] initWithFrame:CGRectMake(168, 0, 9, aContentView.bounds.size.height)];
    videoListLeftShadow.image = [UIImage imageNamed:@"channel-shadow-background-right"];
    [aContentView addSubview:videoListLeftShadow];
    [videoListLeftShadow release];
    
	// release everything
	[videoTableView release];
	[vdoCtrl release];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath retainPosition:(BOOL)useSamePosition {
    
	// channel
	ChannelContainerView * ctnView = (ChannelContainerView *)[cell viewWithTag:1001];
	NMChannel * theChannel = (NMChannel *)[self.fetchedResultsController objectAtIndexPath:indexPath];
	ctnView.textLabel.text = theChannel.title;
	[ctnView.imageView setImageForChannel:theChannel];
    [ctnView setNeedsDisplay];

	// video row
	AGOrientedTableView * htView = (AGOrientedTableView *)[cell viewWithTag:1009];
	htView.tableController.fetchedResultsController = nil;
	htView.tableController.channel = theChannel;
    htView.tableController.indexInTable = [indexPath row];
    htView.tableController.isLoadingNewContent = NO;
    
	[htView reloadData];
    if (!useSamePosition) {
        [htView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    }
    
    UIView * loadingOverlayView = (UIView *)[cell viewWithTag:1008];
    [loadingOverlayView setHidden:([htView numberOfRowsInSection:0] > 1)];
    
NMTaskQueueController * schdlr = [NMTaskQueueController sharedTaskQueueController];
	if ( theChannel == nil || [theChannel.videos count] == 0 ) {
		[schdlr issueGetVideoListForChannel:theChannel];
	}
    
    if (highlightedChannelIndex == [indexPath row]) {
        [htView.tableController updateChannelTableView:[videoViewController currentVideoForPlayer:nil] animated:NO];
    }

}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    [self configureCell:cell atIndexPath:indexPath retainPosition:NO];
}

- (void)didSelectNewVideoWithChannelIndex:(NSInteger)newChannelIndex andVideoIndex:(NSInteger)newVideoIndex {
    // used for highlight / unhighlight row, and what to do when row is selected(?)
//    NSLog(@"selected channel index: %d, video index: %d",newChannelIndex,newVideoIndex);

    // first, unhighlight the old cell
    if ((newVideoIndex != highlightedVideoIndex) || (newChannelIndex != highlightedChannelIndex)) {
        UITableViewCell *channelCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:highlightedChannelIndex inSection:0]];
        AGOrientedTableView * htView = (AGOrientedTableView *)[channelCell viewWithTag:1009];
        
        NSIndexPath* rowToReload = [NSIndexPath indexPathForRow:highlightedVideoIndex inSection:0];
        PanelVideoContainerView *cell = (PanelVideoContainerView *)[htView cellForRowAtIndexPath:rowToReload];
        [cell setIsPlayingVideo:NO];
    }

    highlightedChannelIndex = newChannelIndex;
    highlightedVideoIndex = newVideoIndex;

    UITableViewCell *channelCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:highlightedChannelIndex inSection:0]];
    AGOrientedTableView * htView = (AGOrientedTableView *)[channelCell viewWithTag:1009];
    
    NSIndexPath* rowToReload = [NSIndexPath indexPathForRow:highlightedVideoIndex inSection:0];
    PanelVideoContainerView *cell = (PanelVideoContainerView *)[htView cellForRowAtIndexPath:rowToReload];
    [cell setIsPlayingVideo:YES];

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
    
    static NSString *CellIdentifier = @"WholeVideoRow";
    
	UITableViewCell *cell = (UITableViewCell *)[aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        [cell setFrame:CGRectMake(0, 0, 1024, NM_VIDEO_CELL_HEIGHT)];
		cell.clipsToBounds = NO;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
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

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// clear the previous selection
	selectedIndex = [indexPath row];
	NSLog(@"selected column at index %d", [indexPath row]);
    
    AGOrientedTableView * htView = (AGOrientedTableView *)[(UITableViewCell *)[aTableView cellForRowAtIndexPath:indexPath] viewWithTag:1009];
    
    for (int i=0; i<[[[htView.tableController.fetchedResultsController sections] objectAtIndex:0] numberOfObjects]; i++) {
        NMVideo * theVideo = [htView.tableController.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        NSLog(@"%@ %d", [theVideo title], [theVideo nm_playback_status]);
//        if (([theVideo nm_playback_status] >= 0) && ([theVideo nm_playback_status] < NMVideoQueueStatusPlaying)) {
        if ([theVideo nm_playback_status] >= 0) {
            [htView.tableController playVideoForIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            break;
        }
    }
}

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
	
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"nm_subscribed == %@", [NSNumber numberWithBool:YES]]];
	
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
            
        case NSFetchedResultsChangeInsert: {
            if ([newIndexPath row] <= highlightedChannelIndex) {
                highlightedChannelIndex++;
            }
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        }
        case NSFetchedResultsChangeDelete:
            if ([newIndexPath row] <= highlightedChannelIndex) {
                highlightedChannelIndex--;
            }
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
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
    for (int i=0; i<[sectionInfo numberOfObjects]; i++) {
        NMChannel * theChannel = (NMChannel *)[self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if (theChannel == videoViewController.currentChannel) {
            highlightedChannelIndex = i;
            break;
        }
    }

    [tableView endUpdates];
}


# pragma mark swipe gestures
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // override default tableview panning gesture
    
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        return YES;
    }
    
    return YES;
}

-(void)customPanning:(UIPanGestureRecognizer *)sender {
    // force inner tableview to bounce
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
        {
            CGPoint velocity = [sender velocityInView:tableView];
            if(fabsf(velocity.x) > fabsf(velocity.y)) // moving left-right
            {
                tableView.scrollEnabled = NO;
            }
            else // moving up-down
            {
                tableView.scrollEnabled = YES;
            }
        }
            break;
        case UIGestureRecognizerStateChanged:
            break;
        case UIGestureRecognizerStateEnded:
            tableView.scrollEnabled = YES;
            break;
        default:
            break;
    }
}


@end
