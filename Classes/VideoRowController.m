//
//  VideoRowController.m
//  ipad
//
//  Created by Bill So on 6/14/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "VideoRowController.h"
#import "ChannelContainerView.h"
#import "VideoPlaybackViewController.h"
#import "PanelVideoCell.h"
#import "Analytics.h"
#import "UIView+InteractiveAnimation.h"

#define kShortVideoLengthSeconds    120
#define kMediumVideoLengthSeconds   600
#define kShortVideoCellWidth        202.0f
#define kMediumVideoCellWidth       404.0f
#define kLongVideoCellWidth         606.0f
#define kLoadingViewWidth           154.0f
#define kPullToRefreshDistance      (kLoadingViewWidth * 0.8)

@interface VideoRowController (PrivateMethods)
- (NSArray *)sortDescriptors;
- (void)hidePullToRefreshView;
@end

@implementation VideoRowController

@synthesize managedObjectContext = managedObjectContext_;
@synthesize fetchedResultsController = fetchedResultsController_;
@synthesize videoTableView;
@synthesize channel, panelController;
@synthesize indexInTable;
@synthesize isLoadingNewContent;
@synthesize pullToRefreshView;
@synthesize loadingCell;

- (id)init {
	self = [super init];
    if (self) {
        self.managedObjectContext = [NMTaskQueueController sharedTaskQueueController].dataController.managedObjectContext;
        
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(handleDidGetBeginPlayingVideoNotification:) name:NMWillBeginPlayingVideoNotification object:nil];
        [nc addObserver:self selector:@selector(handleDidGetChannelVideoListNotification:) name:NMDidGetChannelVideoListNotification object:nil];
        [nc addObserver:self selector:@selector(handleDidFailGetChannelVideoListNotification:) name:NMDidFailGetChannelVideoListNotification object:nil];
        [nc addObserver:self selector:@selector(handleDidCancelGetChannelVideListNotification:) name:NMDidCancelGetChannelVideListNotification object:nil];
        [nc addObserver:self selector:@selector(handleNewSessionNotification:) name:NMBeginNewSessionNotification object:nil];
        [nc addObserver:self selector:@selector(handleSortOrderDidChangeNotification:) name:NMSortOrderDidChangeNotification object:nil];
        
        [[NSBundle mainBundle] loadNibNamed:@"VideoPanelPullToRefreshView" owner:self options:nil];
        pullToRefreshView.transform = CGAffineTransformMakeRotation(M_PI_2);
    }
    
    return self;
}


- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[channel release];
	[fetchedResultsController_ release];
	[managedObjectContext_ release];

    for (PanelVideoCell *cell in videoTableView.visibleCells) {
        // Otherwise we get a bad access when the cell tries to recycle itself to the row delegate (this object)
        [cell setVideoRowDelegate:nil];
    }
    [videoTableView release];
    [pullToRefreshView release];
    [loadingCell release];
    
	[super dealloc];
}

- (void)setVideoTableView:(AGOrientedTableView *)aVideoTableView
{
    if (videoTableView != aVideoTableView) {
        [videoTableView release];
        videoTableView = [aVideoTableView retain];
    }

    pullToRefreshView.frame = CGRectMake(0, -kLoadingViewWidth, videoTableView.frame.size.height, kLoadingViewWidth);
    [videoTableView insertSubview:pullToRefreshView atIndex:0];
}

- (void)hidePullToRefreshView
{
    [UIView animateWithInteractiveDuration:0.3
                                animations:^{
                                    videoTableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
                                }
                                completion:^(BOOL finished){
                                    [pullToRefreshView.activityIndicator stopAnimating];
                                    pullToRefreshView.loadingText.text = @"";
                                }];            
}

#pragma mark - UITableViewDelegate and UITableViewDatasource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
	return [sectionInfo numberOfObjects]+1;
}

