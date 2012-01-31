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
@synthesize headerView;
@synthesize shadowTopView;
@synthesize shadowBottomView;
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
    [headerView release];
    [shadowTopView release];
    [shadowBottomView release];
    
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
    [self reloadDataKeepOffset:YES];
}

- (void)setHeaderView:(UIView *)aHeaderView
{
    if (headerView != aHeaderView) {
        [headerView release];
        headerView = [aHeaderView retain];
    }

    CGRect frame = headerView.frame;
    frame.origin.x = 0;
    frame.origin.y = -self.contentInset.top;
    frame.size.width = self.frame.size.width;
    headerView.frame = frame;
    
    self.contentSize = CGSizeMake(self.contentSize.width, self.contentSize.height + headerView.frame.size.height);
    self.contentOffset = CGPointMake(0, headerView.frame.size.height - self.contentInset.top);
    
    [self addSubview:headerView];
}

- (CGRect)frameForIndex:(NSUInteger)index
{
    NSUInteger row = index / resolvedNumberOfColumns;
    NSUInteger column = index % resolvedNumberOfColumns;
    
    return CGRectMake(round(column * (resolvedItemWidth + resolvedHorizontalItemPadding)), 
                      round(row * (itemSize.height + verticalItemPadding)) + (headerView ? headerView.frame.size.height : 0), 
                      resolvedItemWidth, 
                      itemSize.height);
}

- (BOOL)indexIsVisible:(NSUInteger)index
{
    CGRect frame = [self frameForIndex:index];
    if (frame.origin.y > self.contentOffset.y + self.frame.size.height ||
        frame.origin.y + frame.size.height < self.contentOffset.y) {
        return NO;
    }    
    
    return YES;
}

- (void)addViewAtIndex:(NSUInteger)index
{
    if (![self indexIsVisible:index]) return;
    
    UIView *view = [gridDelegate gridScrollView:self viewForItemAtIndex:index];
    view.frame = [self frameForIndex:index];
    view.tag = index;
    [self insertSubview:view atIndex:0];
    [visibleViews addObject:view];       
}

- (BOOL)removeViewAtIndex:(NSUInteger)index
{
    UIView *viewToRemove = nil;
    for (UIView *view in visibleViews) {
        if (view.tag == index) {
            viewToRemove = view;
            break;
        }
    }
 
    if (viewToRemove) {
        [recycledViews addObject:viewToRemove];
        [viewToRemove removeFromSuperview];
        [visibleViews removeObject:viewToRemove];
        return YES;
    }
    
    return NO;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    if (updating) return;
    
    // Recalculate visible row range
    NSInteger firstVisibleRow = INT_MAX;
    NSInteger lastVisibleRow = INT_MIN;
    CGFloat topY = (headerView ? headerView.frame.size.height : 0);
    CGFloat bottomY = 0;
    
    // Can we remove any views?
    NSMutableSet *viewsToRemove = [[NSMutableSet alloc] init];
    for (UIView *view in visibleViews) {
        NSInteger row = view.tag / resolvedNumberOfColumns;

        if (CGRectIntersectsRect(view.frame, CGRectMake(0, self.contentOffset.y, self.frame.size.width, self.frame.size.height))) {            
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
            
            if ([visibleViews count] - [viewsToRemove count] == 0) {
                // We've removed all visible subviews - user is scrolling very fast
                // FIXME: Right now this causes ALL VIEWS above the current scroll position to be re-added at once, leading to memory problems.
            }
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
            if (index < numberOfItems + numberOfItemsDelta) {        
                [self addViewAtIndex:index];
            }
        }
        bottomY += itemSize.height + verticalItemPadding;
    }

    while (topY > self.contentOffset.y && firstVisibleRow > 0) {
        firstVisibleRow--;
        topY -= itemSize.height + verticalItemPadding;
        for (NSUInteger column = 0; column < resolvedNumberOfColumns; column++) {
            NSUInteger index = (firstVisibleRow * resolvedNumberOfColumns + column);            
            if (index < numberOfItems + numberOfItemsDelta) {
                [self addViewAtIndex:index];
            }
        }
    }    
}

