//
//  GridController.m
//  ipad
//
//  Created by Chris Haugli on 11/29/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "GridController.h"
#import "NMTaskQueueController.h"
#import "UIView+InteractiveAnimation.h"

@implementation GridController

@synthesize view;
@synthesize gridView;
@synthesize currentChannel;
@synthesize currentVideo;
@synthesize fetchedResultsController;
@synthesize managedObjectContext;
@synthesize delegate;

- (id)init
{
    self = [super init];
    if (self) {
        [[NSBundle mainBundle] loadNibNamed:@"GridController" owner:self options:nil];
        gridView.itemSize = CGSizeMake(100, 50);
        gridView.numberOfColumns = 0;
        
        self.currentChannel = nil;
    }
    return self;
}

- (void)dealloc
{
    [view release];
    [gridView release];
    [currentChannel release];
    [currentVideo release];
    [fetchedResultsController release];
    [managedObjectContext release];
    
    [super dealloc];
}

- (void)setCurrentChannel:(NMChannel *)aCurrentChannel
{
    if (currentChannel != aCurrentChannel) {
        [currentChannel release];
        currentChannel = [aCurrentChannel retain];
    }
    
    self.currentVideo = nil;
    
    [gridView reloadData];
}

- (void)setCurrentVideo:(NMVideo *)aCurrentVideo
{    
    if (currentVideo != aCurrentVideo) {
        [currentVideo release];
        currentVideo = [aCurrentVideo retain];
    }
    
    if (currentVideo) {
        [gridView reloadData];
    }
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)aManagedObjectContext
{
    if (managedObjectContext != aManagedObjectContext) {
        [managedObjectContext release];
        managedObjectContext = [aManagedObjectContext retain];
    }
    
    [gridView reloadData];
}

#pragma mark - Navigation

- (void)slideGridForward:(BOOL)forward
{
    GridScrollView *newGridView = [[gridView copy] autorelease];
    newGridView.frame = CGRectOffset(gridView.frame, (forward ? 1 : -1) * gridView.frame.size.width, 0);
    [view addSubview:newGridView];
     
    [UIView animateWithInteractiveDuration:0.5
                                animations:^{
                                    newGridView.frame = gridView.frame;
                                    gridView.frame = CGRectOffset(gridView.frame, (forward ? -1 : 1) * gridView.frame.size.width, 0);
                                }
                                completion:^(BOOL finished){
                                    [gridView removeFromSuperview];
                                    self.gridView = newGridView;
                                }];    
}

- (void)pushToChannel:(NMChannel *)channel
{
    [fetchedResultsController release];
    fetchedResultsController = nil;

    self.currentChannel = channel;
    [self slideGridForward:YES];
}

- (void)pushToVideo:(NMVideo *)video
{
    [fetchedResultsController release];
    fetchedResultsController = nil;
    
    if (currentVideo) {
        self.currentVideo = video;
        [self slideGridForward:YES];
    } else {
        self.currentVideo = video;
        [gridView reloadData];
    }
}

- (void)pop
{
    // Go back a level
    if (currentVideo) {
        self.currentVideo = nil;
    } else if (currentChannel) {
        self.currentChannel = nil;
    }
    
    [self slideGridForward:NO];
}

#pragma mark - GridScrollViewDelegate

- (NSUInteger)gridScrollViewNumberOfItems:(GridScrollView *)gridScrollView
{
    return [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects];
}

- (UIView *)gridScrollView:(GridScrollView *)gridScrollView viewForItemAtIndex:(NSUInteger)index
{
    UIButton *button = (UIButton *)[gridScrollView dequeueReusableSubview];
    if (!button) {
        button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    button.tag = index;
    
    if (currentChannel) {
        // We're on the videos page
        NMVideo *video = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        [button setTitle:video.title forState:UIControlStateNormal];
    } else {
        // We're on the channels page
        NMChannel *channel = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        [button setTitle:channel.title forState:UIControlStateNormal];        
    }

    return button;
}

- (void)buttonPressed:(id)sender
{
    NSInteger index = [sender tag];
    
    if (currentChannel) {
        // We're on the videos page
        NMVideo *video = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        [delegate gridController:self didSelectVideo:video];
        [self pushToVideo:video];
    } else {
        // We're on the channels page
        NMChannel *channel = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        [delegate gridController:self didSelectChannel:channel];
        [self pushToChannel:channel];
    }       
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
