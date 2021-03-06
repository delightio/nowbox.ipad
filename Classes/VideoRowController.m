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
- (void)issueGetOlderVideos;
- (void)issueGetNewerVideos;
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
        [nc addObserver:self selector:@selector(handleDidGetOlderVideosNotification:) name:NMDidGetOlderVideoForChannelNotification object:nil];
        [nc addObserver:self selector:@selector(handleDidGetOlderVideosNotification:) name:NMDidFailGetOlderVideoForChannelNotification object:nil];
        [nc addObserver:self selector:@selector(handleDidGetOlderVideosNotification:) name:NMDidCancelGetOlderVideoForChannelNotification object:nil];
        [nc addObserver:self selector:@selector(handleDidGetNewerVideosNotification:) name:NMDidGetNewVideoForChannelNotification object:nil];
        [nc addObserver:self selector:@selector(handleDidGetNewerVideosNotification:) name:NMDidFailGetNewVideoForChannelNotification object:nil];
        [nc addObserver:self selector:@selector(handleDidGetNewerVideosNotification:) name:NMDidCancelGetNewVideoForChannelNotification object:nil];
//        [nc addObserver:self selector:@selector(handleNewSessionNotification:) name:NMBeginNewSessionNotification object:nil]; the backend should manage getting new videos on new session
        [nc addObserver:self selector:@selector(handleSortOrderDidChangeNotification:) name:NMSortOrderDidChangeNotification object:nil];
        
        [[NSBundle mainBundle] loadNibNamed:@"VideoPanelPullToRefreshView" owner:self options:nil];
        pullToRefreshView.transform = CGAffineTransformMakeRotation(M_PI_2);
        pullToRefreshView.highlightOnTouch = NO;
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

- (void)issueGetOlderVideos
{
    NSUInteger numberOfVideos = [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects];
    if (numberOfVideos > 0) {
        NSUInteger lastVideoIndex = (NM_SORT_ORDER == NMSortOrderTypeOldestFirst ? 0 : numberOfVideos - 1);
        NMVideo *lastVideo = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:lastVideoIndex inSection:0]];
        [[NMTaskQueueController sharedTaskQueueController] issueGetOlderVideoForChannel:channel after:lastVideo.nm_id];
    } else {
        [[NMTaskQueueController sharedTaskQueueController] issueGetMoreVideoForChannel:channel];
    }
}

- (void)issueGetNewerVideos
{
    NSUInteger numberOfVideos = [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects];
    if (numberOfVideos > 0) {
        NSUInteger firstVideoIndex = (NM_SORT_ORDER == NMSortOrderTypeNewestFirst ? 0 : numberOfVideos - 1);
        NMVideo *firstVideo = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:firstVideoIndex inSection:0]];
        [[NMTaskQueueController sharedTaskQueueController] issueGetNewerVideoForChannel:channel before:firstVideo.nm_id];
    } else {
        [[NMTaskQueueController sharedTaskQueueController] issueGetMoreVideoForChannel:channel];
    }
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
    NMVideo * theVideo = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:[indexPath row] inSection:0]];
    [panelController didSelectNewVideo:theVideo withChannel:channel];
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
            cell.highlightOnTouch = NO;
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

    if ( panelController.highlightedChannel == channel && theVideo == panelController.highlightedVideo ) {
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
    [videoTableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath 
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [videoTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
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
    [videoTableView endUpdates];
}

- (void)updateChannelTableView:(NMVideo *)newVideo animated:(BOOL)shouldAnimate 
{
    if (newVideo && [newVideo channel] == channel) {
        // select / deselect cells
        [panelController didSelectNewVideo:newVideo withChannel:channel];
        
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
    
    [self hidePullToRefreshView];
    reloadingFromLeft = NO;
}

#pragma mark - Notification handling

- (void)handleDidGetBeginPlayingVideoNotification:(NSNotification *)aNotification {
    NMVideo *newVideo = [[aNotification userInfo] objectForKey:@"video"];
    [self updateChannelTableView:newVideo animated:YES];
}

- (void)handleDidGetChannelVideoListNotification:(NSNotification *)aNotification {
    if ([[[aNotification userInfo] objectForKey:@"channel"] isEqual:channel]) {
        [self loadingDidFinishAnimateCell:YES];        
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

- (void)handleDidGetOlderVideosNotification:(NSNotification *)notification
{
    if ([[[notification userInfo] objectForKey:@"channel"] isEqual:channel]) {
        [self loadingDidFinishAnimateCell:YES];        
    }
}

- (void)handleDidGetNewerVideosNotification:(NSNotification *)notification 
{
    if ([[[notification userInfo] objectForKey:@"channel"] isEqual:channel]) {
        [self loadingDidFinishAnimateCell:YES];     
    }    
}

//- (void)handleNewSessionNotification:(NSNotification *)aNotification {
//	[[NMTaskQueueController sharedTaskQueueController] issueGetMoreVideoForChannel:channel];
//}

- (void)handleSortOrderDidChangeNotification:(NSNotification *)aNotification {
    // Update the sort descriptors and reload the table
    [fetchedResultsController_.fetchRequest setSortDescriptors:[self sortDescriptors]];
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    [videoTableView reloadData];
    if (panelController.highlightedChannel == channel) {
        NSIndexPath *indexPathForCurrentVideo = [fetchedResultsController_ indexPathForObject:panelController.highlightedVideo];
        if (indexPathForCurrentVideo) {
            [videoTableView scrollToRowAtIndexPath:indexPathForCurrentVideo 
                                  atScrollPosition:UITableViewScrollPositionMiddle
                                          animated:YES];
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {    
    CGPoint offset = aScrollView.contentOffset;
    CGRect bounds = aScrollView.bounds;
    CGSize size = aScrollView.contentSize;
    UIEdgeInsets inset = aScrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
    float reload_distance = -kMediumVideoCellWidth-100;
    if(y > h + reload_distance) {
        if (!isLoadingNewContent && !isAnimatingNewContentCell) {
            isLoadingNewContent = YES;
            [videoTableView beginUpdates];
            [videoTableView endUpdates];
            
            if (NM_SORT_ORDER == NMSortOrderTypeNewestFirst) {
                [self issueGetOlderVideos];
            } else {
                [self issueGetNewerVideos];
            }
        }
    }
    
    float leftY = aScrollView.contentOffset.y + aScrollView.contentInset.top;
    if (!reloadingFromLeft && dragging) {
        if (leftY < -kPullToRefreshDistance) {
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
        
        if (NM_SORT_ORDER == NMSortOrderTypeNewestFirst) {
            [self issueGetNewerVideos];
        } else {
            [self issueGetOlderVideos];
        }
        
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