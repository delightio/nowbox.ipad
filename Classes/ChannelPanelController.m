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
#import "VideoRowTableView.h"
#import "SettingsViewController.h"
#import "ChannelManagementViewController.h"
#import "FeatureDebugViewController.h"
#import "ToolTipController.h"
#import "NMNavigationController.h"
#import "Analytics.h"

#define VIDEO_ROW_LEFT_PADDING			181.0f
#define NM_CHANNEL_CELL_LEFT_PADDING	10.0f
#define NM_CHANNEL_CELL_TOP_PADDING		10.0f
#define NM_CHANNEL_CELL_DETAIL_TOP_MARGIN	40.0f
#define NM_CONTAINER_VIEW_POOL_SIZE		8

NSString * const NMShouldPlayNewlySubscribedChannelNotification = @"NMShouldPlayNewlySubscribedChannelNotification";
BOOL NM_AIRPLAY_ACTIVE = NO;


@implementation ChannelPanelController
@synthesize panelView, tableView;
@synthesize managedObjectContext=managedObjectContext_;
@synthesize fetchedResultsController=fetchedResultsController_;
@synthesize videoViewController;
@synthesize selectedIndex;
@synthesize highlightedChannel, highlightedVideoIndex;
@synthesize displayMode;
@synthesize recycledVideoCells;

- (void)awakeFromNib {
	displayMode = NMHalfScreenMode;
    highlightedVideoIndex = -1;
	
#ifdef DEBUG_PANEL_ENABLED
	filterButton.hidden = NO;
#endif
    
	styleUtility = [NMStyleUtility sharedStyleUtility];
	tableView.rowHeight = NM_VIDEO_CELL_HEIGHT;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.managedObjectContext = [NMTaskQueueController sharedTaskQueueController].managedObjectContext;
	containerViewPool = [[NSMutableArray alloc] initWithCapacity:NM_CONTAINER_VIEW_POOL_SIZE];
    
    // Set up gesture recognizers
    UIPanGestureRecognizer *panningGesture = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(customPanning:)] autorelease];
    panningGesture.delegate = self;
    [tableView addGestureRecognizer:panningGesture];
    
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [scrollToTopArea addGestureRecognizer:doubleTapGestureRecognizer];
    [doubleTapGestureRecognizer release];
    
    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTapGestureRecognizer.numberOfTapsRequired = 1;
    [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
    [scrollToTopArea addGestureRecognizer:singleTapGestureRecognizer];
    [singleTapGestureRecognizer release];
    
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handlePlayNewlySubscribedChannelNotification:) name:NMShouldPlayNewlySubscribedChannelNotification object:nil];
	[nc addObserver:self selector:@selector(handleSubscriptionNotification:) name:NMDidSubscribeChannelNotification object:nil];
	[nc addObserver:self selector:@selector(handleSocialMediaLoginNotification:) name:NMDidVerifyUserNotification object:nil];

	// channel view is launched in split view configuration. set content inset
	tableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 360.0f, 0.0f);
    
    [nc addObserver:self selector:@selector(handleDidGetBeginPlayingVideoNotification:) name:NMWillBeginPlayingVideoNotification object:nil];

    recycledVideoCells = [[NSMutableSet alloc] init];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [tableView release];
	[containerViewPool release];
	[panelView release];
	[managedObjectContext_ release];
	[fetchedResultsController_ release];
    [recycledVideoCells release];
    
	[super dealloc];
}

#pragma mark View transition methods
- (void)postAnimationChangeForDisplayMode:(NMPlaybackViewModeType)aMode {
	switch (aMode) {
		case NMFullScreenChannelMode:
			tableView.contentInset = UIEdgeInsetsZero;
			break;
			
		case NMHalfScreenMode:
			tableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 360.0f, 0.0f);
			break;
			
		default:
			break;
	}
	tableView.scrollIndicatorInsets = tableView.contentInset;
}

- (void)setDisplayMode:(NMPlaybackViewModeType)aMode {
	switch (aMode) {
		case NMFullScreenChannelMode:
			[fullScreenButton setImage:styleUtility.toolbarCollapseImage forState:UIControlStateNormal];
			[fullScreenButton setImage:styleUtility.toolbarCollapseHighlightedImage forState:UIControlStateHighlighted];
			break;
			
		case NMHalfScreenMode:
			[fullScreenButton setImage:styleUtility.toolbarExpandImage forState:UIControlStateNormal];
			[fullScreenButton setImage:styleUtility.toolbarExpandHighlightedImage forState:UIControlStateHighlighted];
			break;
			
		default:
			break;
	}
	displayMode = aMode;
}

