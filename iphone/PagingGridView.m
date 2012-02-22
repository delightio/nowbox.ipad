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
- (PagingGridViewCell *)addCellAtIndex:(NSUInteger)index;
- (void)updateNumberOfPages;
@end

@implementation PagingGridView

@synthesize numberOfRows;
@synthesize numberOfColumns;
@synthesize numberOfPages;
@synthesize currentPage;
@synthesize internalPadding;
@synthesize externalPadding;
@synthesize rearranging;
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

#pragma mark - UIView methods

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

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect visibleRect = CGRectMake(self.contentOffset.x, self.contentOffset.y, self.frame.size.width, self.frame.size.height);
    
    // Can we remove any views that are offscreen?
    NSMutableSet *viewsToRemove = [NSMutableSet set];
    for (PagingGridViewCell *view in visibleViews) {
        // If a subview is being dragged, keep it's position relative to the superview
        if ([view isDragging]) {
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
            [self addCellAtIndex:i];
        }
    }
    
    currentPage = MAX(0, round(self.contentOffset.x / self.frame.size.width));
}

#pragma mark - Properties

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

- (void)setRearranging:(BOOL)isRearranging
{
    rearranging = isRearranging;
    
    for (PagingGridViewCell *cell in visibleViews) {
        if (rearranging) {
            cell.lastDragLocation = CGPointMake(cell.center.x - self.contentOffset.x, cell.center.y - self.contentOffset.y);
        }
        [cell setEditing:rearranging animated:YES];
    }
    
    if (rearranging) {
        if (!stopRearrangingButton) {
            // Put an invisible button on the last page to intercept any touch events in empty space
            stopRearrangingButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [stopRearrangingButton addTarget:self action:@selector(stopRearranging:) forControlEvents:UIControlEventTouchUpInside];
            stopRearrangingButton.frame = CGRectMake(self.contentSize.width - self.frame.size.width, 0, self.frame.size.width, self.frame.size.height);
            [self insertSubview:stopRearrangingButton atIndex:0];
        }
        
        if ([gridDelegate respondsToSelector:@selector(gridViewDidBeginRearranging:)]) {
            [gridDelegate gridViewDidBeginRearranging:self];
        }
    } else {
        [stopRearrangingButton removeFromSuperview];
        stopRearrangingButton = nil;
        
        if ([gridDelegate respondsToSelector:@selector(gridViewDidEndRearranging:)]) {
            [gridDelegate gridViewDidEndRearranging:self];
        }
    }
}

#pragma mark - Private methods

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

