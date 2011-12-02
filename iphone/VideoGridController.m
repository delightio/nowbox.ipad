//
//  VideoGridController.m
//  ipad
//
//  Created by Chris Haugli on 12/1/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "VideoGridController.h"
#import "GridItemView.h"
#import "SizableNavigationController.h"

@implementation VideoGridController

@synthesize currentChannel;
@synthesize fetchedResultsController;

- (void)dealloc
{
    [currentChannel release];
    [fetchedResultsController release];

    [super dealloc];
}

- (void)setCurrentChannel:(NMChannel *)aCurrentChannel
{
    if (currentChannel != aCurrentChannel) {
        [currentChannel release];
        currentChannel = [aCurrentChannel retain];
    }
    
    self.titleLabel.text = currentChannel.title;
}

#pragma mark - Actions

- (IBAction)itemPressed:(id)sender
{
    NSInteger index = [sender index];
    NMVideo *video = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    [self.delegate gridController:self didSelectVideo:video];
}

#pragma mark - GridScrollViewDelegate

- (NSUInteger)gridScrollViewNumberOfItems:(GridScrollView *)gridScrollView
{
    return [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects];
}

- (UIView *)gridScrollView:(GridScrollView *)gridScrollView viewForItemAtIndex:(NSUInteger)index
{
    GridItemView *itemView = (GridItemView *)[gridScrollView dequeueReusableSubview];
    if (!itemView) {
        itemView = [[[GridItemView alloc] initWithFrame:CGRectMake(0, 0, gridScrollView.itemSize.width, gridScrollView.itemSize.height)] autorelease];
        [itemView addTarget:self action:@selector(itemPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    itemView.index = index;
    itemView.highlighted = NO;
    
    NMVideo *video = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    [itemView.thumbnail setImageForVideoThumbnail:video];
    itemView.titleLabel.text = video.title;
    itemView.playing = (self.navigationController.playbackModelController.currentVideo == video);
    
    return itemView;
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
        
        [fetchRequest setEntity:[NSEntityDescription entityForName:NMVideoEntityName inManagedObjectContext:self.managedObjectContext]];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"channel == %@ AND nm_error < %@", currentChannel, [NSNumber numberWithInteger:NMErrorDequeueVideo]]];
        [fetchRequest setFetchBatchSize:5];
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:YES];
        NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_session_id" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:timestampDescriptor, sortDescriptor, nil];
        [fetchRequest setSortDescriptors:sortDescriptors];
        [timestampDescriptor release];
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

@end
