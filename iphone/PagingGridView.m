//
//  PagingGridView.m
//  ipad
//
//  Created by Chris Haugli on 2/6/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "PagingGridView.h"

@implementation PagingGridView

@synthesize numberOfRows;
@synthesize numberOfColumns;
@synthesize numberOfPages;
@synthesize currentPage;
@synthesize internalPadding;
@synthesize externalPadding;
@synthesize dataSource;
@synthesize gridDelegate;

- (void)setup
{
    numberOfColumns = 2;
    numberOfRows = 3;
    internalPadding = CGSizeMake(7, 7);
    externalPadding = CGSizeMake(7, 0);
    
    visibleIndexes = [[NSMutableIndexSet alloc] init];
    visibleViews = [[NSMutableSet alloc] init];
    recycledViews = [[NSMutableSet alloc] init];
    
    self.pagingEnabled = YES;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.delegate = self;
    self.clipsToBounds = NO;
    
    [self reloadData];
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
    [visibleIndexes release];
    [visibleViews release];
    [recycledViews release];
    
    [super dealloc];
}

- (void)setDataSource:(id<PagingGridViewDataSource>)aDataSource
{
    if (dataSource != aDataSource) {
        dataSource = aDataSource;
        [self reloadData];
    }
}

- (void)setNumberOfRows:(NSUInteger)aNumberOfRows
{
    if (numberOfRows != aNumberOfRows) {
        numberOfRows = aNumberOfRows;
        [self reloadData];
    }
}

- (void)setNumberOfColumns:(NSUInteger)aNumberOfColumns
{
    if (numberOfColumns != aNumberOfColumns) {
        numberOfColumns = aNumberOfColumns;
        [self reloadData];
    }
}

- (void)setInternalPadding:(CGSize)anInternalPadding
{
    if (!CGSizeEqualToSize(internalPadding, anInternalPadding)) {
        internalPadding = anInternalPadding;
        [self reloadData];
    }
}

- (void)setExternalPadding:(CGSize)anExternalPadding
{
    if (!CGSizeEqualToSize(externalPadding, anExternalPadding)) {
        externalPadding = anExternalPadding;
        [self reloadData];
    }
}

- (void)setDelegate:(id<UIScrollViewDelegate>)delegate
{
    if (delegate == self) {
        [super setDelegate:delegate];        
    } else {
        NSLog(@"PagingGridView does not expose the UIScrollView delegate. Use gridDelegate instead.");
        [self doesNotRecognizeSelector:_cmd];
    }
}

- (void)setCurrentPage:(NSUInteger)aCurrentPage
{
    currentPage = aCurrentPage;
    [self setContentOffset:CGPointMake(currentPage * self.frame.size.width, 0) animated:YES];
}

- (CGRect)frameForIndex:(NSUInteger)index
{
    NSUInteger page = index / (numberOfRows * numberOfColumns);
    NSUInteger pageOffset = index % (numberOfRows * numberOfColumns);
    NSUInteger row = pageOffset / numberOfColumns;
    NSUInteger column = pageOffset % numberOfColumns;
    
    return CGRectMake(page * self.frame.size.width + externalPadding.width + column * (itemSize.width + internalPadding.width),
                      externalPadding.height + row * (itemSize.height + internalPadding.height), 
                      itemSize.width,
                      itemSize.height);
}

- (NSInteger)repositioningIndexForFrame:(CGRect)frame
{
    CGPoint center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    NSInteger page = floor(center.x / self.frame.size.width);
    NSInteger column = floor((center.x - page * self.frame.size.width - externalPadding.width) / (itemSize.width + internalPadding.width));
    NSInteger row = floor((center.y - externalPadding.height) / (itemSize.height + internalPadding.height));
    
    if (column < 0) column = 0;
    if (row < 0) row = 0;
    
    NSInteger index = page * (numberOfRows * numberOfColumns) + (row * numberOfColumns) + column;
    
    // Make sure we're still on the same page
    if (index >= 0 && index < numberOfItems && index >= page * numberOfRows * numberOfColumns && index < (page + 1) * numberOfRows * numberOfColumns) {
        return index;
    }
    
    return -1;
}

