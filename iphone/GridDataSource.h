//
//  GridDataSource.h
//  ipad
//
//  Created by Chris Haugli on 2/7/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PagingGridView.h"
#import "PagingGridViewCell.h"
#import "NMTaskQueueController.h"
#import "NMDataController.h"

@interface GridDataSource : NSObject <PagingGridViewDataSource, NSFetchedResultsControllerDelegate>

@property (nonatomic, retain) PagingGridView *gridView;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, assign) BOOL updatesEnabled;
@property (nonatomic, assign) id<PagingGridViewCellDelegate> gridViewCellDelegate;

- (id)initWithGridView:(PagingGridView *)aGridView managedObjectContext:(NSManagedObjectContext *)aManagedObjectContext gridViewCellDelegate:(id<PagingGridViewCellDelegate>)aPagingGridViewCellDelegate;
- (GridDataSource *)nextDataSourceForIndex:(NSUInteger)index;
- (void)moveObjectAtIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex;

@end
