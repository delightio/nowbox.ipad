//
//  NMControlsView.m
//  Nowmov
//
//  Created by Bill So on 11/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMControlsView.h"
#import "NMMovieView.h"
#import <QuartzCore/QuartzCore.h>

#define NM_PLAYER_STATUS_CONTEXT		100
#define NM_PLAYER_CURRENT_ITEM_CONTEXT	101
#define NM_PLAYER_PROGRESS_BAR_WIDTH	632


#define NM_CONTROL_VIEW_FULL_SCREEN_ANIMATION_CONTEXT			1001
#define NM_CONTROL_VIEW_HALF_SCREEN_ANIMATION_CONTEXT			1002

@implementation NMControlsView

@synthesize channel, title, duration, timeElapsed;
@synthesize channelViewButton, shareButton, playPauseButton;
@synthesize nextVideoButton, controlsHidden, timeRangeBuffered;

- (void)awakeFromNib {
	playbackMode_ = NMFullScreenPlaybackMode;
//	[self setPlaybackMode:NMHalfScreenMode animated:NO];
	// load the progress bar image
	[progressSlider setMinimumTrackImage:[[UIImage imageNamed:@"demo_progress_bright_side"] stretchableImageWithLeftCapWidth:6 topCapHeight:0] forState:UIControlStateNormal];
	[progressSlider setMaximumTrackImage:[[UIImage imageNamed:@"demo_progress_dark_side"] stretchableImageWithLeftCapWidth:6 topCapHeight:0] forState:UIControlStateNormal];
	[progressSlider setThumbImage:[UIImage imageNamed:@"demo_progress_nub"] forState:UIControlStateNormal];
		
	// the control background
	NMStyleUtility * theStyle = [NMStyleUtility sharedStyleUtility];
	CALayer * ctrlBgLayer = controlContainerView.layer;
	ctrlBgLayer.backgroundColor = [theStyle.blackColor colorWithAlphaComponent:0.7f].CGColor;
	ctrlBgLayer.borderWidth = 1.0f;
	ctrlBgLayer.borderColor = [UIColor colorWithRed:153.0f/255.0f green:153.0f/255.0f blue:153.0f/255.0f alpha:0.7f].CGColor;
	ctrlBgLayer.cornerRadius = 8.0f;
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
	[progressBarLayer release];
	[nubLayer release];
	[lastVideoMessage release];
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
		self.alpha = 0.0;
//		prevVideoButton.alpha = 0.0;
//		nextVideoButton.alpha = 0.0;
//		progressView.alpha = 0.0;
//		durationLabel.alpha = 0.0;
//		currentTimeLabel.alpha = 0.0;
	} else {
		self.alpha = 1.0;
//		prevVideoButton.alpha = 1.0;
//		nextVideoButton.alpha = 1.0;
//		progressView.alpha = 1.0;
//		durationLabel.alpha = 1.0;
//		currentTimeLabel.alpha = 1.0;
	}
	if ( animated ) {
		[UIView commitAnimations];
	}
}

- (BOOL)controlsHidden {
	return controlContainerView.alpha == 0.0f || self.alpha == 0.0f || self.hidden;
}

- (void)showLastVideoMessage {
	UIImage * img = [[UIImage imageNamed:@"channel_title"] stretchableImageWithLeftCapWidth:10 topCapHeight:0];
	if ( lastVideoMessage == nil ) {
		lastVideoMessage = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		lastVideoMessage.userInteractionEnabled = NO;
		lastVideoMessage.titleLabel.font = [UIFont fontWithName:@"Futura-MediumItalic" size:16.0f];
		lastVideoMessage.titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
		[lastVideoMessage setBackgroundImage:img forState:UIControlStateNormal];
		CGRect theFrame = nextVideoButton.frame;
		theFrame.origin.y = nextVideoButton.center.y - floorf(img.size.height / 2.0);
		theFrame.origin.x -= 190.0f;
		theFrame.size.width = 180.0;
		theFrame.size.height = img.size.height;
		lastVideoMessage.frame = theFrame;
		[lastVideoMessage setTitle:@"Playing Last Video" forState:UIControlStateNormal];
		[self addSubview:lastVideoMessage];
	}
}

