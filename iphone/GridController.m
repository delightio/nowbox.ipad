//
//  GridController.m
//  ipad
//
//  Created by Chris Haugli on 11/29/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "GridController.h"
#import "GridNavigationController.h"
#import "GridItemView.h"

@implementation GridController

@synthesize view;
@synthesize gridView;
@synthesize backButton;
@synthesize titleLabel;
@synthesize currentChannel;
@synthesize currentVideo;
@synthesize fetchedResultsController;
@synthesize managedObjectContext;
@synthesize navigationController;
@synthesize delegate;

- (id)init
{
    self = [super init];
    if (self) {
        [[NSBundle mainBundle] loadNibNamed:@"GridController" owner:self options:nil];
        gridView.itemSize = CGSizeMake(104, 70);
        gridView.horizontalItemPadding = 2;
        gridView.numberOfColumns = 0;        
    }
    return self;
}

- (void)dealloc
{
    [view release];
    [gridView release];
    [backButton release];
    [titleLabel release];
    [currentChannel release];
    [currentVideo release];
    [fetchedResultsController release];
    [managedObjectContext release];
    
    [super dealloc];
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)aManagedObjectContext
{
    if (managedObjectContext != aManagedObjectContext) {
        [managedObjectContext release];
        managedObjectContext = [aManagedObjectContext retain];
    }
    
    [gridView reloadData];
}

- (void)setCurrentChannel:(NMChannel *)aCurrentChannel
{
    if (currentChannel != aCurrentChannel) {
        [currentChannel release];
        currentChannel = [aCurrentChannel retain];
    }
    
    if (currentChannel) {
        titleLabel.text = currentChannel.title;
    } else {
        titleLabel.text = @"Channels";
    }
}

#pragma mark - Actions

- (IBAction)itemPressed:(id)sender
{
    NSInteger index = [sender index];
    
    if (currentChannel) {
        // We're on the videos page
        NMVideo *video = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        [delegate gridController:self didSelectVideo:video];
    } else {
        // We're on the channels page
        NMChannel *channel = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        [delegate gridController:self didSelectChannel:channel];
        
        GridController *gridController = [[GridController alloc] init];
        gridController.currentChannel = channel;
        gridController.managedObjectContext = self.managedObjectContext;
        gridController.delegate = self.delegate;
        [navigationController pushGridController:gridController];
        [gridController release];
    }       
}

- (IBAction)backButtonPressed:(id)sender
{
    [navigationController popGridController];
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
        itemView = [[GridItemView alloc] initWithFrame:CGRectMake(0, 0, gridScrollView.itemSize.width, gridScrollView.itemSize.height)];
        [itemView addTarget:self action:@selector(itemPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    itemView.index = index;
    itemView.highlighted = NO;
    
    if (currentChannel) {
        // We're on the videos page
        NMVideo *video = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        [itemView.thumbnail setImageForVideoThumbnail:video];
        itemView.titleLabel.text = video.title;
    } else {
        // We're on the channels page
        NMChannel *channel = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        itemView.titleLabel.text = channel.title;
        [itemView.thumbnail setImageForChannel:channel];
    }

    return itemView;
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController 
{
    if (!managedObjectContext) {
        return nil;
    }
        
    if (!fetchedResultsController) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setReturnsObjectsAsFaults:NO];
        
        if (currentChannel) {
            [fetchRequest setEntity:[NSEntityDescription entityForName:NMVideoEntityName inManagedObjectContext:managedObjectContext]];
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"channel == %@ AND nm_error < %@", currentChannel, [NSNumber numberWithInteger:NMErrorDequeueVideo]]];
            [fetchRequest setFetchBatchSize:5];
            
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:YES];
            NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_session_id" ascending:YES];
            NSArray *sortDescriptors = [NSArray arrayWithObjects:timestampDescriptor, sortDescriptor, nil];
            [fetchRequest setSortDescriptors:sortDescriptors];
            [timestampDescriptor release];
            [sortDescriptor release];
            
        } else {
            [fetchRequest setEntity:[NSEntityDescription entityForName:NMChannelEntityName inManagedObjectContext:managedObjectContext]];
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"nm_subscribed > 0 AND nm_hidden == NO"]];	
            [fetchRequest setFetchBatchSize:20];

            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nm_subscribed" ascending:YES];
            [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            [sortDescriptor release];
        }
        
        fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:managedObjectContext sectionNameKeyPath:nil cacheName:nil];
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

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller 
{
    [gridView reloadData];
}

@end
