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
    
    pageControl.numberOfPages = 3;    
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
    return 14;
}

- (UIView *)gridView:(PagingGridView *)aGridView viewForIndex:(NSUInteger)index
{
    ThumbnailView *view = (ThumbnailView *) [aGridView dequeueReusableSubview];
    
    if (!view) {
        view = [[[ThumbnailView alloc] init] autorelease];
    }
    
    switch (index) {
        case 0:
            view.label.text = @"Facebook";
            view.image.image = [UIImage imageNamed:@"social-facebook.png"];
            break;
        case 1:
            view.label.text = @"YouTube";
            view.image.image = [UIImage imageNamed:@"social-youtube.png"];
            break;
        case 2:
            view.label.text = @"Twitter";
            view.image.image = [UIImage imageNamed:@"social-twitter.png"];            
            break;
        case 3:
            view.label.text = @"Trending";
            view.image.image = [UIImage imageNamed:@"social-vimeo.png"];            
            break;
        default:
            view.label.text = [NSString stringWithFormat:@"Channel %i", index];
            view.image.image = nil;
            break;
    }
    
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

@end
