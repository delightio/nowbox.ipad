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
    dataSource = aDataSource;
    [self reloadData];
}

- (void)setNumberOfRows:(NSUInteger)aNumberOfRows
{
    numberOfRows = aNumberOfRows;
    [self reloadData];
}

- (void)setNumberOfColumns:(NSUInteger)aNumberOfColumns
{
    numberOfColumns = aNumberOfColumns;
    [self reloadData];
}

- (void)setInternalPadding:(CGSize)anInternalPadding
{
    internalPadding = anInternalPadding;
    [self reloadData];
}

- (void)setExternalPadding:(CGSize)anExternalPadding
{
    externalPadding = anExternalPadding;
    [self reloadData];
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

- (NSInteger)indexForFrame:(CGRect)frame
{
    NSUInteger page = floor(frame.origin.x / self.frame.size.width);
    NSUInteger column = round((frame.origin.x - page * self.frame.size.width - externalPadding.width) / (itemSize.width + internalPadding.width));
    NSUInteger row = round((frame.origin.y - externalPadding.height) / (itemSize.height + internalPadding.height));
    
    return page * (numberOfRows * numberOfColumns) + (row * numberOfColumns) + column;
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
    for (UIView *view in visibleViews) {
        if (!CGRectIntersectsRect(view.frame, visibleRect)) {
            NSUInteger index = [self indexForFrame:view.frame];
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
            UIView *view = [dataSource gridView:self viewForIndex:i];
            view.frame = viewFrame;
            [visibleViews addObject:view];
            [visibleIndexes addIndex:i];
            [self addSubview:view];
        }
    }
}

- (UIView *)dequeueReusableSubview
{
    UIView *view = [[[recycledViews anyObject] retain] autorelease];
    if (view) {
        [recycledViews removeObject:view];
    }
    
    return view;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    currentPage = MAX(0, round(scrollView.contentOffset.x / scrollView.frame.size.width));
    [self setNeedsLayout];    
    
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

@end