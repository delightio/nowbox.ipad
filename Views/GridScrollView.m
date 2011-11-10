//
//  GridScrollView.m
//  ipad
//
//  Created by Chris Haugli on 11/4/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "GridScrollView.h"

@implementation GridScrollView

@synthesize rowsPerPage;
@synthesize columnsPerPage;
@synthesize pageMarginLeft;
@synthesize pageMarginRight;
@synthesize gridDelegate;

- (void)setup
{
    self.pagingEnabled = YES;
    self.delegate = self;
    
    columnsPerPage = 3;
    rowsPerPage = 4;
    
    firstVisiblePage = -1;
    lastVisiblePage = -1;
    
    visibleViews = [[NSMutableSet alloc] init];
    recycledViews = [[NSMutableSet alloc] init];
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    [visibleViews release];
    [recycledViews release];
    
    [super dealloc];
}

- (void)setRowsPerPage:(NSInteger)aRowsPerPage
{
    rowsPerPage = aRowsPerPage;
    [self reloadData];
}

- (void)setColumnsPerPage:(NSInteger)aColumnsPerPage
{
    columnsPerPage = aColumnsPerPage;
    [self reloadData];
}

- (void)setPageMarginLeft:(CGFloat)aPageMarginLeft
{
    pageMarginLeft = aPageMarginLeft;
    [self setNeedsLayout];
}

- (void)setPageMarginRight:(CGFloat)aPageMarginRight
{
    pageMarginRight = aPageMarginRight;
    [self setNeedsLayout];
}

- (void)setDelegate:(id<UIScrollViewDelegate>)delegate
{
    if (delegate == self || delegate == nil) {
        [super setDelegate:delegate];
    } else {
        NSLog(@"Warning: setting scroll view delegate on GridScrollView is not supported. Use gridDelegate instead.");
        [self doesNotRecognizeSelector:_cmd];
    }
}

- (void)setGridDelegate:(id<GridScrollViewDelegate>)aGridDelegate
{
    gridDelegate = aGridDelegate;
    [self reloadData];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self setNeedsLayout];
}

- (void)populatePage:(NSUInteger)page
{
    CGFloat columnWidth = round((self.frame.size.width - pageMarginLeft - pageMarginRight) / columnsPerPage);
    CGFloat rowHeight = round(self.frame.size.height / rowsPerPage);
    
    for (NSInteger row = 0; row < rowsPerPage; row++) {
        for (NSInteger col = 0; col < columnsPerPage && (page * rowsPerPage * columnsPerPage + row * columnsPerPage + col < numberOfItems); col++) {
            UIView *view = [gridDelegate gridScrollView:self viewForItemAtIndex:page * rowsPerPage * columnsPerPage + row * columnsPerPage + col];
            view.frame = CGRectMake(page * self.frame.size.width + pageMarginLeft + col * columnWidth, row * rowHeight, view.frame.size.width, view.frame.size.height);
            view.tag = page;
            [self addSubview:view];
            [visibleViews addObject:view];
        }
    }
}

- (void)layoutSubviews
{
    // Figure out which pages should be shown
    CGFloat leftX = self.contentOffset.x;
    CGFloat rightX = self.contentOffset.x + self.frame.size.width;
    NSInteger leftPage = MAX(0, floor((leftX - 10) / self.frame.size.width));
    NSInteger rightPage = MIN(numberOfPages - 1, floor((rightX + 10) / self.frame.size.width));
    
    // Can we remove any views?
    NSMutableSet *viewsToRemove = [[NSMutableSet alloc] init];
    for (UIView *view in visibleViews) {
        if (view.tag < leftPage || view.tag > rightPage) {
            [recycledViews addObject:view];
            [view removeFromSuperview];
            [viewsToRemove addObject:view];
        }
    }
    [visibleViews minusSet:viewsToRemove];
    [viewsToRemove release];
    
    // Do we need to add any views?
    if (firstVisiblePage == -1) {
        [self populatePage:leftPage];
        [self populatePage:rightPage];
    } else {
        while (firstVisiblePage > leftPage) {
            [self populatePage:--firstVisiblePage];
        }
        while (lastVisiblePage < rightPage) {
            [self populatePage:++lastVisiblePage];
        }
    }
    
    firstVisiblePage = leftPage;
    lastVisiblePage = rightPage;        
}

- (void)reloadData
{
    numberOfItems = [gridDelegate gridScrollViewNumberOfItems:self];
    numberOfPages = ceil((float)numberOfItems / (columnsPerPage * rowsPerPage));
    
    firstVisiblePage = -1;
    lastVisiblePage = -1;
    
    // Remove all existing visible views
    for (UIView *view in visibleViews) {
        [recycledViews addObject:view];
        [view removeFromSuperview];
    }
    [visibleViews removeAllObjects];

    self.contentSize = CGSizeMake(numberOfPages * self.frame.size.width, self.frame.size.height);

    [self setNeedsLayout];
}

- (UIView *)dequeueReusableSubview
{
    UIView *recycledView = [recycledViews anyObject];
    if (recycledView) {
        [[recycledView retain] autorelease];
        [recycledViews removeObject:recycledView];
    }
    
    return recycledView;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([gridDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [gridDelegate scrollViewDidScroll:scrollView];
    }
    
    [self setNeedsLayout];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([gridDelegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
        [gridDelegate scrollViewWillBeginDragging:scrollView];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if ([gridDelegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)]) {
        [gridDelegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([gridDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [gridDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    if ([gridDelegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)]) {
        [gridDelegate scrollViewWillBeginDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([gridDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [gridDelegate scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if ([gridDelegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
        [gridDelegate scrollViewDidEndScrollingAnimation:scrollView];
    }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    if ([gridDelegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)]) {
        return [gridDelegate scrollViewShouldScrollToTop:scrollView];
    }
    
    return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    if ([gridDelegate respondsToSelector:@selector(scrollViewDidScrollToTop:)]) {
        [gridDelegate scrollViewDidScrollToTop:scrollView]; 
    }
}

@end