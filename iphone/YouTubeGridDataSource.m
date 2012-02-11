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

- (id)initWithGridView:(PagingGridView *)aGridView managedObjectContext:(NSManagedObjectContext *)aManagedObjectContext
{
    self = [super initWithGridView:aGridView managedObjectContext:aManagedObjectContext];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUnsubscribeChannelNotification:) name:NMDidUnsubscribeChannelNotification object:nil];
        channelsToIndexes = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [channelsToIndexes release];
    [fetchedResultsController release];
    
    [super dealloc];
}

- (GridDataSource *)nextDataSourceForIndex:(NSUInteger)index
{
    return self;
}

- (void)moveObjectAtIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex
{
    NMChannel *displacedChannel = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:newIndex inSection:0]];
    NSNumber *newSortOrder = displacedChannel.nm_subscribed;
    
    if (newIndex < oldIndex) {
        for (NSInteger i = newIndex; i < oldIndex; i++) {
            NMChannel *thisChannel = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            NMChannel *nextChannel = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:i+1 inSection:0]];            
            thisChannel.nm_subscribed = nextChannel.nm_subscribed;
        }
    } else {
        for (NSInteger i = newIndex; i > oldIndex; i--) {
            NMChannel *thisChannel = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            NMChannel *nextChannel = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:i-1 inSection:0]];
            thisChannel.nm_subscribed = nextChannel.nm_subscribed;
        }        
    }
    
    NMChannel *channelToMove = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:oldIndex inSection:0]];
    channelToMove.nm_subscribed = newSortOrder;
}

- (void)deleteObjectAtIndex:(NSUInteger)index
{
    NMChannel *channelToDelete = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    [channelsToIndexes setObject:[NSNumber numberWithUnsignedInteger:index] forKey:channelToDelete.nm_id];
    [[NMTaskQueueController sharedTaskQueueController] issueSubscribe:NO channel:channelToDelete];
}

#pragma mark - Notifications

- (void)didUnsubscribeChannelNotification:(NSNotification *)notification
{
    NMChannel *channel = [[notification userInfo] objectForKey:@"channel"];
    NSUInteger index = [[channelsToIndexes objectForKey:channel.nm_id] unsignedIntegerValue];
    [channelsToIndexes removeObjectForKey:channel.nm_id];
    
    [self.gridView beginUpdates];
    [self.gridView deleteItemAtIndex:index animated:YES];
    [self.gridView endUpdates];
    
    // Other indexes waiting for deletion will be shifted down by one
    for (NMChannel *otherChannel in [channelsToIndexes allKeys]) {
        NSUInteger otherIndex = [[channelsToIndexes objectForKey:channel.nm_id] unsignedIntegerValue];
        if (otherIndex > index) {
            [channelsToIndexes setObject:[NSNumber numberWithUnsignedInteger:otherIndex-1] forKey:otherChannel.nm_id];
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
        [fetchRequest setEntity:[NSEntityDescription entityForName:NMChannelEntityName inManagedObjectContext:self.managedObjectContext]];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"nm_subscribed > 0 AND nm_hidden == NO"]];	            
        [fetchRequest setFetchBatchSize:20];
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_subscribed" ascending:YES];
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
    view.label.text = channel.title;
    [view.image setImageForChannel:channel];
    
    return view;
}

- (BOOL)gridView:(PagingGridView *)gridView canDeleteItemAtIndex:(NSUInteger)index
{
    NMChannel *channel = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    return [channel.type integerValue] != NMChannelRecommendedType;
}

@end
