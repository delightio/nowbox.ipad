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
- (void)setColoursWithCGColors:(CGColorRef)color1:(CGColorRef)color2
{
	const CGFloat *startComponents = CGColorGetComponents(color1);
	const CGFloat *endComponents = CGColorGetComponents(color2);
	
	[self setColours:startComponents[0]:startComponents[1]:startComponents[2]:endComponents[0]:endComponents[1]:endComponents[2]];
}

// Set colours as component RGB.
- (void)setColours:(NSInteger) _startRed:(NSInteger) _startGreen:(NSInteger) _startBlue:(NSInteger) _endRed:(NSInteger) _endGreen:(NSInteger)_endBlue
{	
	startRed = _startRed/255.0;
	startGreen = _startGreen/255.0;
	startBlue = _startBlue/255.0;
	
	endRed = _endRed/255.0;
	endGreen = _endGreen/255.0;
	endBlue = _endBlue/255.0;
    
    self.backgroundColor = [UIColor colorWithRed:endRed green:endGreen blue:endBlue alpha:1.0];
}

- (void)dealloc
{
    [super dealloc];
}

@end