//
//  GridDataSource.h
//  ipad
//
//  Created by Chris Haugli on 2/7/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PagingGridView.h"
#import "NMTaskQueueController.h"
#import "NMDataController.h"

@interface GridDataSource : NSObject <PagingGridViewDataSource, NSFetchedResultsControllerDelegate>

@property (nonatomic, retain) PagingGridView *gridView;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, assign) BOOL ignoresMoveChanges;

- (id)initWithGridView:(PagingGridView *)aGridView managedObjectContext:(NSManagedObjectContext *)aManagedObjectContext;
- (GridDataSource *)nextDataSourceForIndex:(NSUInteger)index;
- (id)objectAtIndex:(NSUInteger)index;
- (void)moveObjectAtIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex;
- (void)deleteObjectAtIndex:(NSUInteger)index;

@end
