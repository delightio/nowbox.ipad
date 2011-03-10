//
//  NMControlsView.m
//  Nowmov
//
//  Created by Bill So on 11/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMControlsView.h"


@implementation NMControlsView


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
	UITouch * atouch = [touches anyObject];
	if ( atouch.tapCount == 1 ) {
		[target performSelector:action withObject:self];
	}
}

- (void)addTarget:(id)atarget action:(SEL)anAction {
	target = atarget;
	action = anAction;
}

@end
