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


@interface VideoRowController : NSObject <HorizontalTableViewDelegate, NSFetchedResultsControllerDelegate> {
	HorizontalTableView * videoTableView;
    NSFetchedResultsController *fetchedResultsController_;
    NSManagedObjectContext *managedObjectContext_;
	NMChannel * channel;
	NMStyleUtility * styleUtility;
}

@property (nonatomic, readonly) HorizontalTableView * videoTableView;
@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController * fetchedResultsController;

- (id)initWithFrame:(CGRect)aframe channel:(NMChannel *)chnObj;


@end
