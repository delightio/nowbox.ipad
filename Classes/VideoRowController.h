//
//  VideoRowController.h
//  ipad
//
//  Created by Bill So on 6/14/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "EasyTableView.h"


@class NMChannel;

@interface VideoRowController : NSObject <EasyTableViewDelegate, NSFetchedResultsControllerDelegate> {
    EasyTableView * videoTableView;
    NSFetchedResultsController *fetchedResultsController_;
    NSManagedObjectContext *managedObjectContext_;
	NMChannel * channel;
}

@property (nonatomic, readonly) EasyTableView * videoTableView;
@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController * fetchedResultsController;

- (id)initWithFrame:(CGRect)aframe channel:(NMChannel *)chnObj;


@end
