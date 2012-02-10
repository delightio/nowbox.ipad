//
//  PagingGridView.h
//  ipad
//
//  Created by Chris Haugli on 2/6/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PagingGridViewCell.h"

@protocol PagingGridViewDataSource;
@protocol PagingGridViewDelegate;

@interface PagingGridView : UIScrollView <PagingGridViewCellDelegate, UIScrollViewDelegate> {
    NSUInteger numberOfItems;
    CGSize itemSize;
    
    NSMutableIndexSet *visibleIndexes;
    NSMutableSet *visibleViews;
    NSMutableSet *recycledViews;
    
    NSTimer *rearrangePageSwitchTimer;
    BOOL rearranging;
    BOOL dragging;
    UIButton *stopRearrangingButton;
}

@property (nonatomic, assign) NSUInteger numberOfRows;
@property (nonatomic, assign) NSUInteger numberOfColumns;
@property (nonatomic, assign) NSUInteger numberOfPages;
@property (nonatomic, assign) NSUInteger currentPage;
@property (nonatomic, assign) CGSize internalPadding;
@property (nonatomic, assign) CGSize externalPadding;
@property (nonatomic, assign) IBOutlet id<PagingGridViewDataSource> dataSource;
@property (nonatomic, assign) IBOutlet id<PagingGridViewDelegate> gridDelegate;

- (PagingGridViewCell *)dequeueReusableCell;
- (void)reloadData;
- (void)beginUpdates;
- (void)endUpdates;
- (void)insertItemAtIndex:(NSUInteger)index;
- (void)deleteItemAtIndex:(NSUInteger)index;
- (void)updateItemAtIndex:(NSUInteger)index;

@end

@protocol PagingGridViewDataSource <NSObject>
- (NSUInteger)gridViewNumberOfItems:(PagingGridView *)gridView;
- (PagingGridViewCell *)gridView:(PagingGridView *)gridView cellForIndex:(NSUInteger)index;
@end

@protocol PagingGridViewDelegate <NSObject>
@optional
- (void)gridView:(PagingGridView *)gridView didSelectItemAtIndex:(NSUInteger)index;
- (void)gridViewDidBeginRearranging:(PagingGridView *)gridView;
- (void)gridView:(PagingGridView *)gridView didMoveItemAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;
- (void)gridViewDidEndRearranging:(PagingGridView *)gridView;
@end