- (void)setPlaybackMode:(NMPlaybackViewModeType)aMode animated:(BOOL)animated {
	if ( aMode == playbackMode_ ) return;
	
	CGRect viewRect;
	switch (aMode) {
		case NMFullScreenPlaybackMode:
		{
			// show stuff
//			otherInfoLabel.hidden = NO;
//			channelNameLabel.hidden = NO;
//			videoTitleLabel.hidden = NO;
			// set to play video in full screen
			if ( animated ) {
				[UIView beginAnimations:nil context:(void *)NM_CONTROL_VIEW_FULL_SCREEN_ANIMATION_CONTEXT];
				[UIView setAnimationBeginsFromCurrentState:YES];
			}
			// set its own size
			viewRect = CGRectMake(self.frame.origin.x - 40.0f, 0.0f, 1024.0f, 768.0f);
			self.frame = viewRect;
			// resize the container view
			viewRect = CGRectMake(49.0f, 640.0f, 926.0f, 98.0f);
			controlContainerView.frame = viewRect;
			otherInfoLabel.alpha = 1.0f;
			channelNameLabel.alpha = 1.0f;
			videoTitleLabel.alpha = 1.0f;
			if ( animated ) [UIView commitAnimations];
			break;
		}
			
		case NMHalfScreenMode:
		{
			// set to play video in full screen
			if ( animated ) {
				[UIView beginAnimations:nil context:(void *)NM_CONTROL_VIEW_HALF_SCREEN_ANIMATION_CONTEXT];
				[UIView setAnimationBeginsFromCurrentState:YES];
			}
			// set its own size
			viewRect = CGRectMake(self.frame.origin.x + 35.0f, 49.0f, 616.0f, 341.0f);
			self.frame = viewRect;
			// resize the container view
			viewRect = CGRectMake(40.0f, 248.0f, viewRect.size.width - 80.0f, 48.0f);
			controlContainerView.frame = viewRect;
			otherInfoLabel.alpha = 0.0f;
			channelNameLabel.alpha = 0.0f;
			videoTitleLabel.alpha = 0.0f;
			if ( animated ) [UIView commitAnimations];
			// hide stuff
//			otherInfoLabel.hidden = YES;
//			channelNameLabel.hidden = YES;
//			videoTitleLabel.hidden = YES;
			break;
		}
			
		default:
			break;
	}
	playbackMode_ = aMode;
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
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	NSInteger c = (NSInteger)context;
	if ( c == 11111 ) {
		AVPlayer * player = object;
		if ( player.rate > 0.0 ) {
			// set button to play
			playPauseButton.selected = NO;
		} else {
			// set button to pause 
			playPauseButton.selected = YES;
		}
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark properties
- (void)resetView {
	channelNameLabel.text = @"";
	videoTitleLabel.text = @"";
	durationLabel.text = @"--:--";
	currentTimeLabel.text = @"--:--";
	if ( lastVideoMessage ) {
		[lastVideoMessage removeFromSuperview];
		[lastVideoMessage release];
		lastVideoMessage = nil;
	}
	// reset progress bar
	CGRect theFrame = progressBarLayer.bounds;
	theFrame.size.width = 18.0;
	
//	[CATransaction begin];
//	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
//	progressBarLayer.bounds = theFrame;
//	progressBarLayer.position = CGPointMake(0.0, 9.0);
//	nubLayer.position = CGPointMake(9.0, 9.0);
//	progressSlider.value = 0.0f;
//	[CATransaction commit];
	
	self.alpha = 1.0;
	self.hidden = NO;
	[self setControlsHidden:YES animated:NO];
}

- (void)setChannel:(NSString *)cname {
	channelNameLabel.text = cname;
}

- (NSString *)channel {
	return channelNameLabel.text;
}

- (void)setTitle:(NSString *)aTitle {
	videoTitleLabel.text = [aTitle uppercaseString];
}

- (NSString *)title {
	return videoTitleLabel.text;
}

- (void)setDuration:(NSInteger)aDur {
	duration = aDur;
	fduration = (CGFloat)aDur;
	if ( aDur ) {
		pxWidthPerSecond = progressBarWidth / (CGFloat)aDur;
	} else {
		pxWidthPerSecond = 0.0f;
	}
	durationLabel.text = [NSString stringWithFormat:@"%02d:%02d", aDur / 60, aDur % 60];
}

- (void)setTimeElapsed:(NSInteger)aTime {
	timeElapsed = aTime;
//	CGFloat barWidth = floorf(pxWidthPerSecond * aTime) + 9.0; // 9.0 is the offset of the nub radius
//	CGRect theFrame = progressBarLayer.frame;
//	if ( barWidth > theFrame.size.width ) {
//		[CATransaction begin];
//		[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
//		theFrame.size.width = barWidth;
//		progressBarLayer.frame = theFrame;
//		nubLayer.position = CGPointMake(barWidth - 9.0, 9.0);
//		[CATransaction commit];
//	}
	currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", aTime / 60, aTime % 60];
	if ( fduration > 0.0f ) progressSlider.value = ((CGFloat)aTime)/fduration;
}

- (void)setTimeRangeBuffered:(CMTimeRange)aRange {
	NSLog(@"%lld %lld", aRange.start.value / aRange.start.timescale, aRange.duration.value / aRange.duration.timescale);
}

@end
