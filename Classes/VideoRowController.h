//
//  VideoRowController.h
//  ipad
//
//  Created by Bill So on 6/14/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EasyTableView.h"


@interface VideoRowController : NSObject <EasyTableViewDelegate> {
    EasyTableView * videoTableView;
    NSFetchedResultsController *fetchedResultsController_;
    NSManagedObjectContext *managedObjectContext_;
}

@property (nonatomic, readonly) EasyTableView * videoTableView;
@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController * fetchedResultsController;

- (id)initWithFrame:(CGRect)aframe;


@end
