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

@implementation VideoRowController
@synthesize managedObjectContext=managedObjectContext_;
@synthesize fetchedResultsController=fetchedResultsController_;
@synthesize youtubeImportPredicate = _youtubeImportPredicate;
@synthesize videoTableView;
@synthesize channel, panelController;
@synthesize indexInTable;
@synthesize isLoadingNewContent;
@synthesize loadingCell;


#define kShortVideoLengthSeconds   120
#define kMediumVideoLengthSeconds   600
#define kShortVideoCellWidth    202.0f
#define kMediumVideoCellWidth    404.0f
#define kLongVideoCellWidth    606.0f



- (id)init {
	self = [super init];
	styleUtility = [NMStyleUtility sharedStyleUtility];
    
	self.managedObjectContext = [NMTaskQueueController sharedTaskQueueController].dataController.managedObjectContext;
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleDidGetBeginPlayingVideoNotification:) name:NMWillBeginPlayingVideoNotification object:nil];
	[nc addObserver:self selector:@selector(handleWillGetChannelVideListNotification:) name:NMWillGetChannelVideListNotification object:nil];
	[nc addObserver:self selector:@selector(handleDidGetChannelVideoListNotification:) name:NMDidGetChannelVideoListNotification object:nil];
	[nc addObserver:self selector:@selector(handleDidFailGetChannelVideoListNotification:) name:NMDidFailGetChannelVideoListNotification object:nil];
	[nc addObserver:self selector:@selector(handleDidCancelGetChannelVideListNotification:) name:NMDidCancelGetChannelVideListNotification object:nil];
	[nc addObserver:self selector:@selector(handleNewSessionNotification:) name:NMBeginNewSessionNotification object:nil];
	return self;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[channel release];
	[fetchedResultsController_ release];
	[managedObjectContext_ release];

    for (PanelVideoCell *cell in videoTableView.visibleCells) {
        // Otherwise we get a bad access when the cell tries to recycle itself to the row delegate (this object)
        [cell setVideoRowDelegate:nil];
    }
    [videoTableView release];
	[_youtubeImportPredicate release];
    
	[super dealloc];
}

#pragma mark -
#pragma mark UITableViewDelegate and UITableViewDatasource methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
	return [sectionInfo numberOfObjects]+1;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

}

-(void)playVideoForIndexPath:(NSIndexPath *)indexPath sender:(id)sender {
	PanelVideoCell * vdoCell = (PanelVideoCell *)[videoTableView cellForRowAtIndexPath:indexPath];
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
                                                                       theVideo.video.title, AnalyticsPropertyVideoName, 
                                                                       theVideo.video.nm_id, AnalyticsPropertyVideoId,
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
        
        if ([channel.populated_at integerValue] > 0 || [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects] > 0) {
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
//    PanelVideoCell *cell = (PanelVideoCell *)[aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    PanelVideoCell *cell = [[[panelController.recycledVideoCells anyObject] retain] autorelease];
    if (cell) {
        [panelController.recycledVideoCells removeObject:cell];
    } else {
        cell = [[[PanelVideoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell
    NMVideo * vdo = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:[anIndexPath row] inSection:0]];
	NMConcreteVideo * theVideo = vdo.video;
    NMDataController *dataCtrl = [NMTaskQueueController sharedTaskQueueController].dataController;
    
    BOOL isVideoPlayable = ([theVideo.nm_error integerValue] == 0) && (theVideo.nm_playback_status >= 0);
    BOOL isVideoFavorited = ([theVideo.nm_favorite boolValue] && ![vdo.channel isEqual:[dataCtrl favoriteVideoChannel]]);
    BOOL isVideoQueued = ([theVideo.nm_watch_later boolValue] && ![vdo.channel isEqual:[dataCtrl myQueueChannel]]);

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
    
    if ([anIndexPath row] > 0) {
        NMVideo *prevVideo = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:[anIndexPath row]-1 inSection:0]];
        [cell setSessionStartCell:([vdo.nm_session_id integerValue] != [prevVideo.nm_session_id integerValue])];
    } else {
        [cell setSessionStartCell:NO];
    }

    if ( panelController.highlightedChannel == channel && [anIndexPath row] == panelController.highlightedVideoIndex ) {
		[cell setIsPlayingVideo:YES];
	} else {
		[cell setIsPlayingVideo:NO];
	}
    
    [cell setLastCell:(anIndexPath.row == [self tableView:aTableView numberOfRowsInSection:anIndexPath.section] - 2)];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
	if ([sectionInfo numberOfObjects] == [indexPath row]) {
        if (!isLoadingNewContent) {
            return 0;
        }
        return 170;
    }
    

    NMVideo * theVideo = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:[indexPath row] inSection:0]];

    if ([theVideo.video.duration integerValue] <= kShortVideoLengthSeconds) {
        return kShortVideoCellWidth;
    }
    else if ([theVideo.video.duration integerValue] <= kMediumVideoLengthSeconds) {
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
- (NSPredicate *)youtubeImportPredicate {
	if ( _youtubeImportPredicate == nil ) {
		_youtubeImportPredicate = [[NSPredicate predicateWithFormat:@"channel == $CHANNEL"] retain];
	}
	return _youtubeImportPredicate;
}

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
	[fetchRequest setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"video"]];
	
	// Make sure the condition here - predicate and sort order is EXACTLY the same as in deleteVideoInChannel:afterVideo: in data controller!!!
	// set predicate
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"channel == %@ AND video.nm_error < %@", channel, [NSNumber numberWithInteger:NMErrorDequeueVideo]]];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:5];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:YES];
	NSSortDescriptor * timestampDesc = [[NSSortDescriptor alloc] initWithKey:@"nm_session_id" ascending:YES];
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
    [videoTableView beginUpdates];
    tempOffset = [videoTableView contentOffset];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
