//
//  GridViewController.m
//  ipad
//
//  Created by Chris Haugli on 2/6/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "GridViewController.h"
#import "ThumbnailView.h"

@implementation GridViewController

@synthesize gridView;
@synthesize pageControl;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)dealloc
{
    [gridView release];
    [pageControl release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    pageControl.numberOfPages = 5;    
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

#pragma mark - PagingGridViewDataSource

- (NSUInteger)gridViewNumberOfItems:(PagingGridView *)gridView
{
    return 28;
}

- (UIView *)gridView:(PagingGridView *)aGridView viewForIndex:(NSUInteger)index
{
    ThumbnailView *view = (ThumbnailView *) [aGridView dequeueReusableSubview];
    
    if (!view) {
        view = [[[ThumbnailView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)] autorelease];
    }
    
    view.label.text = [NSString stringWithFormat:@"Channel %i", index];
    
    return view;
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

#pragma mark - CustomPageControlDelegate

- (void)pageControl:(CustomPageControl *)pageControl didSelectPageAtIndex:(NSUInteger)index
{
    scrollingToPage = YES;
    [gridView setContentOffset:CGPointMake(index * gridView.frame.size.width, 0) animated:YES];
}

@end
