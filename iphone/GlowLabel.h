//
//  GlowLabel.h
//  ipad
//
//  Created by Chris Haugli on 2/27/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GlowLabel : UILabel

@property (nonatomic, retain) UIColor *glowColor;
@property (nonatomic, retain) UIColor *gradientStartColor;
@property (nonatomic, retain) UIColor *gradientEndColor;

- (void)setGradientStartColor:(UIColor *)startColor endColor:(UIColor *)endColor;

@end
