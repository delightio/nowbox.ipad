//
//  ThumbnailView.m
//  ipad
//
//  Created by Chris Haugli on 2/6/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "ThumbnailView.h"
#import <QuartzCore/QuartzCore.h>

#define kPressAndHoldDuration 0.8f
#define kRearrangingScaleFactor 1.15

@implementation ThumbnailView

@synthesize contentView;
@synthesize image;
@synthesize label;
@synthesize activityIndicator;
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Load the view from a nib
        [[NSBundle mainBundle] loadNibNamed:@"ThumbnailView" owner:self options:nil];
        
        if (CGRectEqualToRect(frame, CGRectZero)) {
            self.frame = contentView.bounds;
        }

        contentView.frame = self.bounds;        
        contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:contentView];
        
        // Set the font depending on if it's available (iOS 4 doesn't have Futura Condensed Medium)
        UIFont *font = [UIFont fontWithName:@"Futura-CondensedMedium" size:label.font.pointSize];
        if (!font) {
            font = [UIFont fontWithName:@"Futura-Medium" size:label.font.pointSize];
        }
        [label setFont:font];
        
        image.adjustsImageOnHighlight = YES;        
    }
    return self;
} 

- (void)dealloc
{
    [pressAndHoldTimer invalidate];
    
    [contentView release];
    [image release];
    [label release];
    [activityIndicator release];
    
    [super dealloc];
}

- (void)cancelPressAndHoldTimer
{
    [pressAndHoldTimer invalidate];
    pressAndHoldTimer = nil;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];    
    image.highlighted = highlighted;
}

- (void)setDelegate:(id<ThumbnailViewDelegate>)aDelegate
{
    if (delegate != aDelegate) {
        [self removeTarget:delegate action:NULL forControlEvents:UIControlEventAllEvents];
        delegate = aDelegate;        
        [self addTarget:self action:@selector(handleTouchUp:) forControlEvents:UIControlEventTouchUpInside];
        [self addTarget:self action:@selector(handleTouchDown:withEvent:) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(handleCancelTouch:) forControlEvents:UIControlEventTouchCancel | UIControlEventTouchUpOutside | UIControlEventTouchDragOutside];
        [self addTarget:self action:@selector(handleDrag:withEvent:) forControlEvents:UIControlEventTouchDragInside];
    }
}

#pragma mark - Touches

- (void)didBeginRearranging
{
    pressAndHoldTimer = nil;
    if ([delegate respondsToSelector:@selector(thumbnailViewDidBeginRearranging:)]) {
        [delegate thumbnailViewDidBeginRearranging:self];
    }
    movable = YES;
    [self.superview bringSubviewToFront:self];
    
    [UIView animateWithDuration:0.15
                     animations:^{
                         self.alpha = 0.7;
                         self.transform = CGAffineTransformMakeScale(kRearrangingScaleFactor, kRearrangingScaleFactor);
                     }];
}

- (void)didEndRearranging
{
    movable = NO;        
    
    [UIView animateWithDuration:0.15
                     animations:^{
                         self.alpha = 1.0;
                         self.transform = CGAffineTransformIdentity;                         
                     }];
    
    if ([delegate respondsToSelector:@selector(thumbnailViewDidEndRearranging:)]) {
        [delegate thumbnailViewDidEndRearranging:self];
    }
}

- (void)handleTouchUp:(id)sender
{
    if (movable) {
        [self didEndRearranging];
    } else {
        [self cancelPressAndHoldTimer];        
        [delegate thumbnailViewDidTap:self];
    }
}

- (void)handleTouchDown:(id)sender withEvent:(UIEvent *)event
{
    [self cancelPressAndHoldTimer];
    pressAndHoldTimer = [NSTimer scheduledTimerWithTimeInterval:kPressAndHoldDuration
                                                         target:self
                                                       selector:@selector(didBeginRearranging)
                                                       userInfo:nil
                                                        repeats:NO];
    
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint dragStartLocation = [touch locationInView:self.superview];
    dragAnchorPoint = CGPointMake(dragStartLocation.x - self.center.x, dragStartLocation.y - self.center.y);
}

- (void)handleCancelTouch:(id)sender
{    
    [self cancelPressAndHoldTimer];
    if (movable) {
        [self didEndRearranging];
    } else {
        [self cancelPressAndHoldTimer];
    }
}

- (void)handleDrag:(id)sender withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    if (movable) {
        CGPoint location = [touch locationInView:self.superview];
        
        self.center = CGPointMake(location.x - dragAnchorPoint.x,
                                  location.y - dragAnchorPoint.y);
        
        if ([delegate respondsToSelector:@selector(thumbnailView:didDragToLocation:)]) {
            [delegate thumbnailView:self didDragToLocation:self.center];
        }
    } else {
        CGPoint dragStartLocation = [touch locationInView:self.superview];
        dragAnchorPoint = CGPointMake(dragStartLocation.x - self.center.x, dragStartLocation.y - self.center.y);
    }
}

@end
