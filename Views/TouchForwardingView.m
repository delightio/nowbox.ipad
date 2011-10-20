//
//  TouchForwardingView.m
//  ipad
//
//  Created by Chris Haugli on 10/20/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "TouchForwardingView.h"

@implementation TouchForwardingView

- (void)setup
{
    self.userInteractionEnabled = YES;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
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

- (void)addTarget:(id)aTarget action:(SEL)anAction
{
    target = aTarget;
    action = anAction;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (target) {
        [target performSelector:action];
        target = nil;
    }
    
    return nil;
}

@end
