//
//  TouchDelayingScrollView.m
//  ipad
//
//  Created by Chris Haugli on 2/20/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "TouchDelayingScrollView.h"
#import "PhoneMovieDetailView.h"

@implementation TouchDelayingScrollView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    // We don't want a horizontal swipe to trigger a scroll if the user is touching the seek bar nub. We want it to seek instead.
    for (UIView *subview in [self subviews]) {
        if ([subview isKindOfClass:[PhoneMovieDetailView class]] && CGRectContainsPoint(subview.frame, point)) {
            PhoneMovieDetailView *detailView = (PhoneMovieDetailView *)subview;
            NMSeekBar *slider = detailView.controlsView.progressSlider;
            CGPoint pointInSlider = [self convertPoint:point toView:slider];

            if ([slider pointInsideNub:pointInSlider]) {
                self.delaysContentTouches = NO;
            } else {
                self.delaysContentTouches = YES;
            }
        }
    }
    
    return [super hitTest:point withEvent:event];
}


@end
