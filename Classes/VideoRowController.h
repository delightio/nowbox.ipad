//
//  VideoRowController.h
//  ipad
//
//  Created by Bill So on 6/14/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "HorizontalTableView.h"
#import "NMLibrary.h"
#import "NMStyleUtility.h"


@class ChannelPanelController;

@interface VideoRowController : NSObject <HorizontalTableViewDelegate, NSFetchedResultsControllerDelegate> {
	HorizontalTableView * videoTableView;
    NSFetchedResultsController *fetchedResultsController_;
    NSManagedObjectContext *managedObjectContext_;
	NMChannel * channel;
	NMStyleUtility * styleUtility;
	ChannelPanelController * panelController;
}

@property (nonatomic, assign) HorizontalTableView * videoTableView;
@property (nonatomic, assign) ChannelPanelController * panelController;
@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController * fetchedResultsController;

//- (id)initWithFrame:(CGRect)aframe channel:(NMChannel *)chnObj panelDelegate:(id<HorizontalTableViewParentPanelDelegate>)pDelegate;
- (id)init;

@end
