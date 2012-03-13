//
//  GlowLabel.m
//  ipad
//
//  Created by Chris Haugli on 2/27/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "GlowLabel.h"

@implementation GlowLabel

@synthesize glowColor;

- (void)dealloc
{
    [glowColor release];
    
    [super dealloc];
}

- (void)setGlowColor:(UIColor *)aGlowColor
{
    if (glowColor != aGlowColor) {
        [glowColor release];
        glowColor = [aGlowColor retain];
        
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);

    if (glowColor) {
        CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 5.0, glowColor.CGColor);
    }
    
    [super drawRect:rect];
    
    CGContextRestoreGState(context);
}

@end
