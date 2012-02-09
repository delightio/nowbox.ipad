//
//  GridDataSource.m
//  ipad
//
//  Created by Chris Haugli on 2/7/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "GridDataSource.h"

@implementation GridDataSource

@synthesize gridView;
@synthesize managedObjectContext;
@synthesize thumbnailViewDelegate;

- (id)initWithGridView:(PagingGridView *)aGridView managedObjectContext:(NSManagedObjectContext *)aManagedObjectContext thumbnailViewDelegate:(id<ThumbnailViewDelegate>)aThumbnailViewDelegate
{
    self = [super init];
    if (self) {
        self.gridView = aGridView;
        self.managedObjectContext = aManagedObjectContext;
        self.thumbnailViewDelegate = aThumbnailViewDelegate;
    }
    return self;
}

- (void)dealloc
{
    [gridView release];
    [managedObjectContext release];
    
    [super dealloc];
}

- (GridDataSource *)nextDataSourceForIndex:(NSUInteger)index
{
    // To be overriden by subclasses
    return nil;
}

- (void)moveObjectAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    // To be overriden by subclasses
}

#pragma mark - PagingGridViewDataSource

- (NSUInteger)gridViewNumberOfItems:(PagingGridView *)aGridView
{
    // To be overriden by subclasses
    [self doesNotRecognizeSelector:_cmd];
    return 0;
}

- (UIView *)gridView:(PagingGridView *)aGridView viewForIndex:(NSUInteger)index
{
    // To be overriden by subclasses
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
//    [gridView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath 
{    
//    switch(type) {
//        case NSFetchedResultsChangeInsert: 
//            [gridView insertItemAtIndex:newIndexPath.row];
//            break;
//        case NSFetchedResultsChangeDelete:
//            [gridView deleteItemAtIndex:indexPath.row];
//            break;
//        case NSFetchedResultsChangeUpdate:
//            [gridView updateItemAtIndex:indexPath.row];
//            break;
//        case NSFetchedResultsChangeMove:
//            [gridView deleteItemAtIndex:indexPath.row];
//            [gridView insertItemAtIndex:newIndexPath.row];
//            break;
//    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller 
{
//    [gridView endUpdates];
    [gridView reloadData];
}

@end