#pragma mark Target action methods
- (IBAction)showFeatureDebugView:(id)sender {
#ifdef DEBUG_PANEL_ENABLED
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

- (IBAction)showSettingsView:(id)sender {
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
    
    [[MixpanelAPI sharedAPI] track:AnalyticsEventShowSettings properties:[NSDictionary dictionaryWithObjectsAndKeys:highlightedChannel.title, AnalyticsPropertyChannelName, nil]];
}

- (IBAction)showChannelManagementView:(id)sender {	
	ChannelManagementViewController * chnMngCtrl = [[ChannelManagementViewController alloc] init];
	chnMngCtrl.managedObjectContext = videoViewController.managedObjectContext;
	NMNavigationController * navCtrl = [[NMNavigationController alloc] initWithRootViewController:chnMngCtrl];
	navCtrl.navigationBar.barStyle = UIBarStyleBlack;
	navCtrl.modalPresentationStyle = UIModalPresentationFormSheet;
	navCtrl.delegate = chnMngCtrl;
	[videoViewController presentModalViewController:navCtrl animated:YES];
	
	[navCtrl release];
	[chnMngCtrl release];
    
    [[ToolTipController sharedToolTipController] notifyEvent:ToolTipEventChannelManagementTap sender:sender];
    
    [[MixpanelAPI sharedAPI] track:AnalyticsEventShowChannelManagement properties:[NSDictionary dictionaryWithObjectsAndKeys:highlightedChannel.title, AnalyticsPropertyChannelName, nil]];
}

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
	[ctnView release];
	// create horizontal table controller
	VideoRowController * vdoCtrl = [[VideoRowController alloc] init];
	vdoCtrl.panelController = self;
	// create horizontal table view
	CGRect theFrame = aContentView.bounds;
	theFrame.size.width -= VIDEO_ROW_LEFT_PADDING;
	theFrame.origin.x += VIDEO_ROW_LEFT_PADDING;
	VideoRowTableView * videoTableView = [[VideoRowTableView alloc] init];
	videoTableView.frame = theFrame;
    [videoTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];

    videoTableView.orientedTableViewDataSource = vdoCtrl;
    [videoTableView setTableViewOrientation:kAGTableViewOrientationHorizontal];
    [videoTableView setShowsVerticalScrollIndicator:NO];
    [videoTableView setShowsHorizontalScrollIndicator:NO];
    
    [videoTableView setAlwaysBounceVertical:YES];
    
    videoTableView.allowsSelection = NO;
    videoTableView.delegate	= vdoCtrl;
	videoTableView.tableController = vdoCtrl;
	
    [videoTableView setOpaque:YES];
    [videoTableView setBackgroundColor:[UIColor colorWithRed:235/255.0f green:235/255.0f blue:235/255.0f alpha:1.0]];
    
    
    
    vdoCtrl.videoTableView = videoTableView;
	
    UIView *footer = [[UIView alloc] initWithFrame:CGRectZero];
    videoTableView.tableFooterView = footer;
    [footer release];
    
	videoTableView.tag = 1009;
	[aContentView insertSubview:videoTableView belowSubview:ctnView];
    
//    UIView *bottomSeparatorView = [[UIView alloc]initWithFrame:CGRectMake(167, aContentView.bounds.size.height-1, aContentView.bounds.size.width-167, 1)];
//    bottomSeparatorView.opaque = YES;
//    bottomSeparatorView.backgroundColor = styleUtility.channelBorderColor;
//    
//    [aContentView addSubview:bottomSeparatorView];
//    [bottomSeparatorView release];
    
    UIImageView *videoListLeftShadow = [[UIImageView alloc] initWithFrame:CGRectMake(181, 0, 8, aContentView.bounds.size.height)];
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
    if ([[theChannel.title componentsSeparatedByString:@" "] count] == 1) {
        CGPoint labelCenter = ctnView.textLabel.center;
        [ctnView.textLabel setFrame:CGRectMake(0, 0, ctnView.frame.size.width, 20)];
        ctnView.textLabel.center = labelCenter;
    } else {
        [ctnView.textLabel setFrame:CGRectMake(0, 0, ctnView.frame.size.width, cell.contentView.bounds.size.height)];
    }

    ctnView.newChannelIndicator.hidden = ![theChannel.nm_is_new boolValue];
	[ctnView.imageView setImageForChannel:theChannel];

	// video row
	AGOrientedTableView * htView = (AGOrientedTableView *)[cell viewWithTag:1009];
	htView.tableController.fetchedResultsController = nil;
	htView.tableController.channel = theChannel;
	htView.tableController.indexInTable = [indexPath row];
	htView.tableController.isLoadingNewContent = NO;
    htView.tableController.panelController = self;
    
    // rather than reload, should let the table take care of redraw
    
	[htView reloadData];
    if (!useSamePosition) {
        [htView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    }
    
NMTaskQueueController * schdlr = [NMTaskQueueController sharedTaskQueueController];
	if ( [theChannel.videos count] == 0 ) {
		htView.tableController.isLoadingNewContent = YES;
		// get more channels when a new row is created. issueGetMoreVideoForChannel: will be called again if the app begins a new session. But the backend will not queue the same command twice.
		[schdlr issueGetMoreVideoForChannel:theChannel];
	}
    
    if (highlightedChannel == theChannel) {
        [htView.tableController updateChannelTableView:[videoViewController currentVideoForPlayer:nil] animated:NO];
    }
    
    [ctnView setHighlighted:(highlightedChannel == theChannel)];

}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    [self configureCell:cell atIndexPath:indexPath retainPosition:NO];
}

