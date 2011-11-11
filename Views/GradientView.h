//
//  GradientView.h
//  ipad
//
//  Created by Chris Haugli on 11/9/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GradientView : UIView
{
    float startRed;
    float startGreen;
    float startBlue;
	
    float endRed;
    float endGreen;
    float endBlue;	
}

- (void) setColoursWithCGColors:(CGColorRef)color1:(CGColorRef)color2;
- (void) setColours:(NSInteger)startRed :(NSInteger)startGreen :(NSInteger)startBlue :(NSInteger)endRed :(NSInteger)endGreen :(NSInteger)endBlue;

@end