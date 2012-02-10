//
//  PagingGridView.m
//  ipad
//
//  Created by Chris Haugli on 2/6/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "PagingGridView.h"

#define kRearrangePageSwitchDistance 50
#define kRearrangePageSwitchDuration 1.0

@interface PagingGridView (Private)
- (CGRect)frameForIndex:(NSUInteger)index;
- (NSInteger)repositioningIndexForFrame:(CGRect)frame;
- (void)repositionView:(UIView *)view fromIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex animated:(BOOL)animated;
@end

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
    [rearrangePageSwitchTimer invalidate];

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
    NSInteger page = currentPage;
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

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect visibleRect = CGRectMake(self.contentOffset.x, self.contentOffset.y, self.frame.size.width, self.frame.size.height);
    
    // Can we remove any views that are offscreen?
    NSMutableSet *viewsToRemove = [NSMutableSet set];
    for (PagingGridViewCell *view in visibleViews) {
        // If a subview is being dragged, keep it's position relative to the superview
        if ([view isDraggable]) {
            view.center = CGPointMake(view.lastDragLocation.x + self.contentOffset.x, view.lastDragLocation.y + self.contentOffset.y);
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
            view.delegate = self;
            [visibleViews addObject:view];
            [visibleIndexes addIndex:i];
            [self addSubview:view];
        }
    }
    
    currentPage = MAX(0, round(self.contentOffset.x / self.frame.size.width));
}

- (PagingGridViewCell *)dequeueReusableCell
{
    PagingGridViewCell *view = [[[recycledViews anyObject] retain] autorelease];
    if (view) {
        [recycledViews removeObject:view];
    }
    
    return view;
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

- (void)rearrangePageSwitchTimerFired:(NSTimer *)timer
{
    rearrangePageSwitchTimer = nil;
    CGPoint touchLocation = [[[timer userInfo] objectForKey:@"touchLocation"] CGPointValue];
    
    if (touchLocation.x - self.contentOffset.x < kRearrangePageSwitchDistance && currentPage > 0) {
        // Switch page left
        self.currentPage = currentPage - 1;
    } else if (touchLocation.x - self.contentOffset.x > self.frame.size.width - kRearrangePageSwitchDistance && currentPage + 1 < numberOfPages) {
        // Switch page right
        self.currentPage = currentPage + 1;    
    }
}

#pragma mark - Updates

- (void)beginUpdates
{

}

- (void)endUpdates
{
    if (currentPage > numberOfPages) {
        self.currentPage = numberOfPages - 1;
    }
}

- (void)insertItemAtIndex:(NSUInteger)index
{
    // Bump views that come after down by one
    for (PagingGridViewCell *cell in visibleViews) {
        if (cell.tag >= index) {
            cell.frame = [self frameForIndex:++cell.tag];
        }
    }
    
    // Update visible indexes
    [visibleIndexes removeAllIndexes];
    for (PagingGridViewCell *cell in visibleViews) {
        [visibleIndexes addIndex:cell.tag];
    }
    
    numberOfItems++;
    numberOfPages = numberOfItems / (numberOfRows * numberOfColumns);

    [self setNeedsLayout];
}

- (void)deleteItemAtIndex:(NSUInteger)index
{
    PagingGridViewCell *cellToRemove = nil;
    
    // Bump views that come after up by one
    for (PagingGridViewCell *cell in visibleViews) {
        if (cell.tag == index) {
            cellToRemove = cell;
        } else {
            cell.frame = [self frameForIndex:--cell.tag];
        }
    }
    
    if (cellToRemove) {
        [cellToRemove removeFromSuperview];
        [visibleViews removeObject:cellToRemove];
    }
    
    // Update visible indexes
    [visibleIndexes removeAllIndexes];
    for (PagingGridViewCell *cell in visibleViews) {
        [visibleIndexes addIndex:cell.tag];
    }

    numberOfItems--;
    numberOfPages = numberOfItems / (numberOfRows * numberOfColumns);

    [self setNeedsLayout];    
}

- (void)updateItemAtIndex:(NSUInteger)index
{
    PagingGridViewCell *cellToRemove = nil;
    for (PagingGridViewCell *cell in visibleViews) {
        if (cell.tag == index) {
            cellToRemove = cell;
            break;
        }
    }
    
    if (cellToRemove) {
        [cellToRemove removeFromSuperview];
        [visibleViews removeObject:cellToRemove];
        
        PagingGridViewCell *view = [dataSource gridView:self cellForIndex:index];
        view.frame = [self frameForIndex:index];
        view.tag = index;
        view.delegate = self;
        [visibleViews addObject:view];
        [self addSubview:view];
    }
}

#pragma mark - PagingGridViewCellDelegate

- (void)gridViewCellDidTap:(PagingGridViewCell *)gridViewCell
{
    NSUInteger index = gridViewCell.tag;
    if ([gridDelegate respondsToSelector:@selector(gridView:didSelectItemAtIndex:)]) {
        [gridDelegate gridView:self didSelectItemAtIndex:index];
    }
}

- (void)gridViewCellDidPressAndHold:(PagingGridViewCell *)gridViewCell
{
    self.scrollEnabled = NO;
    gridViewCell.lastDragLocation = CGPointMake(gridViewCell.center.x - self.contentOffset.x, gridViewCell.center.y - self.contentOffset.y);
    [gridViewCell setDraggable:YES animated:YES];
    
    if ([gridDelegate respondsToSelector:@selector(gridViewDidBeginRearranging:)]) {
        [gridDelegate gridViewDidBeginRearranging:self];
    }
}

- (void)gridViewCellDidStartDragging:(PagingGridViewCell *)gridViewCell
{
    
}

- (void)gridViewCellDidEndDragging:(PagingGridViewCell *)gridViewCell
{
    NSUInteger index = gridViewCell.tag;
    [rearrangePageSwitchTimer invalidate];
    rearrangePageSwitchTimer = nil;
    
    [gridViewCell setDraggable:NO animated:YES];
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         gridViewCell.frame = [self frameForIndex:index];
                     }
                     completion:^(BOOL finished){
                         self.scrollEnabled = YES;     
                         
                         if ([gridDelegate respondsToSelector:@selector(gridViewDidEndRearranging:)]) {
                             [gridDelegate gridViewDidEndRearranging:self];
                         }
                     }];
}

