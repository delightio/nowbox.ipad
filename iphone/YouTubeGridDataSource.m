//
//  YouTubeGridDataSource.m
//  ipad
//
//  Created by Chris Haugli on 2/7/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "YouTubeGridDataSource.h"

@implementation YouTubeGridDataSource

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
    NMChannel *displacedChannel = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:newIndex inSection:0]];
    NSNumber *newSortOrder = displacedChannel.subscription.nm_sort_order;
    
    if (newIndex < oldIndex) {
        for (NSInteger i = newIndex; i < oldIndex; i++) {
            NMChannel *thisChannel = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            NMChannel *nextChannel = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:i+1 inSection:0]];            
            thisChannel.subscription.nm_sort_order = nextChannel.subscription.nm_sort_order;
        }
    } else {
        for (NSInteger i = newIndex; i > oldIndex; i--) {
            NMChannel *thisChannel = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            NMChannel *nextChannel = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:i-1 inSection:0]];
            thisChannel.subscription.nm_sort_order = nextChannel.subscription.nm_sort_order;
        }        
    }
    
    NMChannel *channelToMove = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:oldIndex inSection:0]];
    channelToMove.subscription.nm_sort_order = newSortOrder;

    [self.managedObjectContext save:NULL];
    
    // Refresh channels to update sort order
    NSError *error = nil;
    if (![fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (void)deleteObjectAtIndex:(NSUInteger)index
{
    NMChannel *channelToDelete = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    [[NMTaskQueueController sharedTaskQueueController] issueSubscribe:NO channel:channelToDelete];
}

- (void)configureCell:(PagingGridViewCell *)cell forChannel:(NMChannel *)channel
{
    cell.label.text = channel.title;
    
    NMDataController *dataController = [NMTaskQueueController sharedTaskQueueController].dataController;
    NMVideo *latestVideo = [dataController latestVideoForChannel:channel];
    
    if (latestVideo) {
        [cell.image setImageForVideoThumbnail:latestVideo];
        [cell.activityIndicator stopAnimating];
    } else {
        [cell.image setImageForChannel:channel];
        [cell.activityIndicator startAnimating];
        [[NMTaskQueueController sharedTaskQueueController] issueGetMoreVideoForChannel:channel];
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
        [fetchRequest setEntity:[NSEntityDescription entityForName:NMChannelEntityName inManagedObjectContext:self.managedObjectContext]];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"subscription != nil AND subscription.nm_hidden == NO AND (type == %@ OR type == %@)", [NSNumber numberWithInteger:NMChannelYouTubeType], [NSNumber numberWithInteger:NMChannelRecommendedType]]];
        [fetchRequest setFetchBatchSize:20];
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"subscription.nm_sort_order" ascending:YES];
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
        NMChannel *channel = (NMChannel *)anObject;
        PagingGridViewCell *cell = [self.gridView cellForIndex:indexPath.row];
        [self configureCell:cell forChannel:channel];
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

    NMChannel *channel = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    [self configureCell:view forChannel:channel];
    
    return view;
}

- (BOOL)gridView:(PagingGridView *)gridView canDeleteItemAtIndex:(NSUInteger)index
{
    NMChannel *channel = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    return [channel.type integerValue] != NMChannelRecommendedType;
}

@end
