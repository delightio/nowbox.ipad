//
//  FacebookGridDataSource.m
//  ipad
//
//  Created by Chris Haugli on 2/23/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "FacebookGridDataSource.h"

@interface FacebookGridDataSource (PrivateMethods)
- (void)configureCell:(PagingGridViewCell *)cell forChannel:(NMChannel *)channel isUpdate:(BOOL)isUpdate;
@end

@implementation FacebookGridDataSource

@synthesize fetchedResultsController;

- (void)dealloc
{    
    [fetchedResultsController release];
    
    [super dealloc];
}

- (GridDataSource *)nextDataSourceForIndex:(NSUInteger)index
{
    return nil;
}

- (id)objectAtIndex:(NSUInteger)index
{
    return [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
}

- (void)moveObjectAtIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex
{
    NMSubscription *displacedSubscription = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:newIndex inSection:0]];
    NSNumber *newSortOrder = displacedSubscription.nm_sort_order;
    
    if (newIndex < oldIndex) {
        for (NSInteger i = newIndex; i < oldIndex; i++) {
            NMSubscription *thisSubscription = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            NMSubscription *nextSubscription = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:i+1 inSection:0]];            
            thisSubscription.nm_sort_order = nextSubscription.nm_sort_order;
        }
    } else {
        for (NSInteger i = newIndex; i > oldIndex; i--) {
            NMSubscription *thisSubscription = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            NMSubscription *nextSubscription = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:i-1 inSection:0]];
            thisSubscription.nm_sort_order = nextSubscription.nm_sort_order;
        }        
    }
    
    NMSubscription *subscriptionToMove = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:oldIndex inSection:0]];
    subscriptionToMove.nm_sort_order = newSortOrder;
    
    [self.managedObjectContext save:NULL];
}

- (void)deleteObjectAtIndex:(NSUInteger)index
{
    NMChannel *channelToDelete = [[self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]] channel];
    [[NMTaskQueueController sharedTaskQueueController] issueSubscribe:NO channel:channelToDelete];
}

- (void)configureCell:(PagingGridViewCell *)cell forChannel:(NMChannel *)channel isUpdate:(BOOL)isUpdate
{
    cell.label.text = channel.title;
    
    NMDataController *dataController = [NMTaskQueueController sharedTaskQueueController].dataController;
    NMVideo *latestVideo = [dataController latestVideoForChannel:channel];
    
    if (latestVideo) {
        [cell.image setImageForVideoThumbnail:latestVideo];
        [cell.activityIndicator stopAnimating];
    } else {
        [cell.image setImageForChannel:channel];
        
        // Don't get more videos if the cell configuration is due to an update - will loop endlessly if channel has no videos
        if (!isUpdate) {
            [[NMTaskQueueController sharedTaskQueueController] issueGetMoreVideoForChannel:channel];
            [cell.activityIndicator startAnimating];            
        } else {
            [cell.activityIndicator stopAnimating];
        }
    }
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController 
{
    if (!self.managedObjectContext) {
        return nil;
    }
    
    if (!fetchedResultsController) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setReturnsObjectsAsFaults:NO];
        [fetchRequest setEntity:[NSEntityDescription entityForName:NMSubscriptionEntityName inManagedObjectContext:self.managedObjectContext]];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"nm_hidden == NO AND channel != nil AND channel.type == %@", [NSNumber numberWithInteger:NMChannelUserFacebookType]]];
        [fetchRequest setFetchBatchSize:20];
                        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:YES];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        [sortDescriptor release];
        
        fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        fetchedResultsController.delegate = self;
        [fetchRequest release];
        
        NSError *error = nil;
        if (![fetchedResultsController performFetch:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    
    return fetchedResultsController;
}    

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath 
{    
    if (type == NSFetchedResultsChangeUpdate) {
        // Don't replace the cell, it messes up our drags. Just change the properties of the old one.
        NMChannel *channel = [anObject channel];
        PagingGridViewCell *cell = [self.gridView cellForIndex:indexPath.row];
        [self configureCell:cell forChannel:channel isUpdate:YES];
    } else {
        [super controller:controller didChangeObject:anObject atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];
    }
}

#pragma mark - PagingGridViewDataSource

- (NSUInteger)gridViewNumberOfItems:(PagingGridView *)aGridView
{
    return [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects];
}

- (PagingGridViewCell *)gridView:(PagingGridView *)aGridView cellForIndex:(NSUInteger)index
{
    PagingGridViewCell *view = (PagingGridViewCell *) [aGridView dequeueReusableCell];
    
    if (!view) {
        view = [[[PagingGridViewCell alloc] init] autorelease];
    }
    
    NMChannel *channel = [[self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]] channel];
    [self configureCell:view forChannel:channel isUpdate:NO];
    
    return view;
}

- (BOOL)gridView:(PagingGridView *)gridView canDeleteItemAtIndex:(NSUInteger)index
{
    return NO;
}

@end
