//
//  NMAirPlayContainerView.m
//  ipad
//
//  Created by Bill So on 17/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMAirPlayContainerView.h"
#import "NMControlsView.h"

@implementation NMAirPlayContainerView

@synthesize controlsView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:56.0f/255.0f green:56.0f/255.0f blue:56.0f/255.0f alpha:1.0f];
		CALayer * theLayer = [CALayer layer];
		theLayer.frame = self.bounds;
		theLayer.contents = (id)[UIImage imageNamed:@"airplay"].CGImage;
		theLayer.opacity = 0.2f;
		[self.layer addSublayer:theLayer];
    }
    return self;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	// cancel autohide
	[controlsView didTapAirPlayContainerView:self];
	// pass on the touch
	[super touchesEnded:touches withEvent:event];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
