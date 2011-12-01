//
//  GridScrollView.m
//  ipad
//
//  Created by Chris Haugli on 11/4/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "GridScrollView.h"

@implementation GridScrollView

@synthesize numberOfColumns;
@synthesize itemSize;
@synthesize horizontalItemPadding;
@synthesize verticalItemPadding;
@synthesize gridDelegate;

- (void)setup
{
    self.delegate = self;
    
    visibleViews = [[NSMutableSet alloc] init];
    recycledViews = [[NSMutableSet alloc] init];
    
    numberOfColumns = 3;
    itemSize = CGSizeMake(0, 90);
    horizontalItemPadding = 10;
    verticalItemPadding = 10;
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

- (void)setDelegate:(id<UIScrollViewDelegate>)delegate
{
    if (delegate == self || delegate == nil) {
        [super setDelegate:delegate];
    } else {
        NSLog(@"Warning: setting scroll view delegate on GridScrollView is not supported. Use gridDelegate instead.");
        [self doesNotRecognizeSelector:_cmd];
    }
}

- (void)setNumberOfColumns:(NSUInteger)aNumberOfColumns
{
    numberOfColumns = aNumberOfColumns;
    
    if (gridDelegate) {
        [self reloadData];        
    }    
}

- (void)setItemSize:(CGSize)anItemSize
{
    itemSize = anItemSize;
    [self reloadData];
}

- (void)setGridDelegate:(id<GridScrollViewDelegate>)aGridDelegate
{
    gridDelegate = aGridDelegate;
    [self reloadData];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self reloadData];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    NSInteger firstVisibleRow = INT_MAX;
    NSInteger lastVisibleRow = INT_MIN;
    CGFloat topY = 0;
    CGFloat bottomY = 0;
    
    // Can we remove any views?
    NSMutableSet *viewsToRemove = [[NSMutableSet alloc] init];
    for (UIView *view in visibleViews) {
        if (CGRectIntersectsRect(view.frame, CGRectMake(0, self.contentOffset.y, self.frame.size.width, self.frame.size.height))) {
            NSInteger row = view.tag / resolvedNumberOfColumns;
            
            // Keep the view
            if (row < firstVisibleRow) {
                firstVisibleRow = row;
                topY = view.frame.origin.y;
            }
            if (row > lastVisibleRow) {
                lastVisibleRow = row;
                bottomY = view.frame.origin.y + view.frame.size.height + verticalItemPadding;
            }
        } else {
            // Remove it
            [recycledViews addObject:view];
            [view removeFromSuperview];
            [viewsToRemove addObject:view];
        }
    }
    [visibleViews minusSet:viewsToRemove];
    [viewsToRemove release];
    
    if (lastVisibleRow == INT_MIN) {
        lastVisibleRow = -1;
    }
    
    // Do we need to add any views?    
    while ((lastVisibleRow == -1) || (bottomY < self.contentOffset.y + self.frame.size.height && lastVisibleRow < numberOfRows - 1)) {
        lastVisibleRow++;
        for (NSUInteger column = 0; column < resolvedNumberOfColumns; column++) {
            NSUInteger index = (lastVisibleRow * resolvedNumberOfColumns + column);
            if (index < numberOfItems) {            
                UIView *view = [gridDelegate gridScrollView:self viewForItemAtIndex:index];
                view.frame = CGRectMake(round(column * (resolvedItemWidth + resolvedHorizontalItemPadding)), bottomY, resolvedItemWidth, itemSize.height);
                view.tag = index;
                [self insertSubview:view atIndex:0];
                [visibleViews addObject:view];                
            }
        }
        bottomY += itemSize.height + verticalItemPadding;
    }

    while (topY > self.contentOffset.y && firstVisibleRow > 0) {
        firstVisibleRow--;
        topY -= itemSize.height + verticalItemPadding;
        for (NSUInteger column = 0; column < resolvedNumberOfColumns; column++) {
            NSUInteger index = (firstVisibleRow * resolvedNumberOfColumns + column);            
            if (index < numberOfItems) {
                UIView *view = [gridDelegate gridScrollView:self viewForItemAtIndex:index];
                view.frame = CGRectMake(round(column * (resolvedItemWidth + resolvedHorizontalItemPadding)), topY, resolvedItemWidth, itemSize.height);
                view.tag = index;
                [self insertSubview:view atIndex:0];
                [visibleViews addObject:view];
            }
        }
    }    
}

- (void)reloadData
{
    numberOfItems = [gridDelegate gridScrollViewNumberOfItems:self];
    
    if (itemSize.width == 0) {
        resolvedNumberOfColumns = numberOfColumns;
        resolvedHorizontalItemPadding = horizontalItemPadding;
        resolvedItemWidth = (self.frame.size.width - (horizontalItemPadding * (resolvedNumberOfColumns - 1))) / resolvedNumberOfColumns;
    } else {
        resolvedNumberOfColumns = (numberOfColumns == 0 ? (self.frame.size.width + horizontalItemPadding) / (itemSize.width + horizontalItemPadding) : numberOfColumns);
        resolvedHorizontalItemPadding = (resolvedNumberOfColumns == 0 ? 0 : floor(self.frame.size.width - (itemSize.width * resolvedNumberOfColumns)) / (resolvedNumberOfColumns - 1));
        resolvedItemWidth = itemSize.width;
    }
    
    numberOfRows = ceil((float)numberOfItems / resolvedNumberOfColumns);
    
    // Remove all existing visible views
    for (UIView *view in visibleViews) {
        [recycledViews addObject:view];
        [view removeFromSuperview];
    }
    [visibleViews removeAllObjects];

    self.contentSize = CGSizeMake(self.frame.size.width, numberOfRows * itemSize.height + (numberOfRows - 1) * verticalItemPadding);
    self.contentOffset = CGPointMake(0, -self.contentInset.top);
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

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    GridScrollView *scrollView = [[GridScrollView allocWithZone:zone] init];
    scrollView.frame = self.frame;
    scrollView.numberOfColumns = self.numberOfColumns;
    scrollView.itemSize = self.itemSize;
    scrollView.verticalItemPadding = self.verticalItemPadding;
    scrollView.gridDelegate = self.gridDelegate;
    
    return scrollView;
}

@end