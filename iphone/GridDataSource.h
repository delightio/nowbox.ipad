//
//  GridDataSource.h
//  ipad
//
//  Created by Chris Haugli on 2/7/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PagingGridView.h"
#import "ThumbnailView.h"
#import "NMTaskQueueController.h"
#import "NMDataController.h"

@interface GridDataSource : NSObject <PagingGridViewDataSource, NSFetchedResultsControllerDelegate>

@property (nonatomic, retain) PagingGridView *gridView;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, assign) id<ThumbnailViewDelegate> thumbnailViewDelegate;

- (id)initWithGridView:(PagingGridView *)aGridView managedObjectContext:(NSManagedObjectContext *)aManagedObjectContext thumbnailViewDelegate:(id<ThumbnailViewDelegate>)aThumbnailViewDelegate;
- (GridDataSource *)nextDataSourceForIndex:(NSUInteger)index;
- (void)moveObjectAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

@end
