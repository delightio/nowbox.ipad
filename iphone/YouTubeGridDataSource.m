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
    return self;
}

- (void)moveObjectAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
//    NMDataController *dataController = [NMTaskQueueController sharedTaskQueueController].dataController;            
//    NMChannel *channel = [dataController.subscribedChannels objectAtIndex:index];
    
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
//    NMDataController *dataController = [NMTaskQueueController sharedTaskQueueController].dataController;
//    return [dataController.subscribedChannels count];
    return [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects];
}

- (UIView *)gridView:(PagingGridView *)aGridView viewForIndex:(NSUInteger)index
{
    ThumbnailView *view = (ThumbnailView *) [aGridView dequeueReusableSubview];
    
    if (!view) {
        view = [[[ThumbnailView alloc] init] autorelease];
        view.delegate = self.thumbnailViewDelegate;
    }
        
//    NMDataController *dataController = [NMTaskQueueController sharedTaskQueueController].dataController;            
//    NMChannel *channel = [dataController.subscribedChannels objectAtIndex:index];
    NMChannel *channel = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    view.label.text = channel.title;
    [view.image setImageForChannel:channel];

    return view;
}

@end