- (void)playVideoForIndexPath:(NSIndexPath *)indexPath sender:(id)sender 
{
	PanelVideoCell *vdoCell = (PanelVideoCell *)[videoTableView cellForRowAtIndexPath:indexPath];
	if ( vdoCell.isPlayingVideo ) {
		return;
	}
	if ( !NM_AIRPLAY_ACTIVE ) 
		[panelController.videoViewController channelPanelToggleToFullScreen:NO resumePlaying:NO centerToRow:indexInTable];
    [panelController didSelectNewVideoWithChannel:channel andVideoIndex:[indexPath row]];
    NMVideo * theVideo = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:[indexPath row] inSection:0]];
    [panelController.videoViewController playVideo:theVideo];
    
    NSString *senderStr;
    if ([sender isKindOfClass:[PanelVideoCell class]]) {
        senderStr = @"channelpanel_videocell";
    } else if ([sender isKindOfClass:[ChannelPanelController class]]) {
        senderStr = @"channelmanagement_watchnow";
    } else {
        senderStr = @"channelpanel_channelcolumn";
    }
    [[MixpanelAPI sharedAPI] track:AnalyticsEventPlayVideo properties:[NSDictionary dictionaryWithObjectsAndKeys:channel.title, AnalyticsPropertyChannelName, 
                                                                       theVideo.title, AnalyticsPropertyVideoName, 
                                                                       theVideo.nm_id, AnalyticsPropertyVideoId,
                                                                       senderStr, AnalyticsPropertySender, 
                                                                       @"tap", AnalyticsPropertyAction,
                                                                       [NSNumber numberWithBool:NM_AIRPLAY_ACTIVE], AnalyticsPropertyAirPlayActive, nil]];
}

- (void)recycleCell:(PanelVideoCell *)cell
{
    [panelController.recycledVideoCells addObject:cell];
}