- (void)reloadData
{
    if (!dataSource) return;
    
    numberOfItems = [dataSource gridViewNumberOfItems:self];
    numberOfPages = numberOfItems / (numberOfRows * numberOfColumns);
    if (numberOfItems % (numberOfRows * numberOfColumns) > 0) {
        numberOfPages++;
    }
    
    itemSize = CGSizeMake((self.frame.size.width - 2 * externalPadding.width - (numberOfColumns - 1) * internalPadding.width) / numberOfColumns, 
                          (self.frame.size.height - 2 * externalPadding.height - (numberOfRows - 1) * internalPadding.height) / numberOfRows);
    
    self.contentSize = CGSizeMake(numberOfPages * self.frame.size.width, self.frame.size.height);
    
    // Remove all visible views
    for (UIView *view in visibleViews) {
        [view removeFromSuperview];
        [recycledViews addObject:view];
    }
    [visibleViews removeAllObjects];
    [visibleIndexes removeAllIndexes];
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect visibleRect = CGRectMake(self.contentOffset.x, self.contentOffset.y, self.frame.size.width, self.frame.size.height);
    
    // Can we remove any views that are offscreen?
    NSMutableSet *viewsToRemove = [NSMutableSet set];
    for (PagingGridViewCell *view in visibleViews) {
        // If a subview is being dragged, keep it's position relative to the superview
        if ([view isDraggable]) {
            CGPoint lastDragLocation = ((PagingGridViewCell *)view).lastDragLocation;
            view.center = CGPointMake(lastDragLocation.x + self.contentOffset.x, lastDragLocation.y + self.contentOffset.y);
            [self bringSubviewToFront:view];
        } else if (!CGRectIntersectsRect(view.frame, visibleRect)) {
            NSUInteger index = view.tag;
            [viewsToRemove addObject:view];
            [view removeFromSuperview];
            [visibleIndexes removeIndex:index];
            [recycledViews addObject:view];
        }
    }
    [visibleViews minusSet:viewsToRemove];
    
    // Do we need to add any views that came onscreen?
    CGFloat currentPageFloat = MAX(0, self.contentOffset.x / self.frame.size.width);
    NSUInteger firstIndex = floor(currentPageFloat) * (numberOfRows * numberOfColumns);
    NSUInteger lastIndex = (ceil(currentPageFloat) + 1) * (numberOfRows * numberOfColumns);
    
    for (NSUInteger i = firstIndex; i < lastIndex && i < numberOfItems; i++) {
        CGRect viewFrame = [self frameForIndex:i];
        if (CGRectIntersectsRect(viewFrame, visibleRect) && ![visibleIndexes containsIndex:i]) {
            PagingGridViewCell *view = [dataSource gridView:self cellForIndex:i];
            view.frame = viewFrame;
            view.tag = i;
            [visibleViews addObject:view];
            [visibleIndexes addIndex:i];
            [self addSubview:view];
        }
    }
}

- (PagingGridViewCell *)dequeueReusableCell
{
    PagingGridViewCell *view = [[[recycledViews anyObject] retain] autorelease];
    if (view) {
        [recycledViews removeObject:view];
    }
    
    return view;
}

- (void)repositionView:(UIView *)repositioningView fromIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex animated:(BOOL)animated
{
    void (^repositionViews)(void) = ^{ 
        for (UIView *view in visibleViews) {
            NSUInteger index = view.tag;
            if (view != repositioningView && ((index > oldIndex && index <= newIndex) || (index >= newIndex && index < oldIndex))) {
                // This view is affected by the repositioning
                if (newIndex > oldIndex) {
                    index--;
                } else {
                    index++;
                }
                
                view.tag = index;
                view.frame = [self frameForIndex:index];                
            }
        }
    };
    if (animated) {
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
                         animations:repositionViews
                         completion:^(BOOL finished){
                         }];
    } else {
        repositionViews();
    }
    
    repositioningView.tag = newIndex;
    
    // Update the visible indexes
    [visibleIndexes removeAllIndexes];
    for (UIView *view in visibleViews) {
        [visibleIndexes addIndex:view.tag];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    currentPage = MAX(0, round(scrollView.contentOffset.x / scrollView.frame.size.width));
    
    if ([gridDelegate respondsToSelector:@selector(gridViewDidScroll:)]) {
        [gridDelegate gridViewDidScroll:self];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([gridDelegate respondsToSelector:@selector(gridViewWillBeginDragging:)]) {
        [gridDelegate gridViewWillBeginDragging:self];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if ([gridDelegate respondsToSelector:@selector(gridViewDidEndScrollingAnimation:)]) {
        [gridDelegate gridViewDidEndScrollingAnimation:self];
    }
}

@end
