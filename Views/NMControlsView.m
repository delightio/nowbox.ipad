//
//  NMControlsView.m
//  Nowmov
//
//  Created by Bill So on 11/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMControlsView.h"
#import "NMMovieView.h"
#import "NMAirPlayContainerView.h"
#import "NMStyleUtility.h"
#import <QuartzCore/QuartzCore.h>

#define NM_PLAYER_STATUS_CONTEXT		100
#define NM_PLAYER_CURRENT_ITEM_CONTEXT	101
#define NM_PLAYER_PROGRESS_BAR_WIDTH	632


#define NM_CONTROL_VIEW_FULL_SCREEN_ANIMATION_CONTEXT			1001
#define NM_CONTROL_VIEW_HALF_SCREEN_ANIMATION_CONTEXT			1002

#define NM_AUTHOR_SEGMENT_LEFT_INSET							10.0f

@implementation NMControlsView

@synthesize controlDelegate;
@synthesize duration, timeElapsed;
@synthesize channelViewButton, playPauseButton;
@synthesize controlsHidden, timeRangeBuffered;

- (void)awakeFromNib {
	styleUtility = [NMStyleUtility sharedStyleUtility];
	channelDefaultWidth = channelBackgroundView.bounds.size.width;
	authorDefaultWidth = authorBackgroundView.bounds.size.width;
	channelTitleDefaultWidth = channelNameLabel.bounds.size.width;
	authorTitleDefaultWidth = authorNameLabel.bounds.size.width;
	maximumTitleSize = CGSizeMake(256.0f, 40.0f);

	playbackMode_ = NMFullScreenPlaybackMode;
	buttonPlayState = YES;
//	[self setPlaybackMode:NMHalfScreenMode animated:NO];
	// top bar view
	topbarContainerView.layer.shouldRasterize = YES;
	topbarContainerView.layer.contents = (id)[UIImage imageNamed:@"top-bar-title-background"].CGImage;
	
	// channel segment
	channelBackgroundView.layer.shouldRasterize = YES;
	channelBackgroundView.layer.contents = (id)[UIImage imageNamed:@"top-bar-channel-background"].CGImage;
	CGRect theRect = CGRectMake(0.3f, 0.0f, 0.4f, 1.0f);
	channelBackgroundView.layer.contentsCenter = theRect;
	
	CALayer * imgLayer = [CALayer layer];
	imgLayer.shouldRasterize = YES;
	imgLayer.contents = (id)[UIImage imageNamed:@"top-bar-image-frame"].CGImage;
	imgLayer.frame = CGRectMake(17.0f, 7.0f, 29.0f, 29.0f);
	[channelBackgroundView.layer insertSublayer:imgLayer below:channelImageView.layer];
	
	// author segment
	CALayer * imgLayer2 = [CALayer layer];
	imgLayer2.shouldRasterize = YES;
	imgLayer2.frame = CGRectMake(10.0f, 7.0f, 29.0f, 29.0f);
	imgLayer2.contents = imgLayer.contents;
	[authorBackgroundView.layer insertSublayer:imgLayer2 below:authorImageView.layer];
	
	authorBackgroundView.layer.contents = (id)[UIImage imageNamed:@"top-bar-author-background"].CGImage;
	authorBackgroundView.layer.contentsCenter = theRect;
	//topbarContainerView.alpha = 0.0f;
	
	// airplay button
	if ( NM_RUNNING_IOS_5 ) {
		theRect = progressContainerView.frame;
		theRect.size.width -= 61.0f;
		progressContainerView.frame = theRect;
		
		theRect.origin.x += theRect.size.width;
		theRect.size.width = 60.0f;
		NMAirPlayContainerView * theView = [[NMAirPlayContainerView alloc] initWithFrame:theRect];
		theView.controlsView = self;
		theView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		[controlContainerView addSubview:theView];
		
		volumeView = [[MPVolumeView alloc] init];
		[volumeView setShowsVolumeSlider:NO];
		[volumeView sizeToFit];
		volumeView.center = CGPointMake(26.5f, 18.0f);
		[theView addSubview:volumeView];
		
		[theView release];
	}
	
	// load the progress bar image
	[progressSlider setMinimumTrackImage:[[UIImage imageNamed:@"progress-bright-side"] stretchableImageWithLeftCapWidth:6 topCapHeight:0] forState:UIControlStateNormal];
	[progressSlider setMaximumTrackImage:[[UIImage imageNamed:@"progress-dark-side"] stretchableImageWithLeftCapWidth:6 topCapHeight:0] forState:UIControlStateNormal];
	[progressSlider setThumbImage:[UIImage imageNamed:@"progress-nub"] forState:UIControlStateNormal];
		
}

