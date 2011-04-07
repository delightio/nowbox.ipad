//
//  NMControlsView.m
//  Nowmov
//
//  Created by Bill So on 11/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMControlsView.h"
#import "NMMovieView.h"

#define NM_PLAYER_STATUS_CONTEXT		100
#define NM_PLAYER_CURRENT_ITEM_CONTEXT		101


@implementation NMControlsView

@synthesize title, duration, timeElapsed, authorProfileURLString;

- (void)awakeFromNib {
	// load the progress bar image
	UIImage * img = [UIImage imageNamed:@"playback_progress_background"];
	progressView.image = [img stretchableImageWithLeftCapWidth:98 topCapHeight:0];
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

- (void)dealloc {
	[authorProfileURLString release];
    [super dealloc];
}

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

- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated {
	if ( animated ) {
		[UIView beginAnimations:nil context:nil];
	}
	if ( hidden ) {
		prevVideoButton.alpha = 0.0;
		nextVideoButton.alpha = 0.0;
		progressView.alpha = 0.0;
		durationLabel.alpha = 0.0;
		currentTimeLabel.alpha = 0.0;
	} else {
		prevVideoButton.alpha = 1.0;
		nextVideoButton.alpha = 1.0;
		progressView.alpha = 1.0;
		durationLabel.alpha = 1.0;
		currentTimeLabel.alpha = 1.0;
	}
	if ( animated ) {
		[UIView commitAnimations];
	}
}

#pragma mark KVO

//- (void)observeMovieView:(NMMovieView *)mvView {
//	firstShowControlView = YES;
//	[mvView.player addObserver:self forKeyPath:@"status" options:0 context:(void *)NM_PLAYER_STATUS_CONTEXT];
//	[mvView.player addObserver:self forKeyPath:@"currentItem" options:0 context:(void *)NM_PLAYER_CURRENT_ITEM_CONTEXT];
//	[mvView.player addPeriodicTimeObserverForInterval:CMTimeMake(2, 2) queue:NULL usingBlock:^(CMTime aTime){
//		// print the time
//		CMTime t = [mvView.player currentTime];
//		self.timeElapsed = t.value / t.timescale;
//	}];
//}
//
//- (void)stopObservingMovieView:(NMMovieView *)mvView {
//	[mvView.player removeObserver:self forKeyPath:@"status"];
//	[mvView.player removeObserver:self forKeyPath:@"currentItem"];
//	[mvView.player removeTimeObserver:self];
//}
//
//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//	NSInteger c = (NSInteger)context;
//	NMMovieView * movieView = (NMMovieView *)object;
//	if ( c == NM_PLAYER_STATUS_CONTEXT ) {
//		switch (movieView.player.status) {
//			case AVPlayerStatusReadyToPlay:
//			{
//				// the instance is ready to play. yeah!
//				//[self updateControlsForVideoAtIndex:currentIndex];
//				if ( firstShowControlView ) {
//					firstShowControlView = NO;
//					if ( !self.hidden && self.alpha > 0.0 ) {
//						// hide the control
//						[self performSelector:action withObject:target];
//					}
//				}
//				break;
//			}
//			default:
//				break;
//		}
//		if ( firstShowControlView ) {
//			firstShowControlView = NO;
//		}
//	} else if ( c == NM_PLAYER_CURRENT_ITEM_CONTEXT ) {
//#ifdef DEBUG_PLAYBACK_NETWORK_CALL
//		NSLog(@"current item changed");
//#endif
//		[self updateControlsForVideoAtIndex:currentIndex];
//	}
//	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
//}

#pragma mark properties
- (void)resetView {
	durationLabel.text = @"--:--";
	currentTimeLabel.text = @"--:--";
	self.alpha = 1.0;
	self.hidden = NO;
	[self setControlsHidden:YES animated:NO];
}

- (void)setChannel:(NSString *)cname author:(NSString *)authName {
	[authorButton setTitle:authName forState:UIControlStateNormal];
	channelNameLabel.text = cname;
	// author label
	CGSize theSize = [authName sizeWithFont:authorButton.titleLabel.font];
	CGRect theFrame = authorButton.frame;
	theFrame.size.width = theSize.width;
	authorButton.frame = theFrame;
	// set the inbeetween "on" label position
	CGRect otherFrame = onLabel.frame;
	otherFrame.origin.x = theFrame.size.width + theFrame.origin.x;
	onLabel.frame = otherFrame;
	// set channel title
	theFrame = channelNameLabel.frame;
	theFrame.origin.x = otherFrame.origin.x + otherFrame.size.width;
	channelNameLabel.frame = theFrame;
}

- (IBAction)goToAuthorProfilePage:(id)sender {
	if ( authorProfileURLString ) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:authorProfileURLString]];
	}
}

- (void)setTitle:(NSString *)aTitle {
	videoTitleLabel.text = [aTitle uppercaseString];
}

- (void)setDuration:(NSInteger)aDur {
	durationLabel.text = [NSString stringWithFormat:@"%02d:%02d", aDur / 60, aDur % 60];
}

- (void)setTimeElapsed:(NSInteger)aTime {
	currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", aTime / 60, aTime % 60];
}

@end
