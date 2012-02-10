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

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    pageControl.numberOfPages = gridView.numberOfPages;
    
    self.gridDataSource = [[[HomeGridDataSource alloc] initWithGridView:gridView managedObjectContext:managedObjectContext] autorelease];
    gridView.dataSource = gridDataSource;
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.gridView = nil;
    self.gridDataSource = nil;
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

#pragma mark - PagingGridViewDelegate

- (void)gridView:(PagingGridView *)aGridView didSelectItemAtIndex:(NSUInteger)index
{
    self.gridDataSource = [gridDataSource nextDataSourceForIndex:index];
    aGridView.dataSource = gridDataSource;
    pageControl.numberOfPages = aGridView.numberOfPages;
}

- (BOOL)gridView:(PagingGridView *)aGridView shouldDeleteItemAtIndex:(NSUInteger)index
{
    [gridDataSource deleteObjectAtIndex:index];
    
    // We will delete the item ourselves once the data source is finished deleting
    return NO;
}

- (void)gridView:(PagingGridView *)aGridView didDeleteItemAtIndex:(NSUInteger)index
{
    pageControl.numberOfPages = aGridView.numberOfPages;
    pageControl.currentPage = aGridView.currentPage;
}

- (void)gridViewDidBeginRearranging:(PagingGridView *)gridView
{
    NSLog(@"begin rearranging");
    // Don't want updates because then we get layoutSubviews which messes up our drag events
    gridDataSource.updatesEnabled = NO;
}

- (void)gridView:(PagingGridView *)gridView didMoveItemAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    [gridDataSource moveObjectAtIndex:fromIndex toIndex:toIndex];
}

- (void)gridViewDidEndRearranging:(PagingGridView *)gridView
{
    NSLog(@"end rearranging");    
    gridDataSource.updatesEnabled = YES;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!scrollingToPage) {
        NSUInteger currentPage = MAX(0, round(scrollView.contentOffset.x / scrollView.frame.size.width));
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
    [gridView setContentOffset:CGPointMake(index * gridView.frame.size.width, 0) animated:YES];
}

@end
