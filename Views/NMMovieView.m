//
//  NMMovieView.m
//  Nowmov
//
//  Created by Bill So on 11/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMMovieView.h"
#import "NMAVQueuePlayer.h"
#import "NMStyleUtility.h"


@implementation NMMovieView

@synthesize player=player_;
@synthesize activityIndicator, statusLabel;
@synthesize airPlayIndicatorView;

//- (void)awakeFromNib {
//	UIPanGestureRecognizer * panRcr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGestureAction:)];
//	[self addGestureRecognizer:panRcr];
//	[panRcr release];
//	initialCenter = self.center;
//}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	NMStyleUtility * theStyle = [NMStyleUtility sharedStyleUtility];
	self.backgroundColor = theStyle.blackColor;
	
	CGPoint pos;
	pos.x = floorf(frame.size.width / 2.0);
	pos.y = floorf(frame.size.height / 2.0);
	pos.y -= 22.0;
	activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	activityIndicator.center = pos;
	activityIndicator.hidesWhenStopped = YES;
	[self addSubview:activityIndicator];
	
	statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 640.0, 22.0)];
	statusLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	statusLabel.backgroundColor = [UIColor clearColor];
	statusLabel.textAlignment = UITextAlignmentCenter;
	statusLabel.font = [UIFont boldSystemFontOfSize:15.0];
	statusLabel.textColor = [UIColor whiteColor];
	statusLabel.shadowColor = [UIColor darkGrayColor];
	statusLabel.shadowOffset = CGSizeMake(0.0, 1.0);
	pos.y += activityIndicator.bounds.size.height;
	statusLabel.center = pos;
	statusLabel.text = @"Loading";
	statusLabel.alpha = 0.0f;
	[self addSubview:statusLabel];
	
	UIImage * ytLogo = [UIImage imageNamed:@"youtube_logo_36"];
	logoView = [[UIImageView alloc] initWithImage:ytLogo];
	CGRect theFrame = logoView.frame;
	theFrame.origin = CGPointMake(frame.size.width - 10.0f - ytLogo.size.width, frame.size.height - 10.0f - ytLogo.size.height);
	logoView.frame = theFrame;
	logoView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
	logoView.alpha = 0.5f;
	[self addSubview:logoView];
	
	if ( NM_RUNNING_IOS_5 ) {
		// load the view
		[[NSBundle mainBundle] loadNibNamed:@"AppleTVIndicationView" owner:self options:nil];
	}

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

//- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
////	CGRect leftRect = CGRectMake(0.0f, 112.0f, 156.0f, 545.0f);
////	CGRect rightRect = CGRectMake(868.0f, 112.0f, 156.0f, 545.0f);
////	CGPoint touchLoc;
//	UITouch * atouch = [touches anyObject];
//	if ( atouch.tapCount == 1 ) {
//		// check the location of the touch
////		touchLoc = [atouch locationInView:self];
////		if ( CGRectContainsPoint(leftRect, touchLoc) ) {
////			// go to previous
////			[target performSelector:@selector(skipCurrentVideo:) withObject:self];
////		} else if ( CGRectContainsPoint(rightRect, touchLoc) ) {
////			// go to next
////			[target performSelector:@selector(skipCurrentVideo:) withObject:self];
////		} else {
//			[target performSelector:action withObject:self];
////		}
//	}
//}
//
//- (void)addTarget:(id)atarget action:(SEL)anAction {
//	target = atarget;
//	action = anAction;
//}

- (void)setActivityIndicationHidden:(BOOL)hidden animated:(BOOL)animated {
	if ( animated ) [UIView beginAnimations:nil context:nil];
	
	CGFloat f = hidden ? 0.0 : 1.0;
	if ( hidden ) [activityIndicator stopAnimating];
	else [activityIndicator startAnimating];
	activityIndicator.alpha = f;
	statusLabel.alpha = f;
	if ( animated ) [UIView commitAnimations];
}

- (void)hideAirPlayIndicatorView:(BOOL)hidden {
	CGRect theRect;
	if ( airPlayIndicatorView.superview && hidden) {
		// hide
		[airPlayIndicatorView removeFromSuperview];
	} else if ( airPlayIndicatorView.superview == nil && !hidden ) {
		// show
		theRect = self.bounds;
		airPlayIndicatorView.center = CGPointMake(theRect.size.width / 2.0f, theRect.size.height / 2.0f);
		airPlayIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
		[self addSubview:airPlayIndicatorView];
	}
}

@end
