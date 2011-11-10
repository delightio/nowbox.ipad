//
//  GradientView.m
//  ipad
//
//  Created by Chris Haugli on on 11/9/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "GradientView.h"

@implementation GradientView

- (void)drawRect:(CGRect)rect
{
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
	
    size_t numLocations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
	
    //Two colour components, the start and end colour both set to opaque.
    CGFloat components[8] = { startRed, startGreen, startBlue, 1.0, endRed, endGreen, endBlue, 1.0 };
	
    CGColorSpaceRef rgbColorspace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(rgbColorspace, components, locations, numLocations);
	
    CGRect currentBounds = self.bounds;
    CGPoint topCenter = CGPointMake(CGRectGetMidX(currentBounds), 0.0f);
    CGPoint bottomCenter = CGPointMake(CGRectGetMidX(currentBounds), CGRectGetMaxY(currentBounds));
	
    CGContextDrawLinearGradient(currentContext, gradient, topCenter, bottomCenter, 0);
	
    // Release our CG objects.
    CGGradientRelease(gradient);
    CGColorSpaceRelease(rgbColorspace);
}

// Set colours as CGColorRefs.
- (void) setColoursWithCGColors:(CGColorRef)color1:(CGColorRef)color2
{
	const CGFloat *startComponents = CGColorGetComponents(color1);
	const CGFloat *endComponents = CGColorGetComponents(color2);
	
	[self setColours:startComponents[0]:startComponents[1]:startComponents[2]:endComponents[0]:endComponents[1]:endComponents[2]];
}

// Set colours as component RGB.
- (void) setColours:(float) _startRed:(float) _startGreen:(float) _startBlue:(float) _endRed:(float) _endGreen:(float)_endBlue
{
	self.backgroundColor = [UIColor colorWithRed:_endRed green:_endGreen blue:_endBlue alpha:1.0];
	
	startRed = _startRed;
	startGreen = _startGreen;
	startBlue = _startBlue;
	
	endRed = _endRed;
	endGreen = _endGreen;
	endBlue = _endBlue;
}

- (void)dealloc
{
    [super dealloc];
}

@end