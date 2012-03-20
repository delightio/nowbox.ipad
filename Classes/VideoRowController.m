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

@interface VideoRowController (PrivateMethods)
- (NSArray *)sortDescriptors;
- (void)positionPullToRefreshViews;
- (void)hidePullToRefreshViews;
@end

@implementation VideoRowController

@synthesize managedObjectContext = managedObjectContext_;
@synthesize fetchedResultsController = fetchedResultsController_;
@synthesize videoTableView;
@synthesize channel, panelController;
@synthesize indexInTable;
@synthesize isLoadingNewContent;
@synthesize leftPullToRefreshView;
@synthesize rightPullToRefreshView;

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
        
        [[NSBundle mainBundle] loadNibNamed:@"VideoPanelLoadMoreView" owner:self options:nil];
        leftPullToRefreshView.transform = CGAffineTransformMakeRotation(M_PI_2);
        rightPullToRefreshView.transform = CGAffineTransformMakeRotation(M_PI_2);
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
    [leftPullToRefreshView release];
    [rightPullToRefreshView release];
    
	[super dealloc];
}

- (void)setVideoTableView:(AGOrientedTableView *)aVideoTableView
{
    if (videoTableView != aVideoTableView) {
        [videoTableView release];
        videoTableView = [aVideoTableView retain];
    }

    [self positionPullToRefreshViews];
    [videoTableView insertSubview:leftPullToRefreshView atIndex:0];
    [videoTableView insertSubview:rightPullToRefreshView atIndex:0];
}

- (void)positionPullToRefreshViews
{
    leftPullToRefreshView.frame = CGRectMake(0, -kLoadingViewWidth, videoTableView.frame.size.height, kLoadingViewWidth);
    rightPullToRefreshView.frame = CGRectMake(0, MAX(videoTableView.frame.size.width, videoTableView.contentSize.height), videoTableView.frame.size.height, kLoadingViewWidth);
}

- (void)hidePullToRefreshViews
{
    [self positionPullToRefreshViews];
    [UIView animateWithInteractiveDuration:0.3
                                animations:^{
                                    videoTableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
                                }
                                completion:^(BOOL finished){
                                    [leftPullToRefreshView.activityIndicator stopAnimating];
                                    leftPullToRefreshView.loadingText.text = @"Pull to refresh";
                                    [rightPullToRefreshView.activityIndicator stopAnimating];
                                    rightPullToRefreshView.loadingText.text = @"";
                                }];            
}

#pragma mark - UITableViewDelegate and UITableViewDatasource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
	return [sectionInfo numberOfObjects];
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
    
    [cell setLastCell:(anIndexPath.row == [self tableView:aTableView numberOfRowsInSection:anIndexPath.section] - 1)];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
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
    
    [self positionPullToRefreshViews];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller 
{
    CGPoint contentOffset = videoTableView.contentOffset;
    [videoTableView endUpdates];
    videoTableView.contentOffset = contentOffset;
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
            isLoadingNewContent = NO;
			[videoTableView reloadData];
            [self hidePullToRefreshViews];
		}
    }
}

- (void)handleDidFailGetChannelVideoListNotification:(NSNotification *)aNotification {
	NMChannel * chnObj = [[aNotification userInfo] objectForKey:@"channel"];
    if (chnObj && [chnObj isEqual:channel] ) {
        isLoadingNewContent = NO;
        [videoTableView reloadData];
        [self hidePullToRefreshViews];        
    }
}

- (void)handleDidCancelGetChannelVideListNotification:(NSNotification *)aNotification {
	NMChannel * chnObj = [[aNotification userInfo] objectForKey:@"channel"];
    if (chnObj && [chnObj isEqual:channel] ) {
        isLoadingNewContent = NO;
        [videoTableView reloadData];
        [self hidePullToRefreshViews];        
    }
}

- (void)handleNewSessionNotification:(NSNotification *)aNotification {
	[[NMTaskQueueController sharedTaskQueueController] issueGetMoreVideoForChannel:channel];
}

- (void)handleSortOrderDidChangeNotification:(NSNotification *)aNotification {
    // Keep the same video highlighted once the sort order is reversed
    NMVideo *highlightedVideo = nil;
    if (panelController.highlightedChannel == channel) {
        highlightedVideo = [fetchedResultsController_ objectAtIndexPath:[NSIndexPath indexPathForRow:panelController.highlightedVideoIndex inSection:0]];
    }
    
    // Update the sort descriptors and reload the table
    [fetchedResultsController_.fetchRequest setSortDescriptors:[self sortDescriptors]];
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    if (highlightedVideo) {
        panelController.highlightedVideoIndex = [fetchedResultsController_ indexPathForObject:highlightedVideo].row;
        [videoTableView reloadData];
        [self positionPullToRefreshViews];        
        [videoTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:panelController.highlightedVideoIndex inSection:0] 
                              atScrollPosition:UITableViewScrollPositionMiddle
                                      animated:YES];
    } else {
        [videoTableView reloadData];
        [self positionPullToRefreshViews];        
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView 
{
    if (isLoadingNewContent) return;
    
    // Scroll to refresh from right
    float rightY = aScrollView.contentOffset.y + aScrollView.bounds.size.height - aScrollView.contentInset.bottom;
        
    if (rightY > aScrollView.contentSize.height + kLoadingViewWidth / 2) {
        isLoadingNewContent = YES;
        [[NMTaskQueueController sharedTaskQueueController] issueGetMoreVideoForChannel:channel];

        [rightPullToRefreshView.activityIndicator startAnimating];
        rightPullToRefreshView.loadingText.text = @"Loading videos...";
        [UIView animateWithInteractiveDuration:0.2
                                    animations:^{
                                        aScrollView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, kLoadingViewWidth, 0.0f);
                                    }];
    }    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)aScrollView willDecelerate:(BOOL)decelerate
{
    if (isLoadingNewContent) return;

    // Pull to refresh from left
    float leftY = aScrollView.contentOffset.y + aScrollView.contentInset.top;
    
    if (leftY < -kLoadingViewWidth / 2) {
        isLoadingNewContent = YES;
        [[NMTaskQueueController sharedTaskQueueController] issueGetMoreVideoForChannel:channel];
        
        [leftPullToRefreshView.activityIndicator startAnimating];
        leftPullToRefreshView.loadingText.text = @"Loading videos...";
        [UIView animateWithInteractiveDuration:0.2
                                    animations:^{
                                        aScrollView.contentInset = UIEdgeInsetsMake(kLoadingViewWidth, 0.0f, 0.0f, 0.0f);
                                    }];            
    }    
}

@end