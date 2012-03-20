//
//  VideoRowController.h
//  ipad
//
//  Created by Bill So on 6/14/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "NMLibrary.h"
#import "NMStyleUtility.h"
#import "PanelVideoCell.h"

@class ChannelPanelController;
@class AGOrientedTableView;

@interface VideoRowController : NSObject <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, UIScrollViewDelegate> {
    BOOL isAnimatingNewContentCell;
    NMVideo *highlightedVideo;
}

@property (nonatomic, retain) AGOrientedTableView *videoTableView;
@property (nonatomic, assign) ChannelPanelController *panelController;
@property (nonatomic, retain) NMChannel *channel;
@property (nonatomic, assign) NSInteger indexInTable;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, assign) BOOL isLoadingNewContent;
@property (nonatomic, assign) IBOutlet PanelVideoCell *pullToRefreshView;
@property (nonatomic, assign) IBOutlet PanelVideoCell *loadingCell;

- (void)updateChannelTableView:(NMVideo *)newVideo animated:(BOOL)shouldAnimate;
- (void)playVideoForIndexPath:(NSIndexPath *)indexPath sender:(id)sender;
- (void)recycleCell:(PanelVideoCell *)cell;

@end
