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
@synthesize gradientStartColor;
@synthesize gradientEndColor;

- (void)dealloc
{
    [glowColor release];
    [gradientStartColor release];
    [gradientEndColor release];
    
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

- (UIImage *)gradientImageWithSize:(CGSize)size startColor:(UIColor *)startColor endColor:(UIColor *)endColor
{
    CGFloat width = size.width;
    CGFloat height = size.height;
    
    // create a new bitmap image context
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    
    // get context
    CGContextRef context = UIGraphicsGetCurrentContext();       
    
    // push context to make it current (need to do this manually because we are not drawing in a UIView)
    UIGraphicsPushContext(context);                             
    
    //draw gradient    
    CGGradientRef glossGradient;
    CGColorSpaceRef rgbColorspace;
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    const CGFloat *startComp = CGColorGetComponents(startColor.CGColor);
    const CGFloat *endComp = CGColorGetComponents(endColor.CGColor);
    CGFloat components[8] = { endComp[0], endComp[1], endComp[2], endComp[3],
        startComp[0], startComp[1], startComp[2], startComp[3] };
    
    rgbColorspace = CGColorSpaceCreateDeviceRGB();
    glossGradient = CGGradientCreateWithColorComponents(rgbColorspace, components, locations, num_locations);
    CGPoint topCenter = CGPointMake(0, 0);
    CGPoint bottomCenter = CGPointMake(0, height);
    CGContextDrawLinearGradient(context, glossGradient, bottomCenter, topCenter, 0);
    
    CGGradientRelease(glossGradient);
    CGColorSpaceRelease(rgbColorspace); 
    
    // pop context 
    UIGraphicsPopContext();                             
    
    // get a UIImage from the image context
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // clean up drawing environment
    UIGraphicsEndImageContext();
    
    return gradientImage;
}

- (void)updateGradient
{
    CGSize textSize = [self.text sizeWithFont:self.font];
    self.textColor = [UIColor colorWithPatternImage:[self gradientImageWithSize:textSize startColor:gradientStartColor endColor:gradientEndColor]];    
}

- (void)setText:(NSString *)text
{
    [super setText:text];
    
    if (gradientStartColor) {
        [self updateGradient];
    }
}

- (void)setGradientStartColor:(UIColor *)startColor endColor:(UIColor *)endColor
{
    self.gradientStartColor = startColor;
    self.gradientEndColor = endColor;
    [self updateGradient];
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
