//
//  PagingGridView.h
//  ipad
//
//  Created by Chris Haugli on 2/6/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PagingGridViewDataSource;

@interface PagingGridView : UIScrollView <UIScrollViewDelegate> {
    NSUInteger numberOfItems;
    NSUInteger numberOfPages;
    NSUInteger currentPage;
    CGSize itemSize;
    
    NSMutableIndexSet *visibleIndexes;
    NSMutableSet *visibleViews;
    NSMutableSet *recycledViews;
}

@property (nonatomic, assign) NSUInteger numberOfRows;
@property (nonatomic, assign) NSUInteger numberOfColumns;
@property (nonatomic, assign) CGSize internalPadding;
@property (nonatomic, assign) CGSize externalPadding;
@property (nonatomic, assign) IBOutlet id<PagingGridViewDataSource> dataSource;

- (void)reloadData;
- (UIView *)dequeueReusableSubview;

@end

@protocol PagingGridViewDataSource <NSObject>
- (NSUInteger)gridViewNumberOfItems:(PagingGridView *)gridView;
- (UIView *)gridView:(PagingGridView *)gridView viewForIndex:(NSUInteger)index;
@end
