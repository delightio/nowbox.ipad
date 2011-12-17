//
//  UIView+InteractiveAnimation.m
//  ipad
//
//  Created by Chris Haugli on 11/23/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "UIView+InteractiveAnimation.h"

@implementation UIView (InteractiveAnimation)

+ (void)animateWithInteractiveDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion {
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                     animations:animations
                     completion:completion
     ];
}

+ (void)animateWithInteractiveDuration:(NSTimeInterval)duration animations:(void (^)(void))animations {
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                     animations:animations
                     completion:^(BOOL finished) {}
     ];
}

@end
