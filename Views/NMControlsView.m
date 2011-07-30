//
//  NMControlsView.m
//  Nowmov
//
//  Created by Bill So on 11/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMControlsView.h"
#import "NMMovieView.h"
#import "NMStyleUtility.h"
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
	styleUtility = [NMStyleUtility sharedStyleUtility];

	playbackMode_ = NMFullScreenPlaybackMode;
	buttonPlayState = YES;
//	[self setPlaybackMode:NMHalfScreenMode animated:NO];
	// top bar view
	topbarContainerView.layer.contents = (id)[UIImage imageNamed:@"playback-top-toolbar-title-background"].CGImage;
	
	channelBackgroundView.layer.contents = (id)[UIImage imageNamed:@"playback-top-toolbar-channel-background"].CGImage;
	channelBackgroundView.layer.contentsCenter = CGRectMake(0.3f, 0.0f, 0.4f, 1.0f);
	//topbarContainerView.alpha = 0.0f;
	// load the progress bar image
	[progressSlider setMinimumTrackImage:[[UIImage imageNamed:@"progress-bright-side"] stretchableImageWithLeftCapWidth:6 topCapHeight:0] forState:UIControlStateNormal];
	[progressSlider setMaximumTrackImage:[[UIImage imageNamed:@"progress-dark-side"] stretchableImageWithLeftCapWidth:6 topCapHeight:0] forState:UIControlStateNormal];
	[progressSlider setThumbImage:[UIImage imageNamed:@"progress-nub"] forState:UIControlStateNormal];
		
}

- (void)dealloc {
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
	} else {
		self.alpha = 1.0;
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
			// set to play video in full screen
			if ( animated ) {
				[UIView beginAnimations:nil context:(void *)NM_CONTROL_VIEW_FULL_SCREEN_ANIMATION_CONTEXT];
				[UIView setAnimationBeginsFromCurrentState:YES];
			}
			// set its own size
			viewRect = CGRectMake(self.frame.origin.x, 0.0f, 1024.0f, 768.0f);
			self.frame = viewRect;
			
			// show the top bar
			topbarContainerView.alpha = 1.0f;
			// change button image
			[channelViewButton setImage:styleUtility.splitScreenImage forState:UIControlStateNormal];
			[channelViewButton setImage:styleUtility.splitScreenActiveImage forState:UIControlStateHighlighted];
			
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
			viewRect = CGRectMake(self.frame.origin.x, 20.0f, 640.0f, 360.0f);
			self.frame = viewRect;
			
			topbarContainerView.alpha = 0.0f;
			[channelViewButton setImage:styleUtility.fullScreenImage forState:UIControlStateNormal];
			[channelViewButton setImage:styleUtility.fullScreenActiveImage forState:UIControlStateHighlighted];
			
			if ( animated ) [UIView commitAnimations];
			break;
		}
			
		default:
			break;
	}
	playbackMode_ = aMode;
}

- (void)setPlayButtonStateForRate:(CGFloat)aRate {
	if ( aRate == 0.0f && !buttonPlayState ) {
		// video is not playing && button not in play state
		// set button to play state
		[playPauseButton setImage:styleUtility.playImage forState:UIControlStateNormal];
		[playPauseButton setImage:styleUtility.playActiveImage forState:UIControlStateHighlighted];
		buttonPlayState = YES;
	} else if ( buttonPlayState ) {
		buttonPlayState = NO;
		[playPauseButton setImage:styleUtility.pauseImage forState:UIControlStateNormal];
		[playPauseButton setImage:styleUtility.pauseActiveImage forState:UIControlStateHighlighted];
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
	progressSlider.value = 0.0f;
	
	self.alpha = 1.0;
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