- (void)gridViewCell:(PagingGridViewCell *)gridViewCell didDragToCenter:(CGPoint)center touchLocation:(CGPoint)touchLocation
{        
    gridViewCell.lastDragLocation = CGPointMake(center.x - self.contentOffset.x, center.y - self.contentOffset.y);
    
    if ((touchLocation.x - self.contentOffset.x < kRearrangePageSwitchDistance && currentPage > 0) || 
        (touchLocation.x - self.contentOffset.x > self.frame.size.width - kRearrangePageSwitchDistance && currentPage + 1 < numberOfPages)) {
        // Close to left or right edge and page switch possible
        if (!rearrangePageSwitchTimer) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSValue valueWithCGPoint:touchLocation] forKey:@"touchLocation"];
            rearrangePageSwitchTimer = [NSTimer scheduledTimerWithTimeInterval:kRearrangePageSwitchDuration target:self selector:@selector(rearrangePageSwitchTimerFired:) userInfo:userInfo repeats:NO];
        }
        
    } else {    
        if (rearrangePageSwitchTimer) {
            // Cancel any pending page switch action - we moved away from the edge
            [rearrangePageSwitchTimer invalidate];
            rearrangePageSwitchTimer = nil;
        }
        
        // Reposition the view
        NSUInteger oldIndex = gridViewCell.tag;
        NSInteger newIndex = [self repositioningIndexForFrame:gridViewCell.frame];
        
        if (newIndex != oldIndex && newIndex >= 0) {
            [self repositionView:gridViewCell fromIndex:oldIndex toIndex:newIndex animated:YES];
            if ([gridDelegate respondsToSelector:@selector(gridView:didMoveItemAtIndex:toIndex:)]) {
                [gridDelegate gridView:self didMoveItemAtIndex:oldIndex toIndex:newIndex];
            }
        }
    }    
}

@end
