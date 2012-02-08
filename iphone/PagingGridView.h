//
//  PagingGridView.h
//  ipad
//
//  Created by Chris Haugli on 2/6/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PagingGridViewDataSource;
@protocol PagingGridViewDelegate;

@interface PagingGridView : UIScrollView <UIScrollViewDelegate> {
    NSUInteger numberOfItems;
    NSUInteger currentPage;
    CGSize itemSize;
    
    NSMutableIndexSet *visibleIndexes;
    NSMutableSet *visibleViews;
    NSMutableSet *recycledViews;
}

@property (nonatomic, assign) NSUInteger numberOfRows;
@property (nonatomic, assign) NSUInteger numberOfColumns;
@property (nonatomic, assign) NSUInteger numberOfPages;
@property (nonatomic, assign) CGSize internalPadding;
@property (nonatomic, assign) CGSize externalPadding;
@property (nonatomic, assign) IBOutlet id<PagingGridViewDataSource> dataSource;
@property (nonatomic, assign) IBOutlet id<PagingGridViewDelegate> gridDelegate;

- (void)reloadData;
- (UIView *)dequeueReusableSubview;
- (CGRect)frameForIndex:(NSUInteger)index;
- (NSInteger)indexForFrame:(CGRect)frame;
- (void)repositionView:(UIView *)view fromIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex animated:(BOOL)animated;

@end

@protocol PagingGridViewDataSource <NSObject>
- (NSUInteger)gridViewNumberOfItems:(PagingGridView *)gridView;
- (UIView *)gridView:(PagingGridView *)gridView viewForIndex:(NSUInteger)index;
@end

@protocol PagingGridViewDelegate <NSObject>
@optional
- (void)gridViewDidScroll:(PagingGridView *)gridView;
- (void)gridViewWillBeginDragging:(PagingGridView *)gridView;
- (void)gridViewDidEndScrollingAnimation:(PagingGridView *)gridView;
@end
