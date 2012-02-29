//
//  GridViewController.m
//  ipad
//
//  Created by Chris Haugli on 2/6/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "GridViewController.h"
#import "HomeGridDataSource.h"
#import "YouTubeGridDataSource.h"
#import "PhoneVideoPlaybackViewController.h"

@implementation GridViewController

@synthesize gridView;
@synthesize pageControl;
@synthesize gridDataSource;
@synthesize managedObjectContext;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aManagedObjectContext nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.managedObjectContext = aManagedObjectContext;
    }
    return self;
}

- (void)dealloc
{    
    [gridView release];
    [pageControl release];
    [gridDataSource release];
    [managedObjectContext release];
    
    [super dealloc];
}

- (void)setGridDataSource:(GridDataSource *)aGridDataSource
{
    if (gridDataSource != aGridDataSource) {
        [gridDataSource release];
        gridDataSource = [aGridDataSource retain];
        
        gridView.dataSource = gridDataSource;
        pageControl.numberOfPages = gridView.numberOfPages;
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.gridDataSource = [[[HomeGridDataSource alloc] initWithGridView:gridView viewController:self managedObjectContext:managedObjectContext] autorelease];
    
    // If view was unloaded, restore the page we were on
    pageControl.currentPage = currentPage;
    [gridView setContentOffset:CGPointMake(currentPage * gridView.frame.size.width, 0) animated:NO];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.gridView = nil;
    self.pageControl = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (IBAction)searchButtonPressed:(id)sender
{
    
}

- (IBAction)refreshButtonPressed:(id)sender
{
    
}

- (IBAction)settingsButtonPressed:(id)sender
{
    
}

- (IBAction)backButtonPressed:(id)sender
{
    [gridView setRearranging:NO animated:NO];
    
    if (![gridDataSource isKindOfClass:[HomeGridDataSource class]]) {
        self.gridDataSource = [[[HomeGridDataSource alloc] initWithGridView:gridView viewController:self managedObjectContext:managedObjectContext] autorelease];
    }
}

#pragma mark - PagingGridViewDelegate

- (void)gridView:(PagingGridView *)aGridView didSelectItemAtIndex:(NSUInteger)index
{
    GridDataSource *nextDataSource = [gridDataSource nextDataSourceForIndex:index];
    
    if (nextDataSource) {
        // Load another set of grid items
        self.gridDataSource = nextDataSource;
    } else {
        // Go to video player
        NMChannel *channel = [[gridDataSource objectAtIndex:index] channel];
        
        PhoneVideoPlaybackViewController *playbackController = [[PhoneVideoPlaybackViewController alloc] initWithNibName:@"PhoneVideoPlaybackView" bundle:nil];
        [playbackController setManagedObjectContext:managedObjectContext];
        [self presentModalViewController:playbackController animated:NO];
        [playbackController setCurrentChannel:channel startPlaying:YES];
        [playbackController release];
    }
}

- (BOOL)gridView:(PagingGridView *)aGridView shouldDeleteItemAtIndex:(NSUInteger)index
{
    [gridDataSource deleteObjectAtIndex:index];
    
    // We will delete the cell ourselves once the data source is finished deleting
    return NO;
}

- (void)gridView:(PagingGridView *)aGridView didDeleteItemAtIndex:(NSUInteger)index
{
    pageControl.numberOfPages = aGridView.numberOfPages;
    pageControl.currentPage = aGridView.currentPage;
}

- (void)gridViewDidBeginRearranging:(PagingGridView *)gridView
{
    // Don't want moves because then the FRC changes trigger layoutSubviews which cancel our drags
    gridDataSource.ignoresMoveChanges = YES;
}

- (void)gridView:(PagingGridView *)gridView didMoveItemAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    [gridDataSource moveObjectAtIndex:fromIndex toIndex:toIndex];
}

- (void)gridViewDidEndRearranging:(PagingGridView *)gridView
{
    gridDataSource.ignoresMoveChanges = NO;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!scrollingToPage) {
        currentPage = MAX(0, round(scrollView.contentOffset.x / scrollView.frame.size.width));
        [pageControl setCurrentPage:currentPage];
    }    
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    scrollingToPage = NO;    
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    scrollingToPage = NO;    
}

#pragma mark - CustomPageControlDelegate

- (BOOL)pageControl:(CustomPageControl *)pageControl shouldSelectPageAtIndex:(NSUInteger)index
{
    return !scrollingToPage;
}

- (void)pageControl:(CustomPageControl *)pageControl didSelectPageAtIndex:(NSUInteger)index
{
    scrollingToPage = YES;
    currentPage = index;
    [gridView setContentOffset:CGPointMake(index * gridView.frame.size.width, 0) animated:YES];
}

@end
