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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.gridDataSource = [[[HomeGridDataSource alloc] initWithThumbnailViewDelegate:self] autorelease];
    }
    return self;
}

- (void)dealloc
{
    [gridView release];
    [pageControl release];
    [gridDataSource release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    pageControl.numberOfPages = gridView.numberOfPages;
    gridView.dataSource = gridDataSource;
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

#pragma mark - PagingGridViewDelegate

- (void)gridViewDidScroll:(PagingGridView *)aGridView
{
    if (!scrollingToPage) {
        NSUInteger currentPage = MAX(0, round(aGridView.contentOffset.x / aGridView.frame.size.width));
        [pageControl setCurrentPage:currentPage];
    }
}

- (void)gridViewWillBeginDragging:(PagingGridView *)gridView
{
    scrollingToPage = NO;
}

- (void)gridViewDidEndScrollingAnimation:(PagingGridView *)gridView
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

#pragma mark - ThumbnailViewDelegate

- (void)thumbnailViewDidTap:(ThumbnailView *)thumbnailView
{
    NSUInteger index = thumbnailView.tag;
    self.gridDataSource = [gridDataSource nextDataSourceForIndex:index];
    gridView.dataSource = gridDataSource;
    pageControl.numberOfPages = gridView.numberOfPages;
}

- (void)thumbnailViewDidBeginRearranging:(ThumbnailView *)thumbnailView
{
    gridView.scrollEnabled = NO;    
}

- (void)thumbnailViewDidEndRearranging:(ThumbnailView *)thumbnailView
{
    NSUInteger index = thumbnailView.tag;
    [UIView animateWithDuration:0.3
                     animations:^{
                         thumbnailView.frame = [gridView frameForIndex:index];
                     }
                     completion:^(BOOL finished){
                         gridView.scrollEnabled = YES;                         
                     }];
}

- (void)thumbnailView:(ThumbnailView *)thumbnailView didDragToLocation:(CGPoint)location
{
    NSUInteger oldIndex = thumbnailView.tag;
    NSInteger newIndex = [gridView repositioningIndexForFrame:thumbnailView.frame];
    
    if (newIndex != oldIndex && newIndex >= 0) {
        [gridView repositionView:thumbnailView fromIndex:oldIndex toIndex:newIndex animated:YES];
    }
}

@end