- (void)reloadDataKeepOffset:(BOOL)keepOffset
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
    
    numberOfRows = (resolvedNumberOfColumns == 0 ? 0 : ceil((float)numberOfItems / resolvedNumberOfColumns));
    
    // Remove all existing visible views
    for (UIView *view in visibleViews) {
        [recycledViews addObject:view];
        [view removeFromSuperview];
    }
    [visibleViews removeAllObjects];

    self.contentSize = CGSizeMake(self.frame.size.width, (numberOfRows == 0 ? 0 : numberOfRows * itemSize.height + (numberOfRows - 1) * verticalItemPadding) + (headerView ? headerView.frame.size.height : 0));
    
    if (!keepOffset) {
        self.contentOffset = CGPointMake(0, (headerView ? headerView.frame.size.height - self.contentInset.top : -self.contentInset.top));
    }
    
    [self setNeedsLayout];
}

- (void)reloadData
{
    [self reloadDataKeepOffset:NO];
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

- (void)beginUpdates
{
    numberOfItemsDelta = 0;
    updating = YES;
}

- (void)endUpdates
{
    numberOfItems += numberOfItemsDelta;
    numberOfItemsDelta = 0;
    numberOfRows = ceil((float)numberOfItems / resolvedNumberOfColumns);    
    
    self.contentSize = CGSizeMake(self.frame.size.width, numberOfRows * itemSize.height + (numberOfRows - 1) * verticalItemPadding + (headerView ? headerView.frame.size.height : 0));   
    
    updating = NO;
}

- (void)insertItemAtIndex:(NSUInteger)index
{
    numberOfItemsDelta++;

    // If the item will not be visible, we don't need to do anything. Will be added once the user scrolls.
    if (![self indexIsVisible:index]) return;
    
    NSInteger indexToRemove = -1;
    if (index < numberOfItems) {
        // Shift other views down
        for (UIView *view in visibleViews) {
            if (view.tag >= index) {
                view.frame = [self frameForIndex:++view.tag];
                
                if (view.frame.origin.y > self.contentOffset.y + self.frame.size.height) {
                    indexToRemove = view.tag;
                }
            }
        }
    }
    
    [self addViewAtIndex:index];

    // Remove the view that got shifted below the screen
    if (indexToRemove >= 0) {
        [self removeViewAtIndex:indexToRemove];
    }    
}

- (void)deleteItemAtIndex:(NSUInteger)index
{
    numberOfItemsDelta--;

    // If the item is not currently visible, we don't need to do anything. It was already deleted.
    if (![self indexIsVisible:index]) return;
    
    [self removeViewAtIndex:index];

    // Shift other views up
    NSInteger lastVisibleIndex = -1;
    for (UIView *view in visibleViews) {
        if (view.tag > index) {
            view.frame = [self frameForIndex:--view.tag];
            
            if (view.tag > lastVisibleIndex) {
                lastVisibleIndex = view.tag;
            }
        }
    }
        
    // Might need to add a view to the end of the last visible column
    if (lastVisibleIndex >= 0 && lastVisibleIndex + 1 < numberOfItems + numberOfItemsDelta && !replacing) {
        [self addViewAtIndex:lastVisibleIndex + 1];
    }
}

- (void)updateItemAtIndex:(NSUInteger)index
{
    // If the item is not visible, we don't need to do anything. Will be updated once the user scrolls.
    if (![self indexIsVisible:index]) return;
    
    replacing = YES;
    if ([self removeViewAtIndex:index]) {
        [self addViewAtIndex:index];
    }
    replacing = NO;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([gridDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [gridDelegate scrollViewDidScroll:scrollView];
    }
    
    shadowTopView.alpha = MIN(1, MAX(0, scrollView.contentOffset.y / 10));
    shadowBottomView.alpha = MIN(1, MAX(0, (scrollView.contentSize.height - (scrollView.contentOffset.y + scrollView.frame.size.height)) / 10));
    
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