//
//  CustomPageControl.h
//  ipad
//
//  Created by Chris Haugli on 2/6/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CustomPageControlDelegate;

@interface CustomPageControl : UIView {
    UIImage *dotImage;
    UIImage *filledDotImage;
    CGFloat dotWidth;
    CGFloat overallWidth;
    CGFloat touchStartX;
}

@property (nonatomic, assign) NSUInteger numberOfPages;
@property (nonatomic, assign) NSUInteger currentPage;
@property (nonatomic, assign) CGFloat dotSpacing;
@property (nonatomic, assign) IBOutlet id<CustomPageControlDelegate> delegate;

@end

@protocol CustomPageControlDelegate <NSObject>
- (void)pageControl:(CustomPageControl *)pageControl didSelectPageAtIndex:(NSUInteger)index;
@optional
- (BOOL)pageControl:(CustomPageControl *)pageControl shouldSelectPageAtIndex:(NSUInteger)index;
@end