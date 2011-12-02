//
//  GridController.m
//  ipad
//
//  Created by Chris Haugli on 11/29/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "GridController.h"
#import "SizableNavigationController.h"

@implementation GridController

@synthesize gridView;
@synthesize backButton;
@synthesize titleLabel;
@synthesize managedObjectContext;
@synthesize navigationController;
@synthesize delegate;

- (void)dealloc
{
    [gridView release];
    [backButton release];
    [titleLabel release];
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

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    gridView.itemSize = CGSizeMake(104, 70);
    gridView.horizontalItemPadding = 2;
    gridView.numberOfColumns = 0;            
}

- (void)viewDidUnload
{
    self.gridView = nil;
    self.backButton = nil;
    self.titleLabel = nil;

    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.backButton.hidden = ([navigationController.viewControllers objectAtIndex:0] == self);
    
    CGPoint contentOffset = gridView.contentOffset;
    [gridView reloadData];
    gridView.contentOffset = contentOffset;
}

#pragma mark - Actions

- (IBAction)backButtonPressed:(id)sender
{
    [navigationController popViewController];
}

#pragma mark - GridScrollViewDelegate

- (NSUInteger)gridScrollViewNumberOfItems:(GridScrollView *)gridScrollView
{
    return 0;
}

- (UIView *)gridScrollView:(GridScrollView *)gridScrollView viewForItemAtIndex:(NSUInteger)index
{
    return nil;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [gridView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath 
{    
    switch(type) {
        case NSFetchedResultsChangeInsert: 
            [gridView insertItemAtIndex:newIndexPath.row];
            break;
        case NSFetchedResultsChangeDelete:
            [gridView deleteItemAtIndex:indexPath.row];
            break;
        case NSFetchedResultsChangeUpdate:
            [gridView updateItemAtIndex:indexPath.row];
            break;
        case NSFetchedResultsChangeMove:
            [gridView deleteItemAtIndex:indexPath.row];
            [gridView insertItemAtIndex:newIndexPath.row];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller 
{
    [gridView endUpdates];
}

@end
