//
//  GridScrollView.h
//  ipad
//
//  Created by Chris Haugli on 11/4/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GridScrollViewDelegate;

@interface GridScrollView : UIScrollView <UIScrollViewDelegate> {
    NSUInteger numberOfItems;
    NSInteger numberOfItemsDelta;
    NSUInteger numberOfRows;
    
    // If itemSize.width == 0, item width is auto. Otherwise, horizontal item padding is auto.
    CGFloat resolvedItemWidth;
    CGFloat resolvedHorizontalItemPadding;
    NSUInteger resolvedNumberOfColumns;
    
    NSMutableSet *visibleViews;
    NSMutableSet *recycledViews;
}

@property (nonatomic, assign) NSUInteger numberOfColumns;
@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, assign) CGFloat horizontalItemPadding;
@property (nonatomic, assign) CGFloat verticalItemPadding;
@property (nonatomic, assign) IBOutlet id<GridScrollViewDelegate> gridDelegate;

- (void)reloadData;
- (UIView *)dequeueReusableSubview;
- (void)insertItemAtIndex:(NSUInteger)index;
- (void)deleteItemAtIndex:(NSUInteger)index;
- (void)updateItemAtIndex:(NSUInteger)index;
- (void)beginUpdates;
- (void)endUpdates;

@end

@protocol GridScrollViewDelegate <UIScrollViewDelegate>
- (NSUInteger)gridScrollViewNumberOfItems:(GridScrollView *)gridScrollView;
- (UIView *)gridScrollView:(GridScrollView *)gridScrollView viewForItemAtIndex:(NSUInteger)index;
@end