//
//  HomeGridDataSource.m
//  ipad
//
//  Created by Chris Haugli on 2/7/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "HomeGridDataSource.h"
#import "YouTubeGridDataSource.h"
#import "FacebookGridDataSource.h"
#import "NMAccountManager.h"

@implementation HomeGridDataSource

@synthesize fetchedResultsController;

- (void)dealloc
{    
    [fetchedResultsController release];
    
    [super dealloc];
}

- (GridDataSource *)nextDataSourceForIndex:(NSUInteger)index
{
    NSUInteger frcObjectCount = [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects];
    index = [self mappedFetchedResultsIndexForGridIndex:index];

    if (index >= frcObjectCount) {
        switch (index - frcObjectCount) {
            case 0: {
                // Facebook
                NMAccountManager *accountManager = [NMAccountManager sharedAccountManager];
                if (![accountManager.facebook isSessionValid]) {
                    [accountManager authorizeFacebook];
                }
                return [[[FacebookGridDataSource alloc] initWithGridView:self.gridView managedObjectContext:self.managedObjectContext] autorelease];            
                break;
            }
            default:
                return [[[YouTubeGridDataSource alloc] initWithGridView:self.gridView managedObjectContext:self.managedObjectContext] autorelease];
                break;
        }
    }
    
    return nil;
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
        [fetchRequest setEntity:[NSEntityDescription entityForName:NMSubscriptionEntityName inManagedObjectContext:self.managedObjectContext]];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"nm_hidden == NO AND channel != nil AND (channel.type == %@ OR channel.type == %@)", 
                                    [NSNumber numberWithInteger:NMChannelRecommendedType],
                                    [NSNumber numberWithInteger:NMChannelUserType]]];
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
        [self configureCell:cell forChannel:channel];
    } else {
        [super controller:controller didChangeObject:anObject atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];
    }
}

#pragma mark - PagingGridViewDataSource

- (NSUInteger)gridViewNumberOfItems:(PagingGridView *)aGridView
{
    return [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects] + 4;
}

- (PagingGridViewCell *)gridView:(PagingGridView *)aGridView cellForIndex:(NSUInteger)index
{
    // index = 1 doesn't exist. First cell spans two columns.
    if (index == 1) return nil;
    
    PagingGridViewCell *view = (PagingGridViewCell *) [aGridView dequeueReusableCell];
    
    if (!view) {
        view = [[[PagingGridViewCell alloc] init] autorelease];
    }
     
    NSUInteger frcObjectCount = [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects];
    NSUInteger frcIndex = [self mappedFetchedResultsIndexForGridIndex:index];
    
    if (frcIndex < frcObjectCount) {
        NMSubscription *subscription = [self objectAtIndex:index];
        [self configureCell:view forChannel:subscription.channel];
    } else {
        switch (frcIndex - frcObjectCount) {
            case 0:
                view.label.text = @"Facebook";
                view.image.image = [UIImage imageNamed:@"social-facebook.png"];
                break;
            case 1:
                view.label.text = @"YouTube";
                view.image.image = [UIImage imageNamed:@"social-youtube.png"];
                break;
            case 2:
                view.label.text = @"Twitter";
                view.image.image = [UIImage imageNamed:@"social-twitter.png"];            
                break;
            default:
                break;
        }
    }
    
    return view;
}

- (BOOL)gridView:(PagingGridView *)gridView canDeleteItemAtIndex:(NSUInteger)index
{
    return NO;
}

- (BOOL)gridView:(PagingGridView *)gridView canRearrangeItemAtIndex:(NSUInteger)index
{
    return NO;
}

- (NSUInteger)gridView:(PagingGridView *)gridView columnSpanForCellAtIndex:(NSUInteger)index
{
    return (index == 0 ? 2 : 1);
}

@end
