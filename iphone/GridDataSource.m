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
@synthesize ignoresMoveChanges;
@synthesize managedObjectContext;

- (id)initWithGridView:(PagingGridView *)aGridView managedObjectContext:(NSManagedObjectContext *)aManagedObjectContext
{
    self = [super init];
    if (self) {
        self.gridView = aGridView;
        self.managedObjectContext = aManagedObjectContext;
    }
    return self;
}

- (void)dealloc
{
    [gridView release];
    [managedObjectContext release];
    
    [super dealloc];
}

- (id)objectAtIndex:(NSUInteger)index
{
    // To be implemented by subclasses
    return nil;
}

- (NMChannel *)selectObjectAtIndex:(NSUInteger)index
{
    // To be implemented by subclasses
    return nil;
}

- (void)moveObjectAtIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex
{
    // To be implemented by subclasses
}

- (void)deleteObjectAtIndex:(NSUInteger)index
{
    // To be implemented by subclasses    
}

- (NSUInteger)mappedFetchedResultsIndexForGridIndex:(NSUInteger)gridIndex
{
    // The indexes in our grid and fetched results may not correspond. This method lets us define a mapping between the two.
    return gridIndex;
}

- (NSUInteger)mappedGridIndexForFetchedResultsIndex:(NSUInteger)fetchedResultsIndex
{
    // The indexes in our grid and fetched results may not correspond. This method lets us define a mapping between the two.
    return fetchedResultsIndex;
}

- (void)refreshAllObjects
{
    // To be implemented by subclasses
}

#pragma mark - PagingGridViewDataSource

- (NSUInteger)gridViewNumberOfItems:(PagingGridView *)aGridView
{
    // To be implemented by subclasses
    [self doesNotRecognizeSelector:_cmd];
    return 0;
}

- (PagingGridViewCell *)gridView:(PagingGridView *)aGridView cellForIndex:(NSUInteger)index
{
    // To be implemented by subclasses
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [gridView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath 
{    
    if (ignoresMoveChanges && type == NSFetchedResultsChangeMove) return;
    
    NSUInteger index = [self mappedGridIndexForFetchedResultsIndex:indexPath.row];
    NSUInteger newIndex = [self mappedGridIndexForFetchedResultsIndex:newIndexPath.row];
    
    switch(type) {
        case NSFetchedResultsChangeInsert: 
            [gridView insertItemAtIndex:newIndex];
            break;
        case NSFetchedResultsChangeDelete:
            [gridView deleteItemAtIndex:index animated:YES];
            break;
        case NSFetchedResultsChangeUpdate:
            [gridView updateItemAtIndex:index];
            break;
        case NSFetchedResultsChangeMove:
            [gridView deleteItemAtIndex:index animated:YES];
            [gridView insertItemAtIndex:newIndex];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller 
{
    [gridView endUpdates];
}

@end
