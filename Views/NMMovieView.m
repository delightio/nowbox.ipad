//
//  NMMovieView.m
//  Nowmov
//
//  Created by Bill So on 11/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMMovieView.h"
#import "NMAVQueuePlayer.h"


@implementation NMMovieView

@synthesize player=player_;
@synthesize activityIndicator, statusLabel;

//- (void)awakeFromNib {
//	UIPanGestureRecognizer * panRcr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGestureAction:)];
//	[self addGestureRecognizer:panRcr];
//	[panRcr release];
//	initialCenter = self.center;
//}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	self.backgroundColor = [UIColor blackColor];
	
	CGPoint pos;
	pos.x = floorf(frame.size.width / 2.0);
	pos.y = floorf(frame.size.height / 2.0);
	pos.y -= 22.0;
	activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	activityIndicator.center = pos;
	[self addSubview:activityIndicator];
	
	statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 640.0, 22.0)];
	statusLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	statusLabel.backgroundColor = [UIColor clearColor];
	statusLabel.textAlignment = UITextAlignmentCenter;
	statusLabel.font = [UIFont fontWithName:@"Futura-MediumItalic" size:15.0f];
	statusLabel.textColor = [UIColor whiteColor];
	statusLabel.shadowColor = [UIColor darkGrayColor];
	statusLabel.shadowOffset = CGSizeMake(0.0, 1.0);
	pos.y += activityIndicator.bounds.size.height;
	statusLabel.center = pos;
	statusLabel.text = @"Loading";
	[self addSubview:statusLabel];
	
	return self;
}

- (void)dealloc {
	[player_ release];
	[statusLabel release];
	[activityIndicator release];
	[super dealloc];
}

+ (Class)layerClass {
	return [AVPlayerLayer class];
}

- (NMAVQueuePlayer *)player {
    return player_;
}
- (void)setPlayer:(NMAVQueuePlayer *)aPlayer {
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

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//	CGRect leftRect = CGRectMake(0.0f, 112.0f, 156.0f, 545.0f);
//	CGRect rightRect = CGRectMake(868.0f, 112.0f, 156.0f, 545.0f);
//	CGPoint touchLoc;
	UITouch * atouch = [touches anyObject];
	if ( atouch.tapCount == 1 ) {
		// check the location of the touch
//		touchLoc = [atouch locationInView:self];
//		if ( CGRectContainsPoint(leftRect, touchLoc) ) {
//			// go to previous
//			[target performSelector:@selector(skipCurrentVideo:) withObject:self];
//		} else if ( CGRectContainsPoint(rightRect, touchLoc) ) {
//			// go to next
//			[target performSelector:@selector(skipCurrentVideo:) withObject:self];
//		} else {
			[target performSelector:action withObject:self];
//		}
	}
}

- (void)addTarget:(id)atarget action:(SEL)anAction {
	target = atarget;
	action = anAction;
}

- (void)setActivityIndicationHidden:(BOOL)hidden animated:(BOOL)animated {
	if ( animated ) [UIView beginAnimations:nil context:nil];
	
	CGFloat f = hidden ? 0.0 : 1.0;
	if ( hidden ) [activityIndicator stopAnimating];
	else [activityIndicator startAnimating];
	activityIndicator.alpha = f;
	statusLabel.alpha = f;
	if ( animated ) [UIView commitAnimations];
}

@end
