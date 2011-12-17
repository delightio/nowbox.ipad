//
//  UIView+InteractiveAnimation.h
//  ipad
//
//  Created by Chris Haugli on 11/23/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (InteractiveAnimation)

+ (void)animateWithInteractiveDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion;
+ (void)animateWithInteractiveDuration:(NSTimeInterval)duration animations:(void (^)(void))animations;

@end
