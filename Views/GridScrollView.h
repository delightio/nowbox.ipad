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
    NSUInteger numberOfPages;
    NSInteger firstVisiblePage;
    NSInteger lastVisiblePage;
    
    NSMutableSet *visibleViews;
    NSMutableSet *recycledViews;
}

@property (nonatomic, assign) NSInteger rowsPerPage;
@property (nonatomic, assign) NSInteger columnsPerPage;
@property (nonatomic, assign) CGFloat pageMarginLeft;
@property (nonatomic, assign) CGFloat pageMarginRight;
@property (nonatomic, assign) IBOutlet id<GridScrollViewDelegate> gridDelegate;

- (void)reloadData;
- (UIView *)dequeueReusableSubview;

@end

@protocol GridScrollViewDelegate <UIScrollViewDelegate>
- (NSUInteger)gridScrollViewNumberOfItems:(GridScrollView *)gridScrollView;
- (UIView *)gridScrollView:(GridScrollView *)gridScrollView viewForItemAtIndex:(NSUInteger)index;
@end