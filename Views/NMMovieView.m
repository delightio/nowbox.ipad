//
//  NMMovieView.m
//  Nowmov
//
//  Created by Bill So on 11/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMMovieView.h"


@implementation NMMovieView

@synthesize player=player_;

//- (void)awakeFromNib {
//	UIPanGestureRecognizer * panRcr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGestureAction:)];
//	[self addGestureRecognizer:panRcr];
//	[panRcr release];
//	initialCenter = self.center;
//}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	self.backgroundColor = [UIColor blackColor];
	return self;
}

- (void)dealloc {
	[player_ release];
	[super dealloc];
}

- (void)swipeGestureAction:(id)sender {
	UIPanGestureRecognizer * panRcr = (UIPanGestureRecognizer *)sender;
	CGPoint pos = [panRcr translationInView:self.superview];
	CGPoint theCenter = initialCenter;
	theCenter.x += pos.x;
	self.center = theCenter;
	NSLog(@"%f, %f", pos.x, pos.y);
}

+ (Class)layerClass {
	return [AVPlayerLayer class];
}

- (AVQueuePlayer *)player {
    return player_;
}
- (void)setPlayer:(AVQueuePlayer *)aPlayer {
	if ( player_ ) {
		[player_ release];
	}
	player_ = [aPlayer retain];
    [(AVPlayerLayer *)[self layer] setPlayer:aPlayer];
}

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
