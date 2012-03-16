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

- (id)initWithGridView:(PagingGridView *)aGridView managedObjectContext:(NSManagedObjectContext *)aManagedObjectContext
{
    self = [super initWithGridView:aGridView managedObjectContext:aManagedObjectContext];
    if (self) {
        self.title = @"Facebook";
        
        [[NMAccountManager sharedAccountManager] addObserver:self forKeyPath:@"facebookAccountStatus" options:0 context:NULL];
    }
    return self;
}

- (void)dealloc
{    
    [[NMAccountManager sharedAccountManager] removeObserver:self forKeyPath:@"facebookAccountStatus"];
    
    [fetchedResultsController release];
    
    [super dealloc];
}

- (NMChannel *)selectObjectAtIndex:(NSUInteger)index
{
    NMChannel *channel = [[self objectAtIndex:index] channel];
    
    if (index > 0) {
        // Start crawling user's feed for more videos
        [[NMTaskQueueController sharedTaskQueueController] issueProcessFeedForChannel:channel];
    }
    
    return channel;
}

- (id)objectAtIndex:(NSUInteger)index
{
    index = [self mappedFetchedResultsIndexForGridIndex:index];
    return [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
}

- (NSUInteger)mappedFetchedResultsIndexForGridIndex:(NSUInteger)gridIndex
{
    return (gridIndex == 0 ? 0 : gridIndex - 1);
}

- (NSUInteger)mappedGridIndexForFetchedResultsIndex:(NSUInteger)fetchedResultsIndex;
{
    return (fetchedResultsIndex == 0 ? 0 : fetchedResultsIndex + 1);
}

- (void)moveObjectAtIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex
{
    oldIndex = [self mappedFetchedResultsIndexForGridIndex:oldIndex];
    newIndex = [self mappedFetchedResultsIndexForGridIndex:newIndex];
    
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
    index = [self mappedFetchedResultsIndexForGridIndex:index];
    
    NMSubscription *subscriptionToDelete = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    [[NMTaskQueueController sharedTaskQueueController] issueSubscribe:NO channel:subscriptionToDelete.channel];
}

- (void)configureCell:(PagingGridViewCell *)cell forChannel:(NMChannel *)channel isUpdate:(BOOL)isUpdate
{
    cell.label.text = channel.title;
    
    NMDataController *dataController = [NMTaskQueueController sharedTaskQueueController].dataController;
    NMVideo *latestVideo = [dataController latestVideoForChannel:channel];
    
    if (latestVideo) {
        [cell.image setImageForVideoThumbnail:latestVideo];
        cell.authorView.hidden = NO;
        [cell.authorImage setImageForChannel:channel];
    } else {
        [cell.image setImageForChannel:channel];
    }
    
    if ([[NMAccountManager sharedAccountManager].facebookAccountStatus integerValue] == NMSyncSyncInProgress) {
        if (![cell.activityIndicator isAnimating]) {
            [cell.activityIndicator startAnimating];
        }
    } else {
        [cell.activityIndicator stopAnimating];
    }
}

- (void)refreshAllObjects
{
    [[NMAccountManager sharedAccountManager] scheduleSyncSocialChannels];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // Facebook sync status updated, we have imported some videos
    [self.gridView updateVisibleItems];
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
        NMChannel *channel = [(NMSubscription *)anObject channel];
        NSUInteger gridIndex = [self mappedGridIndexForFetchedResultsIndex:indexPath.row];
        PagingGridViewCell *cell = [self.gridView cellForIndex:gridIndex];
        [self configureCell:cell forChannel:channel isUpdate:YES];
    } else {
        [super controller:controller didChangeObject:anObject atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];
    }
}

#pragma mark - PagingGridViewDataSource

- (NSUInteger)gridViewNumberOfItems:(PagingGridView *)aGridView
{
    NSUInteger numberOfItems = [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects];
    return (numberOfItems == 0 ? 0 : numberOfItems + 1);
}

- (PagingGridViewCell *)gridView:(PagingGridView *)aGridView cellForIndex:(NSUInteger)index
{
    // First cell spans two columns
    if (index == 1) return nil;
    
    PagingGridViewCell *view = (PagingGridViewCell *) [aGridView dequeueReusableCell];
    
    if (!view) {
        view = [[[PagingGridViewCell alloc] init] autorelease];
    }
    
    index = [self mappedFetchedResultsIndexForGridIndex:index];
    NMChannel *channel = [[self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]] channel];
    [self configureCell:view forChannel:channel isUpdate:NO];
    
    return view;
}

- (BOOL)gridView:(PagingGridView *)gridView canDeleteItemAtIndex:(NSUInteger)index
{
    return NO;
}

- (NSUInteger)gridView:(PagingGridView *)gridView columnSpanForCellAtIndex:(NSUInteger)index
{
    return (index == 0 ? 2 : 1);
}

- (BOOL)gridView:(PagingGridView *)gridView canRearrangeItemAtIndex:(NSUInteger)index
{
    return index > 1;
}

@end
