//
//  UIResponder+InterceptTouches.m
//  ipad
//
//  Created by Chris Haugli on 1/23/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "UIResponder+InterceptTouches.h"
#import </usr/include/objc/objc-class.h>

@implementation UIView (InterceptTouches)

void Swizzle(Class c, SEL orig, SEL new)
{
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, new);
    method_exchangeImplementations(origMethod, newMethod);

    /*
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, new);
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
        class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    else
        method_exchangeImplementations(origMethod, newMethod);*/
}

- (void)customTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
    NSLog(@"touch!");
    [self customTouchesBegan:touches withEvent:event];
}

@end
