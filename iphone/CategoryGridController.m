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
#import "VideoGridController.h"
#import "NMCategory.h"
#import "Analytics.h"

#define kDefaultPredicate @"nm_id > 0"

@implementation CategoryGridController

@synthesize fetchedResultsController;
@synthesize lastSearchQuery;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidSearchNotification:) name:NMDidSearchChannelsNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [fetchedResultsController release];
    [lastSearchQuery release];
    
    [super dealloc];
}

- (void)performSearchWithText:(NSString *)searchText
{
    // Don't search for the same thing twice in a row (can happen if user presses Search button)
    if ([self.lastSearchQuery isEqualToString:searchText]) return;
    
    NMTaskQueueController *ctrl = [NMTaskQueueController sharedTaskQueueController];
    [ctrl.dataController clearSearchResultCache];
    if ([searchText length] > 0) {
        NSLog(@"issuing search for text %@", searchText);
        [ctrl issueChannelSearchForKeyword:searchText];
        
        [[MixpanelAPI sharedAPI] track:AnalyticsEventPerformSearch properties:[NSDictionary dictionaryWithObject:searchText forKey:AnalyticsPropertySearchQuery]];
        self.lastSearchQuery = searchText;
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.titleLabel.text = @"Categories";
    self.searchBar.placeholder = @"Search channels";    
    
    self.searchBar.hidden = NO;
    self.gridView.headerView = self.searchBar;
}

#pragma mark - Actions

- (IBAction)itemPressed:(id)sender
{
    NSInteger index = [sender index];
    
    id object = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    GridController *gridController;
    
    if ([object isKindOfClass:[NMCategory class]]) {
        NMCategory *category = (NMCategory *)object;
        gridController = [[ChannelGridController alloc] initWithNibName:@"GridController" bundle:[NSBundle mainBundle]];
        ((ChannelGridController *)gridController).categoryFilter = category;        
    } else {
        NMChannel *channel = (NMChannel *)object;
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
    
    id object = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    
    if ([object isKindOfClass:[NMCategory class]]) {
        NMCategory *category = (NMCategory *)object;
        itemView.titleLabel.text = category.title;
        [itemView.thumbnail setImageForCategory:category];
    } else {
        NMChannel *channel = (NMChannel *)object;
        itemView.titleLabel.text = channel.title;
        [itemView.thumbnail setImageForChannel:channel];
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
        
        [fetchRequest setEntity:[NSEntityDescription entityForName:NMCategoryEntityName inManagedObjectContext:self.managedObjectContext]];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:kDefaultPredicate]];
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

#pragma mark - Notifications

-(void)clearSearchResults {
    NMTaskQueueController *ctrl = [NMTaskQueueController sharedTaskQueueController];
	[ctrl.dataController clearSearchResultCache];
    self.lastSearchQuery = nil;
}

- (void)handleDidSearchNotification:(NSNotification *)aNotification {    
    NSString *searchText = self.searchBar.text;
    NSString *keyword = [[aNotification userInfo] objectForKey:@"keyword"];
    NSLog(@"got results for keyword: %@", keyword);
    
    if ([keyword isEqualToString:searchText]) {        
        // Hide the keyboard, but avoid autocomplete messing with our query after it's done!
        [self.searchBar resignFirstResponder];
        [self.searchBar setShowsCancelButton:NO animated:YES];
        self.searchBar.text = searchText;
        [self.gridView reloadDataKeepOffset:YES];
    } else {
        // These are not the search results we're looking for
        [self clearSearchResults];
    }    
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self clearSearchResults];
    [NSFetchedResultsController deleteCacheWithName:nil];
    
    if (searchText.length > 0) {
        [self.fetchedResultsController.fetchRequest setEntity:[NSEntityDescription entityForName:NMChannelEntityName inManagedObjectContext:self.managedObjectContext]];
        [self.fetchedResultsController.fetchRequest setPredicate:[[NMTaskQueueController sharedTaskQueueController].dataController searchResultsPredicate]];
        
        [self performSelector:@selector(performSearchWithText:) withObject:searchText afterDelay:1.0];        
    } else {
        [self.fetchedResultsController.fetchRequest setEntity:[NSEntityDescription entityForName:NMCategoryEntityName inManagedObjectContext:self.managedObjectContext]];        
        [self.fetchedResultsController.fetchRequest setPredicate:[NSPredicate predicateWithFormat:kDefaultPredicate]];	            
    }
    
    NSError *error = nil;
    if (![fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    [self.gridView reloadDataKeepOffset:YES];
}

@end
