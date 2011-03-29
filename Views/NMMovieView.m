//
//  NMMovieView.m
//  Nowmov
//
//  Created by Bill So on 11/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMMovieView.h"


@implementation NMMovieView


//- (id)initWithFrame:(CGRect)frame {
//    
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code.
//    }
//    return self;
//}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

//- (void)dealloc {
//    [super dealloc];
//}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	CGRect leftRect = CGRectMake(0.0f, 112.0f, 156.0f, 545.0f);
	CGRect rightRect = CGRectMake(868.0f, 112.0f, 156.0f, 545.0f);
	CGPoint touchLoc;
	UITouch * atouch = [touches anyObject];
	if ( atouch.tapCount == 1 ) {
		// check the location of the touch
		touchLoc = [atouch locationInView:self];
		if ( CGRectContainsPoint(leftRect, touchLoc) ) {
			// go to previous
			[target performSelector:@selector(skipCurrentVideo:) withObject:self];
		} else if ( CGRectContainsPoint(rightRect, touchLoc) ) {
			// go to next
			[target performSelector:@selector(skipCurrentVideo:) withObject:self];
		} else {
			[target performSelector:action withObject:self];
		}
	}
}

- (void)addTarget:(id)atarget action:(SEL)anAction {
	target = atarget;
	action = anAction;
}

@end
