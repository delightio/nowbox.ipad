//
//  PhoneVideoInfoOrientedView.m
//  ipad
//
//  Created by Chris Haugli on 2/21/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "PhoneVideoInfoOrientedView.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark - PhoneVideoInfoOrientedView

@implementation PhoneVideoInfoOrientedView

@synthesize topView;
@synthesize bottomView;
@synthesize infoView;
@synthesize channelThumbnail;
@synthesize infoButtonScrollView;
@synthesize channelTitleLabel;
@synthesize videoTitleLabel;
@synthesize descriptionLabel;
@synthesize infoPanelExpanded;
@synthesize delegate;

- (void)awakeFromNib
{
    UIView *viewToMask = infoButtonScrollView.superview;
    
    // Fade out info buttons
    CAGradientLayer *mask = [CAGradientLayer layer];
    mask.frame = CGRectMake(0, 0, viewToMask.bounds.size.width, viewToMask.bounds.size.height * 2);
    mask.colors = [NSArray arrayWithObjects:
                   (id)[UIColor whiteColor].CGColor,
                   (id)[UIColor whiteColor].CGColor,                       
                   (id)[UIColor clearColor].CGColor, nil];
    mask.startPoint = CGPointMake(0.5, 0);
    mask.endPoint = CGPointMake(0.5, 1);
    mask.locations = [NSArray arrayWithObjects:
                      [NSNumber numberWithFloat:0],
                      [NSNumber numberWithFloat:0.25],
                      [NSNumber numberWithFloat:0.375], nil];
    viewToMask.layer.mask = mask; 
    
    originalVideoTitleFrame = videoTitleLabel.frame;
}

- (void)dealloc
{
    [topView release];
    [bottomView release];
    [infoView release];
    [channelThumbnail release];
    [infoButtonScrollView release];
    [channelTitleLabel release];
    [videoTitleLabel release];
    [descriptionLabel release];
    
    [super dealloc];
}

- (void)positionLabels
{
    // Position the description label below the video title
    videoTitleLabel.frame = originalVideoTitleFrame;
    [videoTitleLabel sizeToFit];
    CGRect frame = videoTitleLabel.frame;
    frame.size.height = MIN(frame.size.height, originalVideoTitleFrame.size.height);
    videoTitleLabel.frame = frame;
    
    frame = descriptionLabel.frame;
    CGFloat distanceFromBottom = CGRectGetHeight(infoView.frame) - CGRectGetMaxY(frame);
    frame.origin.y = CGRectGetMaxY(videoTitleLabel.frame) + 2;
    frame.size.height = infoView.frame.size.height - frame.origin.y - distanceFromBottom;
    descriptionLabel.frame = frame;
    descriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)setInfoPanelExpanded:(BOOL)expanded
{
    [self setInfoPanelExpanded:expanded animated:NO];
}

- (void)setInfoPanelExpanded:(BOOL)expanded animated:(BOOL)animated
{    
    infoPanelExpanded = expanded;
    
    CGRect frame = infoView.frame;
    BOOL landscape = (infoView == bottomView);
    
    if (landscape) {
        // Landscape - resize view keeping the bottom position the same
        frame.size.height = (expanded ? 160 : 120);
        frame.origin.y = CGRectGetMaxY(infoView.frame) - frame.size.height;
    } else {
        // Portrait - resize view keeping the top position the same
        frame.size.height = (expanded ? 200 : 116);
    }
    
    if (expanded) {
        infoButtonScrollView.scrollEnabled = NO;
        
        // We don't want buttons flying down from the top, looks bad. Reposition buttons to avoid it.
        for (UIView *view in infoButtonScrollView.subviews) {
            if (view.center.y < infoButtonScrollView.contentOffset.y) {
                view.center = CGPointMake(view.center.x, view.center.y + [infoButtonScrollView.subviews count] * infoButtonScrollView.frame.size.height);
            }
        }
    } else {
        infoButtonScrollView.scrollEnabled = YES;
    }
    
    // We don't want the button alpha mask when the panel is expanded
    CAGradientLayer *mask = (CAGradientLayer *) infoButtonScrollView.superview.layer.mask;
    if (animated) {
        [CATransaction begin];
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [CATransaction setValue:[NSNumber numberWithDouble:0.3] forKey:kCATransactionAnimationDuration];
    }
    if (expanded) {
        mask.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0],
                          [NSNumber numberWithFloat:1.0],
                          [NSNumber numberWithFloat:1.0], nil];
    } else {
        mask.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0],
                          [NSNumber numberWithFloat:0.25],
                          [NSNumber numberWithFloat:0.375], nil];
    }
    if (animated) {
        [CATransaction commit];
    }
    
    // Resize the panel
    if (animated) {
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             infoView.frame = frame;
                         }
                         completion:^(BOOL finished){
                         }];
    } else {
        infoView.frame = frame;
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [infoButtonScrollView centerContentOffset];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [infoButtonScrollView centerContentOffset];
    }
    
    [delegate phoneVideoInfoOrientedView:self didEndDraggingWithScrollView:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [delegate phoneVideoInfoOrientedView:self willBeginDraggingWithScrollView:scrollView];
}

@end

#pragma mark - InfiniteScrollView

@implementation InfiniteScrollView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    // Since clipToBounds = NO, we want to allow swiping anywhere content is shown
    if (self.superview) {
        CGPoint pointInSuperview = [self convertPoint:point toView:self.superview];
        return [self.superview pointInside:pointInSuperview withEvent:event];
    }
    
    return [super pointInside:point withEvent:event];
}

- (NSInteger)centerViewIndex
{
    for (UIView *view in self.subviews) {
        if (view.center.y > self.contentOffset.y &&
            view.center.y < self.contentOffset.y + self.frame.size.height) {
            return view.tag;
        }
    }
    return 0;
}

- (void)centerContentOffset
{
    // Which view is closest to the center?
    NSInteger centerViewIndex = [self centerViewIndex];
    
    // Make sure we don't get too close to the scroll limit
    self.contentOffset = CGPointMake(0, round((self.contentSize.height / 2) / self.frame.size.height) * self.frame.size.height);
    for (UIView *view in self.subviews) {
        CGRect frame = view.frame;
        frame.origin.y = self.contentOffset.y + (view.tag - centerViewIndex) * self.frame.size.height;
        view.frame = frame;
    }        
    
    [self setNeedsLayout];
}

- (void)awakeFromNib
{
    // "Infinite" scrolling
    self.contentSize = CGSizeMake(self.frame.size.width, 10000);
    [self centerContentOffset];
}

- (void)layoutSubviews
{
    // Do we need to loop any of the subviews to the top / bottom?
    for (UIView *view in self.subviews) {
        CGFloat distance = view.center.y - (self.contentOffset.y + self.frame.size.height / 2);
        CGFloat newY = view.center.y + (distance > 0 ? -1.0f : 1.0f) * [self.subviews count] * self.frame.size.height;
        CGFloat newDistance = newY - (self.contentOffset.y + self.frame.size.height / 2);
        
        if (ABS(newDistance) < ABS(distance)) {
            view.center = CGPointMake(view.center.x, newY);
        }
    }
}

@end