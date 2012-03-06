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
    BOOL dragging;
    UIButton *stopRearrangingButton;
}

@property (nonatomic, assign) NSUInteger numberOfRows;
@property (nonatomic, assign) NSUInteger numberOfColumns;
@property (nonatomic, assign) NSUInteger numberOfPages;
@property (nonatomic, assign) NSUInteger currentPage;
@property (nonatomic, assign) CGSize internalPadding;
@property (nonatomic, assign) CGSize externalPadding;
@property (nonatomic, assign) BOOL rearranging;
@property (nonatomic, assign) IBOutlet id<PagingGridViewDataSource> dataSource;
@property (nonatomic, assign) IBOutlet id<PagingGridViewDelegate> gridDelegate;

- (PagingGridViewCell *)dequeueReusableCell;
- (PagingGridViewCell *)cellForIndex:(NSUInteger)index;
- (void)setDataSource:(id<PagingGridViewDataSource>)newDataSource animated:(BOOL)animated;
- (void)setCurrentPage:(NSUInteger)aCurrentPage animated:(BOOL)animated;
- (void)setRearranging:(BOOL)isRearranging animated:(BOOL)animated;
- (void)reloadData;
- (void)beginUpdates;
- (void)endUpdates;
- (void)insertItemAtIndex:(NSUInteger)index;
- (void)deleteItemAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)updateItemAtIndex:(NSUInteger)index;

@end

@protocol PagingGridViewDataSource <NSObject>
- (NSUInteger)gridViewNumberOfItems:(PagingGridView *)gridView;
- (PagingGridViewCell *)gridView:(PagingGridView *)gridView cellForIndex:(NSUInteger)index;
@optional
- (BOOL)gridView:(PagingGridView *)gridView canDeleteItemAtIndex:(NSUInteger)index;
- (BOOL)gridView:(PagingGridView *)gridView canRearrangeItemAtIndex:(NSUInteger)index;
- (NSUInteger)gridView:(PagingGridView *)gridView columnSpanForCellAtIndex:(NSUInteger)index;
- (NSUInteger)gridView:(PagingGridView *)gridView rowSpanForCellAtIndex:(NSUInteger)index;
@end

@protocol PagingGridViewDelegate <NSObject>
@optional
- (void)gridView:(PagingGridView *)aGridView dataSourceWillAnimate:(id<PagingGridViewDataSource>)newDataSource;
- (void)gridView:(PagingGridView *)aGridView dataSourceDidChange:(id<PagingGridViewDataSource>)newDataSource;
- (void)gridView:(PagingGridView *)gridView didSelectItemAtIndex:(NSUInteger)index;
- (void)gridView:(PagingGridView *)aGridView willDeleteItemAtIndex:(NSUInteger)index;
- (BOOL)gridView:(PagingGridView *)aGridView shouldDeleteItemAtIndex:(NSUInteger)index;
- (void)gridView:(PagingGridView *)aGridView numberOfItemsDidChange:(NSUInteger)numberOfItems;
- (void)gridViewDidBeginRearranging:(PagingGridView *)gridView;
- (void)gridView:(PagingGridView *)gridView didMoveItemAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;
- (void)gridViewDidEndRearranging:(PagingGridView *)gridView;
@end
