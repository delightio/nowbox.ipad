//
//  UIResponder+InterceptTouches.h
//  ipad
//
//  Created by Chris Haugli on 1/23/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

void Swizzle(Class c, SEL orig, SEL new);

@interface UIResponder (InterceptTouches)

- (void)customTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;

@end
