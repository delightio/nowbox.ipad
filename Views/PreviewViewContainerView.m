//
//  PreviewViewContainerView.m
//  ipad
//
//  Created by Tim Chen on 4/9/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "PreviewViewContainerView.h"

@implementation PreviewViewContainerView

@synthesize scrollView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event
{
    UIView* child = nil;
    if ((child = [super hitTest:point withEvent:event]) == self)
        return scrollView;
    return child;
}


@end
