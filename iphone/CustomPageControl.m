//
//  CustomPageControl.m
//  ipad
//
//  Created by Chris Haugli on 2/6/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "CustomPageControl.h"

#define kMinSwipeDistance 30

@implementation CustomPageControl

@synthesize numberOfPages;
@synthesize currentPage;
@synthesize dotSpacing;
@synthesize delegate;

- (void)setup
{
    numberOfPages = 1;
    dotSpacing = 6;  

    dotImage = [[UIImage imageNamed:@"phone_grid_dot.png"] retain];
    filledDotImage = [[UIImage imageNamed:@"phone_grid_dot_filled.png"] retain];
    dotWidth = dotImage.size.width;
    
    self.clearsContextBeforeDrawing = YES;
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
    [dotImage release];
    [filledDotImage release];
    
    [super dealloc];
}

- (void)drawRect:(CGRect)rect
{
    if (numberOfPages <= 1) return;
    
    overallWidth = (dotWidth + dotSpacing) * numberOfPages - dotSpacing;
    
    CGFloat startX = (self.frame.size.width - overallWidth) / 2;
    CGFloat y = (self.frame.size.height - dotImage.size.height) / 2;
    
    for (NSUInteger i = 0; i < numberOfPages; i++) {
        CGRect rect = CGRectMake(startX + i*(dotWidth + dotSpacing), y, dotWidth, dotImage.size.height);

        if (i == currentPage) {
            [filledDotImage drawInRect:rect];
        } else {
            [dotImage drawInRect:rect];
        }
    }
}

- (void)setNumberOfPages:(NSUInteger)aNumberOfPages
{
    if (numberOfPages != aNumberOfPages) {
        numberOfPages = aNumberOfPages;
        [self setNeedsDisplay];
    }
}

- (void)setCurrentPage:(NSUInteger)aCurrentPage
{
    if (currentPage != aCurrentPage) {
        currentPage = aCurrentPage;
        [self setNeedsDisplay];
    }
}

- (void)setDotSpacing:(CGFloat)aDotSpacing
{
    if (dotSpacing != aDotSpacing) {
        dotSpacing = aDotSpacing;
        [self setNeedsDisplay];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    touchStartX = location.x;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    NSInteger desiredPage;
    
    if (location.x < touchStartX - kMinSwipeDistance) {
        // Swipe left
        desiredPage = currentPage - 1;
    } else if (location.x > touchStartX + kMinSwipeDistance) {
        // Swipe right
        desiredPage = currentPage + 1;
    } else {
        // Tap on a dot
        desiredPage = (location.x - (self.frame.size.width - overallWidth) / 2) / (dotWidth + dotSpacing);
    }
    
    if (desiredPage >= 0 && desiredPage < numberOfPages && desiredPage != currentPage) {
        if (![delegate respondsToSelector:@selector(pageControl:shouldSelectPageAtIndex:)] ||
              [delegate pageControl:self shouldSelectPageAtIndex:desiredPage]) {
            self.currentPage = desiredPage;
            [delegate pageControl:self didSelectPageAtIndex:desiredPage];
        }
    }
}

@end