- (PagingGridViewCell *)addCellAtIndex:(NSUInteger)index
{    
    PagingGridViewCell *view = [dataSource gridView:self cellForIndex:index];
    view.frame = [self frameForIndex:index];
    view.tag = index;
    view.delegate = self;
    view.editing = rearranging;
    [visibleViews addObject:view];
    [visibleIndexes addIndex:index];
    [self addSubview:view];    
    
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
                            options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
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

- (void)updateNumberOfPages
{
    numberOfPages = numberOfItems / (numberOfRows * numberOfColumns);
    if (numberOfItems % (numberOfRows * numberOfColumns) > 0) {
        numberOfPages++;
    }
    
    self.contentSize = CGSizeMake(numberOfPages * self.frame.size.width, self.frame.size.height);
    
    if (currentPage >= numberOfPages && currentPage > 0) {
        self.currentPage = currentPage - 1;
    }
}

- (void)stopRearranging:(id)sender
{
    if (!dragging) {
        [self setRearranging:NO];
    }
}

#pragma mark - Public methods

- (PagingGridViewCell *)dequeueReusableCell
{
    PagingGridViewCell *view = [[[recycledViews anyObject] retain] autorelease];
    if (view) {
        [recycledViews removeObject:view];
        [view.activityIndicator stopAnimating];
    }
    
    return view;
}

- (PagingGridViewCell *)cellForIndex:(NSUInteger)index
{
    for (PagingGridViewCell *cell in visibleViews) {
        if (cell.tag == index) {
            return cell;
        }
    }
    
    return nil;
}

- (void)reloadData
{
    if (!dataSource) return;
    
    numberOfItems = [dataSource gridViewNumberOfItems:self];
    [self updateNumberOfPages];
    
    itemSize = CGSizeMake(round((self.frame.size.width - 2 * externalPadding.width - (numberOfColumns - 1) * internalPadding.width) / numberOfColumns), 
                          round((self.frame.size.height - 2 * externalPadding.height - (numberOfRows - 1) * internalPadding.height) / numberOfRows));
    
    
    // Remove all visible views
    for (UIView *view in visibleViews) {
        [view removeFromSuperview];
        [recycledViews addObject:view];
    }
    [visibleViews removeAllObjects];
    [visibleIndexes removeAllIndexes];
    
    [self setNeedsLayout];
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
    [self updateNumberOfPages];
    [self setNeedsLayout];
}

- (void)deleteItemAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    if ([gridDelegate respondsToSelector:@selector(gridView:willDeleteItemAtIndex:)]) {
        [gridDelegate gridView:self willDeleteItemAtIndex:index];
    }
    
    PagingGridViewCell *cellToRemove = nil;
    
    // Add the subview on the next page which will be bumped to this page
    NSUInteger page = index / (numberOfRows * numberOfColumns);
    NSUInteger nextIndex = (page + 1) * (numberOfRows * numberOfColumns) - 1;
    if (nextIndex < numberOfItems - 1) {
        PagingGridViewCell *cell = [self addCellAtIndex:nextIndex];
        cell.tag++;
        // Animate it in from the side rather than from the top
        cell.frame = [self frameForIndex:(cell.tag + (numberOfRows - 1) * numberOfColumns)];
    }
    
    // Bump views that come after up by one
    for (PagingGridViewCell *cell in visibleViews) {
        if (cell.tag == index) {
            cellToRemove = cell;
        } else if (cell.tag > index) {
            cell.tag--;
            
            if (animated) {
                [UIView animateWithDuration:0.3
                                 animations:^{
                                     cell.frame = [self frameForIndex:cell.tag];                                     
                                 }];
            } else {
                cell.frame = [self frameForIndex:cell.tag];
            }
        }
    }
    
    void (^removeCell)(BOOL) = ^(BOOL finished){        
        [cellToRemove removeFromSuperview];    
        cellToRemove.alpha = 1;
        [recycledViews addObject:cellToRemove];
        [visibleViews removeObject:cellToRemove];
        
        // Update visible indexes
        [visibleIndexes removeAllIndexes];
        for (PagingGridViewCell *cell in visibleViews) {
            [visibleIndexes addIndex:cell.tag];
        }
        
        numberOfItems--;
        [self updateNumberOfPages];
        
        [self setNeedsLayout];   
        
        if ([gridDelegate respondsToSelector:@selector(gridView:didDeleteItemAtIndex:)]) {
            [gridDelegate gridView:self didDeleteItemAtIndex:index];
        }
    };
    
    // Fade out the cell being deleted
    if (animated) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             cellToRemove.alpha = 0;
                         }
                         completion:removeCell];
    } else {
        removeCell(YES);
    }    
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
        
        [self addCellAtIndex:index];
    }
}

#pragma mark - PagingGridViewCellDelegate

- (void)gridViewCellDidTap:(PagingGridViewCell *)gridViewCell
{
    if (dragging) return;
    
    if (rearranging) {
        // Make the cells non-draggable again
        [self setRearranging:NO];
    } else {
        // Selected an item
        NSUInteger index = gridViewCell.tag;
        if ([gridDelegate respondsToSelector:@selector(gridView:didSelectItemAtIndex:)]) {
            [gridDelegate gridView:self didSelectItemAtIndex:index];
        }
    }
}

- (void)gridViewCellDidPressAndHold:(PagingGridViewCell *)gridViewCell
{
    [self setRearranging:YES];
}

- (BOOL)gridViewCellShouldShowDeleteButton:(PagingGridViewCell *)gridViewCell
{
    if ([dataSource respondsToSelector:@selector(gridView:canDeleteItemAtIndex:)] && [dataSource gridView:self canDeleteItemAtIndex:gridViewCell.tag]) {
        return YES;
    }
    
    return NO;
}

- (void)gridViewCellDidPressDeleteButton:(PagingGridViewCell *)gridViewCell
{    
    BOOL shouldDelete = YES;
    if ([gridDelegate respondsToSelector:@selector(gridView:shouldDeleteItemAtIndex:)]) {
        shouldDelete = [gridDelegate gridView:self shouldDeleteItemAtIndex:gridViewCell.tag];
    }
    
    if (shouldDelete) {    
        [self beginUpdates];
        [self deleteItemAtIndex:gridViewCell.tag animated:YES];
        [self endUpdates];
    } else {
        [gridViewCell.activityIndicator startAnimating];
    }
}

- (BOOL)gridViewCellShouldStartDragging:(PagingGridViewCell *)gridViewCell
{
    return !dragging;
}

- (void)gridViewCellDidStartDragging:(PagingGridViewCell *)gridViewCell
{
    self.scrollEnabled = NO;
    dragging = YES;
}

- (void)gridViewCellDidEndDragging:(PagingGridViewCell *)gridViewCell
{
    NSUInteger index = gridViewCell.tag;
    [rearrangePageSwitchTimer invalidate];
    rearrangePageSwitchTimer = nil;
    
    dragging = NO;
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         gridViewCell.frame = [self frameForIndex:index];
                     }
                     completion:^(BOOL finished){
                         self.scrollEnabled = YES;
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
