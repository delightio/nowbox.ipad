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
#import "UIFont+BackupFont.h"

@interface GridViewController (PrivateMethods)
- (void)updateTitleBarForDataSource:(id<PagingGridViewDataSource>)dataSource;
@end

@implementation GridViewController

@synthesize gridView;
@synthesize nowboxLogo;
@synthesize titleLabel;
@synthesize backButton;
@synthesize refreshButton;
@synthesize pageControl;
@synthesize gridDataSource;
@synthesize managedObjectContext;

- (id)initWithDataSource:(GridDataSource *)aDataSource managedObjectContext:(NSManagedObjectContext *)aManagedObjectContext nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.managedObjectContext = aManagedObjectContext;
        self.gridDataSource = aDataSource;
    }
    return self;
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aManagedObjectContext nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithDataSource:[[[HomeGridDataSource alloc] initWithGridView:nil viewController:self managedObjectContext:managedObjectContext] autorelease]
               managedObjectContext:aManagedObjectContext
                            nibName:nibNameOrNil
                             bundle:nibBundleOrNil];
}

- (void)dealloc
{    
    [gridView release];
    [nowboxLogo release];
    [titleLabel release];
    [backButton release];
    [refreshButton release];
    [pageControl release];
    [gridDataSource release];
    [managedObjectContext release];
    
    [super dealloc];
}

- (void)updateTitleBarForDataSource:(id<PagingGridViewDataSource>)dataSource
{
#ifdef FRIENDBOX
    refreshButton.alpha = 1.0f;
#else
    if ([dataSource isKindOfClass:[HomeGridDataSource class]]) {
        refreshButton.alpha = 0.0f;
        backButton.alpha = 0.0f;
        titleLabel.alpha = 0.0f;
        nowboxLogo.alpha = 1.0f;
    } else {
        refreshButton.alpha = 1.0f;
        backButton.alpha = 1.0f;
        titleLabel.alpha = 1.0f;
        nowboxLogo.alpha = 0.0f;
    }    
#endif
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [gridDataSource setGridView:gridView];
    [gridView setDataSource:gridDataSource animated:NO];
    [self updateTitleBarForDataSource:gridDataSource];
    
    titleLabel.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:26.0f backupFontName:@"Futura-Medium" size:22.0f];
    [titleLabel setGradientStartColor:[UIColor colorWithRed:255.0/255.0f green:223.0/255.0f blue:93.0/255.0f alpha:1.0f]
                             endColor:[UIColor colorWithRed:255.0/255.0f green:197.0/255.0f blue:61.0/255.0f alpha:1.0f]];

    // If view was unloaded, restore the page we were on
    pageControl.currentPage = currentPage;
    [gridView setContentOffset:CGPointMake(currentPage * gridView.frame.size.width, 0) animated:NO];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.gridView = nil;
    self.nowboxLogo = nil;
    self.titleLabel = nil;
    self.backButton = nil;
    self.refreshButton = nil;
    self.pageControl = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (IBAction)refreshButtonPressed:(id)sender
{
    [gridDataSource refreshAllObjects];
    [gridView reloadData];
}

- (IBAction)backButtonPressed:(id)sender
{
    [gridView setRearranging:NO animated:NO];
    
    if (![gridDataSource isKindOfClass:[HomeGridDataSource class]]) {
        GridDataSource *homeDataSource = [[[HomeGridDataSource alloc] initWithGridView:gridView viewController:self managedObjectContext:managedObjectContext] autorelease];
        [gridView setDataSource:homeDataSource animated:YES];
    }
}

#pragma mark - PagingGridViewDelegate

- (void)gridView:(PagingGridView *)aGridView dataSourceWillAnimate:(id<PagingGridViewDataSource>)newDataSource
{
    titleLabel.text = ((GridDataSource *)newDataSource).title;
    
    [UIView animateWithDuration:0.3 animations:^{
        [self updateTitleBarForDataSource:newDataSource];
    }];
}

- (void)gridView:(PagingGridView *)aGridView dataSourceDidChange:(id<PagingGridViewDataSource>)newDataSource
{
    self.gridDataSource = (GridDataSource *)newDataSource;
    pageControl.numberOfPages = gridView.numberOfPages;
    pageControl.currentPage = gridView.currentPage;
}

- (void)gridView:(PagingGridView *)aGridView didSelectItemAtIndex:(NSUInteger)index
{
    NMChannel *channel = [gridDataSource selectObjectAtIndex:index];
    if (channel) {
        // Go to video player
        PhoneVideoPlaybackViewController *playbackController = [[PhoneVideoPlaybackViewController alloc] initWithNibName:@"PhoneVideoPlaybackView" bundle:nil];
        [playbackController setManagedObjectContext:managedObjectContext];
        [self.navigationController pushViewController:playbackController animated:YES];
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

- (void)gridView:(PagingGridView *)aGridView numberOfItemsDidChange:(NSUInteger)numberOfItems
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