//	static NSUInteger theCount = 0;
    
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [videoTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
		case NSFetchedResultsChangeDelete:
		{
            [videoTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationFade];
			break;
		}
		case NSFetchedResultsChangeUpdate:
        {
            [videoTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        }
		case NSFetchedResultsChangeMove:
			break;
			
		default:
		{
			break;
		}
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    //[videoTableView scrollRectToVisible:CGRectMake(tempOffset.x, tempOffset.y, 1, 1) animated:NO];
    [videoTableView endUpdates];
}

-(void)updateChannelTableView:(NMVideo *)newVideo animated:(BOOL)shouldAnimate {
    if (newVideo) {
        if ([newVideo channel] == channel) {
            // select / deselect cells
            [panelController didSelectNewVideoWithChannel:channel andVideoIndex:[[fetchedResultsController_ indexPathForObject:newVideo] row]];
            
            // scroll to the current video
            [videoTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[[fetchedResultsController_ indexPathForObject:newVideo] row] inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:shouldAnimate];
        }
        else {
            // let other channels deal with their own notifications: do nothing!
        }
    }
}


#pragma mark Notification handling
- (void)handleDidGetBeginPlayingVideoNotification:(NSNotification *)aNotification {
    NMVideo *newVideo = [[aNotification userInfo] objectForKey:@"video"];
    [self updateChannelTableView:newVideo animated:YES];
}

- (void)handleWillGetChannelVideListNotification:(NSNotification *)aNotification {
    // BOOL set in scroll action already
    //    isLoadingNewContent = YES;
    if ([[aNotification userInfo] objectForKey:@"channel"] == channel) {
//        NSLog(@"handleWillGetChannelVideListNotification");
    }
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
//            if ([[info objectForKey:@"num_video_added"] integerValue]==0) {
//            }
//			NSLog(@"should hide \"loading label\": %@", channel.title);
            [self performSelector:@selector(resetAnimatingVariable) withObject:nil afterDelay:1.0];
            isLoadingNewContent = NO;
            isAnimatingNewContentCell = YES;
			[videoTableView reloadData];
            [videoTableView beginUpdates];
            [videoTableView endUpdates];
		}
    }
}

- (void)handleDidFailGetChannelVideoListNotification:(NSNotification *)aNotification {
	NMChannel * chnObj = [[aNotification userInfo] objectForKey:@"channel"];
    if (chnObj && [chnObj isEqual:channel] ) {
//        NSLog(@"handleDidFailGetChannelVideoListNotification");
        isLoadingNewContent = NO;
        isAnimatingNewContentCell = NO;
        [videoTableView reloadData];
    }
}

- (void)handleDidCancelGetChannelVideListNotification:(NSNotification *)aNotification {
	NMChannel * chnObj = [[aNotification userInfo] objectForKey:@"channel"];
    if (chnObj && [chnObj isEqual:channel] ) {
//        NSLog(@"handleDidCancelGetChannelVideListNotification");
        isLoadingNewContent = NO;
        isAnimatingNewContentCell = NO;
        [videoTableView reloadData];
    }
}

- (void)handleNewSessionNotification:(NSNotification *)aNotification {
	[[NMTaskQueueController sharedTaskQueueController] issueGetMoreVideoForChannel:channel];
}

#pragma mark trigger load new
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
//            id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
//            NSLog(@"Load new videos y:%f, h:%f, r:%f",y,h,reload_distance);

			NMChannelType chnType = [channel.type integerValue];
			if ( chnType != NMChannelUserFacebookType && chnType != NMChannelUserTwitterType ) {
				isLoadingNewContent = YES;
				[videoTableView beginUpdates];
				[videoTableView endUpdates];
				[[NMTaskQueueController sharedTaskQueueController] issueGetMoreVideoForChannel:channel];
			}
        }
    }
}

#pragma mark helpers
- (void)resetAnimatingVariable {
    isLoadingNewContent = NO;
    isAnimatingNewContentCell = NO;
}

@end