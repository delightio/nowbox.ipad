//
//  CategoryGridController.m
//  ipad
//
//  Created by Chris Haugli on 12/1/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "CategoryGridController.h"
#import "GridItemView.h"
#import "SizableNavigationController.h"
#import "ChannelGridController.h"
#import "NMCategory.h"

@implementation CategoryGridController

@synthesize fetchedResultsController;

- (void)dealloc
{
    [fetchedResultsController release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.titleLabel.text = @"Categories";
}

#pragma mark - Actions

- (IBAction)itemPressed:(id)sender
{
    NSInteger index = [sender index];
    
    NMCategory *category = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    
    ChannelGridController *gridController = [[ChannelGridController alloc] initWithNibName:@"GridController" bundle:[NSBundle mainBundle]];
    gridController.managedObjectContext = self.managedObjectContext;
    gridController.delegate = self.delegate;
    gridController.categoryFilter = category;
    [self.navigationController pushViewController:gridController];
    [gridController release];
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
    
    NMCategory *category = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    itemView.titleLabel.text = category.title;
    [itemView.thumbnail setImageForCategory:category];

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
        
        [fetchRequest setEntity:[NSEntityDescription entityForName:NMCategoryEntityName inManagedObjectContext:self.managedObjectContext]];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"nm_id > 0"]];
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

@end
