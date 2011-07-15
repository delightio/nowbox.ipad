//
//  NMMovieBackgroundView.m
//  ipad
//
//  Created by Bill So on 30/06/2011.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "NMMovieBackgroundView.h"
#import "NMStyleUtility.h"
#import <QuartzCore/QuartzCore.h>


@implementation NMMovieBackgroundView

+ (Class)layerClass {
	return [CAGradientLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		[self awakeFromNib];
	}
    return self;
}

- (void)awakeFromNib {
	CAGradientLayer * theLayer = (CAGradientLayer *)self.layer;
	theLayer.shouldRasterize = YES;
	// gradient color
	NSArray * colors = [NSArray arrayWithObjects:(id)[UIColor colorWithRed:78.0f / 255.0f green:80.0f / 255.0f blue:84.0f / 255.0f alpha:1.0].CGColor, (id)[UIColor colorWithRed:68.0f / 255.0f green:68.0f / 255.0f blue:68.0f / 255.0f alpha:1.0].CGColor, nil];
	[theLayer setColors:colors];
//	theLayer.startPoint = CGPointMake(0.5f, 0.0f);
//	theLayer.endPoint = CGPointMake(0.5f, 1.0f);
	// shadow
	theLayer.shadowOffset = CGSizeMake(0.0f, -1.0);
	theLayer.shadowRadius = 5.0f;
	theLayer.shadowOpacity = 0.8f;
	// border
	theLayer.borderColor = [UIColor colorWithRed:55.0f/255.0f green:55.0f/255.0f blue:55.0f/255.0f alpha:1.0f].CGColor;
	theLayer.borderWidth = 1.0f;
	// center black rect
	CALayer * rectLayer = [CALayer layer];
	rectLayer.backgroundColor = [NMStyleUtility sharedStyleUtility].blackColor.CGColor;
	rectLayer.frame = CGRectInset(theLayer.bounds, 13.0f, 13.0f);
	[theLayer addSublayer:rectLayer];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)dealloc
{
    [super dealloc];
}

@end
