//
//  ChannelGridController.m
//  ipad
//
//  Created by Chris Haugli on 12/1/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "ChannelGridController.h"
#import "GridItemView.h"
#import "SizableNavigationController.h"
#import "VideoGridController.h"
#import "CategoryGridController.h"

@implementation ChannelGridController

@synthesize fetchedResultsController;
@synthesize categoryFilter;

- (void)dealloc
{
    [fetchedResultsController release];
    [categoryFilter release];
    
    [super dealloc];
}

- (void)setCategoryFilter:(NMCategory *)aCategoryFilter
{
    if (categoryFilter != aCategoryFilter) {
        [categoryFilter release];
        categoryFilter = [aCategoryFilter retain];
        self.titleLabel.text = categoryFilter.title;
        
        if ([categoryFilter.nm_last_refresh timeIntervalSinceNow] < -60.0f) {
            [[NMTaskQueueController sharedTaskQueueController] issueGetChannelsForCategory:categoryFilter];
        }
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.titleLabel.text = (categoryFilter ? categoryFilter.title : @"Channels");
}

#pragma mark - Actions

- (IBAction)itemPressed:(id)sender
{
    NSInteger index = [sender index];
    
    GridController *gridController;
    
    if (!categoryFilter && index >= [self gridScrollViewNumberOfItems:self.gridView] - 1) {
        gridController = [[CategoryGridController alloc] initWithNibName:@"GridController" bundle:[NSBundle mainBundle]];
    } else {
        NMChannel *channel = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        [self.delegate gridController:self didSelectChannel:channel];
        
        gridController = [[VideoGridController alloc] initWithNibName:@"GridController" bundle:[NSBundle mainBundle]];
        ((VideoGridController *)gridController).currentChannel = channel;
    }
    
    gridController.managedObjectContext = self.managedObjectContext;
    gridController.delegate = self.delegate;
    [self.navigationController pushViewController:gridController];
    [gridController release];
}

#pragma mark - GridScrollViewDelegate

- (NSUInteger)gridScrollViewNumberOfItems:(GridScrollView *)gridScrollView
{
    NSUInteger numberOfItems = [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects];
    return (categoryFilter ? numberOfItems : numberOfItems + 1);
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
    
    if (!categoryFilter && index == [self gridScrollViewNumberOfItems:gridScrollView] - 1) {
        // + button
        itemView.titleLabel.hidden = YES;
        itemView.thumbnail.image = [UIImage imageNamed:@"grid-channels-plus.png"];
        itemView.playing = NO;
    } else {
        NMChannel *channel = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        itemView.titleLabel.hidden = NO;
        itemView.titleLabel.text = channel.title;
        [itemView.thumbnail setImageForChannel:channel];
        itemView.playing = (self.navigationController.playbackModelController.channel == channel);
    }
    
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
        
        [fetchRequest setEntity:[NSEntityDescription entityForName:NMChannelEntityName inManagedObjectContext:self.managedObjectContext]];
        if (categoryFilter) {
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"ANY categories.nm_id == %@ AND nm_hidden == NO", categoryFilter.nm_id]];	
        } else {
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"nm_subscribed > 0 AND nm_hidden == NO"]];	            
        }
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

@end
