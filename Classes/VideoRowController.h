//
//  VideoRowController.h
//  ipad
//
//  Created by Bill So on 6/14/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "NMLibrary.h"
#import "NMStyleUtility.h"


@class ChannelPanelController;
@class AGOrientedTableView;

@interface VideoRowController : NSObject <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, UIScrollViewDelegate> {
	AGOrientedTableView * videoTableView;
    NSFetchedResultsController *fetchedResultsController_;
    NSManagedObjectContext *managedObjectContext_;
	NMChannel * channel;
	NSInteger indexInTable;
	NMStyleUtility * styleUtility;
	ChannelPanelController * panelController;
    BOOL isLoadingNewContent;
    CGPoint tempOffset;
}

@property (nonatomic, assign) AGOrientedTableView * videoTableView;
@property (nonatomic, assign) ChannelPanelController * panelController;
@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, assign) NSInteger indexInTable;
@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController * fetchedResultsController;
@property (nonatomic, assign) BOOL isLoadingNewContent;

- (id)init;
-(void)updateChannelTableView:(NMVideo *)newVideo;
- (void)handleDidGetBeginPlayingVideoNotification:(NSNotification *)aNotification;
-(void)playVideoForIndexPath:(NSIndexPath *)indexPath;
@end