- (void)dealloc {
	[lastVideoMessage release];
	[volumeView release];
    [super dealloc];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch * atouch = [touches anyObject];
	if ( atouch.tapCount == 1 ) {
		CGPoint touchPoint = [atouch locationInView:self];
		if ( !CGRectContainsPoint(controlContainerView.frame, touchPoint) ) {
			// the touch up does NOT happen in the control.
			[target performSelector:action withObject:self];
		}
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
	if ( lastVideoMessage == nil ) {
		lastVideoMessage = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		lastVideoMessage.userInteractionEnabled = NO;
		lastVideoMessage.titleLabel.font = styleUtility.videoTitleFont;
		lastVideoMessage.titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
		CGRect theFrame = CGRectMake(1024.0f - 190.0f, 768.0f / 2.0f, 180.0f, 24.0f);
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

- (void)didTapAirPlayContainerView:(NMAirPlayContainerView *)ctnView {
	if ( volumeView ) {
		[controlDelegate didTapAirPlayContainerView:ctnView];
	}
}

#pragma mark properties
- (void)resetView {
	authorNameLabel.text = @"";
	channelNameLabel.text = @"";
	videoTitleLabel.text = @"";
	durationLabel.text = @"--:--";
	currentTimeLabel.text = @"--:--";
	authorImageView.image = nil;
	channelImageView.image = nil;
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

- (void)updateViewForVideo:(NMVideo *)aVideo {
	NMChannel * chn = aVideo.channel;
	// channel imjage
	[channelImageView setImageForChannel:chn];
	channelNameLabel.text = chn.title;
	// channel width
	CGSize theSize = [channelNameLabel.text sizeWithFont:channelNameLabel.font constrainedToSize:maximumTitleSize];
	CGFloat titleDiff = theSize.width - channelTitleDefaultWidth;
	// set channel segment width
	CGRect theRect = channelBackgroundView.frame;
	theRect.size.width = channelDefaultWidth + titleDiff;
	channelBackgroundView.frame = theRect;
	
	// set author segment position
	theRect = authorBackgroundView.frame;
	theRect.origin.x = channelBackgroundView.frame.size.width;
	// author label
	authorNameLabel.text = aVideo.detail.author_username;	
	// author size
	theSize = [authorNameLabel.text sizeWithFont:authorNameLabel.font constrainedToSize:maximumTitleSize];
	titleDiff = theSize.width - authorTitleDefaultWidth;
	theRect.size.width = authorDefaultWidth + titleDiff;
	authorBackgroundView.frame = theRect;
	// author image
	[authorImageView setImageForAuthorThumbnail:aVideo.detail];
	
	titleDiff = theRect.size.width + theRect.origin.x;
	theRect = videoTitleLabel.frame;
	theRect.origin.x = titleDiff + 10.0f;
	theRect.size.width = 1024.0f - titleDiff - 10.0f - 146.0f;
	videoTitleLabel.frame = theRect;
	videoTitleLabel.text = aVideo.title;
	
	self.duration = [aVideo.duration integerValue];
}

//- (void)setChannel:(NSString *)cname {
//	channelNameLabel.text = cname;
//}
//
//- (NSString *)channel {
//	return channelNameLabel.text;
//}
//
//- (void)setTitle:(NSString *)aTitle {
//	videoTitleLabel.text = [aTitle uppercaseString];
//}
//
//- (NSString *)title {
//	return videoTitleLabel.text;
//}

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
