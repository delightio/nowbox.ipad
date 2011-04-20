//
//  NMTouchImageView.m
//  Nowmov
//
//  Created by Bill So on 09/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTouchImageView.h"
#import <QuartzCore/QuartzCore.h>


@implementation NMTouchImageView

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
		// create highlight layer
		highlightLayer = [[CALayer layer] retain];
		highlightLayer.backgroundColor = [UIColor blackColor].CGColor;
		highlightLayer.opacity = 0.5f;
		highlightLayer.frame = CGRectMake(0.0, 0.0, frame.size.width, frame.size.height);
		self.contentMode = UIViewContentModeScaleAspectFill;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

- (void)dealloc {
	[highlightLayer release];
    [super dealloc];
}

- (void)addTarget:(id)aTarget action:(SEL)anAction {
	target = aTarget;
	action = anAction;
}

#pragma mark Highlight 
- (void)highlightHandler:(id)sender {
	[self.layer addSublayer:highlightLayer];
	self.highlighted = YES;
}

- (void)clearHighlight:(id)sender {
	[highlightLayer removeFromSuperlayer];
	self.highlighted = NO;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[self highlightHandler:nil];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch * atouch = [touches anyObject];
	CGPoint thePoint = [atouch locationInView:self];
	if ( CGRectContainsPoint(self.bounds, thePoint) ) {
		if ( !self.highlighted ) {
			[self highlightHandler:nil];
		}
	} else if ( self.highlighted ) {
		// the touch is moved outside of the entry
		// remove highlight
		[self clearHighlight:nil];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch * atouch = [touches anyObject];
	CGPoint thePoint = [atouch locationInView:self];
	if ( CGRectContainsPoint(self.bounds, thePoint) && target) {
		// fire the action
		[target performSelector:action withObject:self];
	}
	[self clearHighlight:nil];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[self clearHighlight:nil];
}


@end