- (UITableViewCell *)tableView:(AGOrientedTableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)anIndexPath
{    
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
	if ([sectionInfo numberOfObjects] == [anIndexPath row]) {
        static NSString *CellIdentifier = @"LoadMoreView";
        
        PanelVideoCell *cell = (PanelVideoCell *) [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            [[NSBundle mainBundle] loadNibNamed:@"VideoPanelLoadMoreView" owner:self options:nil];
            cell = loadingCell;
            [cell setLoadingCell:YES];
            self.loadingCell = nil;
        }
        [cell setHidden:!isLoadingNewContent];
        
        if ([channel.populated_at timeIntervalSince1970] > 0 || [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects] > 0) {
            cell.loadingText.text = @"Loading videos...";
        } else {
            cell.loadingText.text = @"Processing channel...";
        }
        
        CGRect frame = cell.activityIndicator.frame;
        frame.origin.x = [cell.loadingText.text sizeWithFont:cell.loadingText.font constrainedToSize:cell.loadingText.frame.size lineBreakMode:cell.loadingText.lineBreakMode].width + 22;
        cell.activityIndicator.frame = frame;
        
        return (UITableViewCell *)cell;
    }
    
    static NSString *CellIdentifier = @"VideoCell";
    PanelVideoCell *cell = [[[panelController.recycledVideoCells anyObject] retain] autorelease];
    if (cell) {
        [panelController.recycledVideoCells removeObject:cell];
    } else {
        cell = [[[PanelVideoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell
    NMVideo *theVideo = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:[anIndexPath row] inSection:0]];
    NMDataController *dataCtrl = [NMTaskQueueController sharedTaskQueueController].dataController;
    
    BOOL isVideoPlayable = ([[theVideo nm_error] intValue] == 0) && (theVideo.nm_playback_status >= 0);
    BOOL isVideoFavorited = (([[theVideo nm_favorite] intValue] == 1) && ([theVideo channel] != [dataCtrl favoriteVideoChannel]));
    BOOL isVideoQueued = (([[theVideo nm_watch_later] intValue] == 1) && ([theVideo channel] != [dataCtrl myQueueChannel]));

    if (!isVideoPlayable) {
        [cell setState:PanelVideoCellStateUnplayable];
    } else if (isVideoFavorited) {
        [cell setState:PanelVideoCellStateFavorite];
    } else if (isVideoQueued) {
        [cell setState:PanelVideoCellStateQueued];
    } else {
        [cell setState:PanelVideoCellStateDefault];
    }
    
    [cell setTitle:theVideo.title];
    [cell setDateString:[[NMStyleUtility sharedStyleUtility].videoDateFormatter stringFromDate:theVideo.published_at]];
    [cell setTag:anIndexPath.row];
    [cell setVideoRowDelegate:self];
    [cell setViewed:[theVideo.nm_did_play boolValue]];
    
    NSInteger duration = [theVideo.duration integerValue];
	[cell setDuration:[NSString stringWithFormat:@"%02d:%02d", duration / 60, duration % 60]];

    if ( panelController.highlightedChannel == channel && [anIndexPath row] == panelController.highlightedVideoIndex ) {
		[cell setIsPlayingVideo:YES];
	} else {
		[cell setIsPlayingVideo:NO];
	}
    
    [cell setLastCell:(anIndexPath.row == [self tableView:aTableView numberOfRowsInSection:anIndexPath.section] - 2)];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
	if ([sectionInfo numberOfObjects] == [indexPath row]) {
        if (!isLoadingNewContent) {
            return 0;
        }
        return 170;
    }
    
    NMVideo *theVideo = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:[indexPath row] inSection:0]];

    if ([theVideo.duration intValue] <= kShortVideoLengthSeconds) {
        return kShortVideoCellWidth;
    } else if ([theVideo.duration intValue] <= kMediumVideoLengthSeconds) {
        return kMediumVideoCellWidth;
    } else {
        return kLongVideoCellWidth;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

#pragma mark - Fetched Results Controller

- (NSArray *)sortDescriptors 
{
    NSSortDescriptor *timestampDesc = [[NSSortDescriptor alloc] initWithKey:@"published_at" ascending:(NM_SORT_ORDER == NMSortOrderTypeOldestFirst)];
    NSArray *sortDescriptors = [NSArray arrayWithObject:timestampDesc];
    [timestampDesc release];

    return sortDescriptors;
}

- (NSFetchedResultsController *)fetchedResultsController 
{    
    if (fetchedResultsController_ != nil) {
        return fetchedResultsController_;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NMVideoEntityName inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
	[fetchRequest setReturnsObjectsAsFaults:NO];
	
	// Make sure the condition here - predicate and sort order is EXACTLY the same as in deleteVideoInChannel:afterVideo: in data controller!!!
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"channel == %@ AND nm_error < %@", channel, [NSNumber numberWithInteger:NMErrorDequeueVideo]]];
    [fetchRequest setFetchBatchSize:5];
    [fetchRequest setSortDescriptors:[self sortDescriptors]];
    
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [fetchRequest release];
    
    NSError *error = nil;
    if (![fetchedResultsController_ performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return fetchedResultsController_;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller 
{
    // Remember which video was highlighted (easier than keeping track of an index which may be moved around)
    if (highlightedVideo) {
        [highlightedVideo release];
        highlightedVideo = nil;
    }
    if (panelController.highlightedVideoIndex >= 0 && panelController.highlightedVideoIndex < [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects]) {
        highlightedVideo = [[fetchedResultsController_ objectAtIndexPath:[NSIndexPath indexPathForRow:panelController.highlightedVideoIndex inSection:0]] retain];
    }
    
    // Add to the offset as new cells are inserted to the left
    tableViewOffset = videoTableView.contentOffset;
    
    [videoTableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath 
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [videoTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            if (newIndexPath.row < 5 && reloadingFromRight) {
                tableViewOffset.y += [self tableView:videoTableView heightForRowAtIndexPath:newIndexPath];
            }
            break;
		case NSFetchedResultsChangeDelete:
            [videoTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeUpdate:
            [videoTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
		case NSFetchedResultsChangeMove:
			break;
		default:
			break;
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller 
{
    // Update the highlighted index
    if (highlightedVideo) {
        NSIndexPath *highlightedIndexPath = [fetchedResultsController_ indexPathForObject:highlightedVideo];
        if (highlightedIndexPath) {
            panelController.highlightedVideoIndex = highlightedIndexPath.row;
        }
        [highlightedVideo release];
        highlightedVideo = nil;
    }
    
    [videoTableView endUpdates];
}

- (void)updateChannelTableView:(NMVideo *)newVideo animated:(BOOL)shouldAnimate 
{
    if (newVideo && [newVideo channel] == channel) {
        // select / deselect cells
        [panelController didSelectNewVideoWithChannel:channel andVideoIndex:[[fetchedResultsController_ indexPathForObject:newVideo] row]];
        
        // scroll to the current video
        [videoTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[[fetchedResultsController_ indexPathForObject:newVideo] row] inSection:0] 
                              atScrollPosition:UITableViewScrollPositionMiddle 
                                      animated:shouldAnimate];
    }
}

- (void)loadingDidFinishAnimateCell:(BOOL)animateNewContentCell
{
    if (animateNewContentCell) {
        [self performSelector:@selector(resetAnimatingVariable) withObject:nil afterDelay:1.0];
    }
        
    isLoadingNewContent = NO;
    isAnimatingNewContentCell = animateNewContentCell;
    [videoTableView reloadData];

    if (reloadingFromRight) {
        tableViewOffset.y = MAX(0, MIN(tableViewOffset.y, videoTableView.contentSize.height - videoTableView.frame.size.width));
        [videoTableView setContentOffset:tableViewOffset animated:NO];
    }
    
    [self hidePullToRefreshView];
    reloadingFromLeft = NO;
    reloadingFromRight = NO;
}

#pragma mark - Notification handling

- (void)handleDidGetBeginPlayingVideoNotification:(NSNotification *)aNotification {
    NMVideo *newVideo = [[aNotification userInfo] objectForKey:@"video"];
    [self updateChannelTableView:newVideo animated:YES];
}

- (void)handleDidGetChannelVideoListNotification:(NSNotification *)aNotification {
	NSDictionary * info = [aNotification userInfo];
    if ( [[info objectForKey:@"channel"] isEqual:channel] ) {
		NSInteger numRec = [[info objectForKey:@"num_video_received"] integerValue];
		if ( numRec && [[info objectForKey:@"num_video_added"] integerValue] == 0 && numRec == [[info objectForKey:@"num_video_requested"] integerValue] ) {
			// the "if" condition should be interrupted as follow:
			// The server has returned full page of videos. But, no video is inserted. That means there may be more videos listed in Nowmov server.
			// poll the server again
			[[NMTaskQueueController sharedTaskQueueController] issueGetMoreVideoForChannel:channel];
		} else {
            [self loadingDidFinishAnimateCell:YES];
		}
    }
}

- (void)handleDidFailGetChannelVideoListNotification:(NSNotification *)aNotification {
	NMChannel * chnObj = [[aNotification userInfo] objectForKey:@"channel"];
    if (chnObj && [chnObj isEqual:channel] ) {
        [self loadingDidFinishAnimateCell:NO];       
    }
}

- (void)handleDidCancelGetChannelVideListNotification:(NSNotification *)aNotification {
	NMChannel * chnObj = [[aNotification userInfo] objectForKey:@"channel"];
    if (chnObj && [chnObj isEqual:channel] ) {
        [self loadingDidFinishAnimateCell:NO];              
    }
}

- (void)handleNewSessionNotification:(NSNotification *)aNotification {
	[[NMTaskQueueController sharedTaskQueueController] issueGetMoreVideoForChannel:channel];
}

- (void)handleSortOrderDidChangeNotification:(NSNotification *)aNotification {
    // Keep the same video highlighted once the sort order is reversed
    NMVideo *currentVideo = nil;
    if (panelController.highlightedChannel == channel) {
        currentVideo = [fetchedResultsController_ objectAtIndexPath:[NSIndexPath indexPathForRow:panelController.highlightedVideoIndex inSection:0]];
    }
    
    // Update the sort descriptors and reload the table
    [fetchedResultsController_.fetchRequest setSortDescriptors:[self sortDescriptors]];
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    if (currentVideo) {
        panelController.highlightedVideoIndex = [fetchedResultsController_ indexPathForObject:currentVideo].row;
        [videoTableView reloadData];
        [videoTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:panelController.highlightedVideoIndex inSection:0] 
                              atScrollPosition:UITableViewScrollPositionMiddle
                                      animated:YES];
    } else {
        [videoTableView reloadData];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    tableViewOffset = aScrollView.contentOffset;
    
    CGPoint offset = aScrollView.contentOffset;
    CGRect bounds = aScrollView.bounds;
    CGSize size = aScrollView.contentSize;
    UIEdgeInsets inset = aScrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
    float reload_distance = -kMediumVideoCellWidth-100;
    if(y > h + reload_distance && dragging) {
        if (!isLoadingNewContent && !isAnimatingNewContentCell) {
            isLoadingNewContent = YES;
            reloadingFromRight = YES;
            [videoTableView beginUpdates];
            [videoTableView endUpdates];
            
            NMTaskQueueController * schdlr = [NMTaskQueueController sharedTaskQueueController];
			[schdlr issueGetMoreVideoForChannel:channel];
        }
    }
    
    float leftY = aScrollView.contentOffset.y + aScrollView.contentInset.top;
    if (!reloadingFromLeft) {
        if (leftY < -kPullToRefreshDistance && dragging) {
            pullToRefreshView.loadingText.text = @"Release to refresh";
        } else {
            pullToRefreshView.loadingText.text = @"Pull to refresh";        
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    dragging = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)aScrollView willDecelerate:(BOOL)decelerate
{
    dragging = NO;
    if (isLoadingNewContent) return;

    // Pull to refresh from left
    float leftY = aScrollView.contentOffset.y + aScrollView.contentInset.top;
    
    if (leftY < -kPullToRefreshDistance) {
        isLoadingNewContent = YES;
        [[NMTaskQueueController sharedTaskQueueController] issueGetMoreVideoForChannel:channel];
        
        [pullToRefreshView.activityIndicator startAnimating];
        pullToRefreshView.loadingText.text = @"Loading videos...";
        reloadingFromLeft = YES;
        
        [UIView animateWithInteractiveDuration:0.2
                                    animations:^{
                                        aScrollView.contentInset = UIEdgeInsetsMake(kLoadingViewWidth, 0.0f, 0.0f, 0.0f);
                                    }];            
    }    
}

#pragma mark helpers

- (void)resetAnimatingVariable {
    isLoadingNewContent = NO;
    isAnimatingNewContentCell = NO;
}

@end