- (void)didSelectNewVideoWithChannel:(NMChannel *)theChannel andVideoIndex:(NSInteger)newVideoIndex {
    // used for highlight / unhighlight row, and what to do when row is selected(?)
//    NSLog(@"deselected channel index: %@, video index: %d",[highlightedChannel title],highlightedVideoIndex);

    // first, unhighlight the old cell

    for (UITableViewCell *channelCell in [tableView visibleCells]) {
        for (PanelVideoCell *cell in [(AGOrientedTableView *)[channelCell viewWithTag:1009] visibleCells]) {
            if ([cell class] == [PanelVideoCell class]) {
                [cell setIsPlayingVideo:NO];
            }
        }
        ChannelContainerView * ctnView = (ChannelContainerView *)[channelCell viewWithTag:1001];
        [ctnView setHighlighted:NO];
    }
    
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:theChannel];

	selectedIndex = indexPath.row;
    highlightedChannel = theChannel;
    highlightedVideoIndex = newVideoIndex;

//    NSLog(@"selected channel index: %@, video index: %d",[theChannel title],newVideoIndex);

    UITableViewCell *channelCell = [tableView cellForRowAtIndexPath:indexPath];
    AGOrientedTableView * htView = (AGOrientedTableView *)[channelCell viewWithTag:1009];
    
    ChannelContainerView * ctnView = (ChannelContainerView *)[channelCell viewWithTag:1001];
    [ctnView setHighlighted:YES];
    [ctnView.newChannelIndicator setHidden:![theChannel.nm_is_new boolValue]];

    NSIndexPath* rowToReload = [NSIndexPath indexPathForRow:highlightedVideoIndex inSection:0];
    
    if ([htView numberOfRowsInSection:0] > 1) {
        PanelVideoCell *cell = (PanelVideoCell *)[htView cellForRowAtIndexPath:rowToReload];
        [cell setIsPlayingVideo:YES];
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

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [[ToolTipController sharedToolTipController] notifyEvent:ToolTipEventChannelListScroll sender:nil];
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
//	NSLog(@"selected column at index %d", [indexPath row]);
    
    [aTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    
    AGOrientedTableView * htView = (AGOrientedTableView *)[(UITableViewCell *)[aTableView cellForRowAtIndexPath:indexPath] viewWithTag:1009];
    
	// check if user has tapped the currently selected channel
	if ( [highlightedChannel isEqual:htView.tableController.channel] ) {
        [htView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:highlightedVideoIndex inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        return;
    }
    
	NSInteger c = [[[htView.tableController.fetchedResultsController sections] objectAtIndex:0] numberOfObjects];
    for (NSInteger i = 0; i < c; i++) {
        NMVideo * theVideo = [htView.tableController.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
//        NSLog(@"%@ %d", [theVideo title], theVideo.nm_playback_status);
		// only play video in that channel which has not been played before
        if ( theVideo.video.nm_playback_status >= 0 && !([theVideo.video.nm_did_play boolValue]) ) {
            [htView.tableController playVideoForIndexPath:[NSIndexPath indexPathForRow:i inSection:0] sender:aTableView];
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
	
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"nm_subscribed > 0 AND nm_hidden == NO"]];
	
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


-(NSInteger)highlightedChannelIndex {
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:highlightedChannel];
    return [indexPath row];
}

#pragma mark -
#pragma mark Fetched results controller delegate


- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    if (!massUpdate) {
        [tableView beginUpdates];
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    if (massUpdate) return;

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
    
    if (massUpdate) return;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert: {
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        }
        case NSFetchedResultsChangeDelete: {
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            
			if ( selectedIndex == indexPath.row ) {
				// Go to next channel, or first channel if we're at the end of the list
				NSInteger numberOfRows = [[[controller sections] objectAtIndex:0] numberOfObjects];
				
				NSIndexPath *nextChannelIndexPath = nil;
				if (indexPath.row < numberOfRows) {
					nextChannelIndexPath = indexPath;
				} else if (numberOfRows > 0) {
					nextChannelIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
				}
						   
				if (nextChannelIndexPath) {
					NMChannel *channel = [controller objectAtIndexPath:nextChannelIndexPath];
                    NSArray *videos = [[NMTaskQueueController sharedTaskQueueController].dataController sortedVideoListForChannel:channel];

                    // do not use setCurrentChannel:startPlaying:. It's for app launch case. This is not a good method name... But em... let's improve this later on if needed.
                    if ([videos count] > 0) {
                        [videoViewController playVideo:[videos objectAtIndex:0]];
                    }
				}
			}
            
            break;
        } 
        case NSFetchedResultsChangeUpdate: {
            // the entire channel row shouldn't have to be reconfigured, this should be done in the video row controller
            UITableViewCell *cell = (UITableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
            AGOrientedTableView * htView = (AGOrientedTableView *)[cell viewWithTag:1009];
            htView.tableController.indexInTable = [newIndexPath row];
            if (htView.tableController.channel == highlightedChannel) {
                [self didSelectNewVideoWithChannel:htView.tableController.channel andVideoIndex:highlightedVideoIndex];
            }
            //            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath retainPosition:YES];	
            break;
        }
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if (massUpdate) {
        [tableView reloadData];
        massUpdate = NO;
    } else {
        [tableView endUpdates];
    }
}

# pragma mark - Gesture recognizers

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

- (void)handleSingleTap:(UITapGestureRecognizer *)sender {
    // Scroll to top
    [tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)sender {
    // Scroll to current channel
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:highlightedChannel];
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

#pragma mark play newly subscribed channel
- (void)handlePlayNewlySubscribedChannelNotification:(NSNotification *)aNotification {
	NMChannel * targetChn = [[aNotification userInfo] objectForKey:@"channel"];
	// do not proceed if not the same channel object as the current one.
//    NSLog(@"CHDESC: %@", [targetChn description]);
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:targetChn];
//    NSLog(@"ROW: %d", [indexPath row]);
    if ([tableView numberOfRowsInSection:0]>0) {
        UITableViewCell *channelCell = [tableView cellForRowAtIndexPath:indexPath];
        AGOrientedTableView * htView = (AGOrientedTableView *)[channelCell viewWithTag:1009];
        // htview num rows always have at least 1 because of the loading cell, checking against the FRC object would be a better idea down the line
        if ([htView numberOfRowsInSection:0] > 1) {
            [htView.tableController playVideoForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] sender:self];
        }
    }
}

- (void)handleSubscriptionNotification:(NSNotification *)aNotification {
    [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[tableView numberOfRowsInSection:0]-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}


#pragma mark new video begin playing
- (void)handleDidGetBeginPlayingVideoNotification:(NSNotification *)aNotification {
    NMVideo *newVideo = [[aNotification userInfo] objectForKey:@"video"];
    highlightedChannel = [newVideo channel];
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:highlightedChannel];
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

- (void)handleSocialMediaLoginNotification:(NSNotification *)aNotification {
    massUpdate = YES;
}

@end
