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
#import "NMAVPlayerItem.h"
#import "NMStyleUtility.h"
#import <QuartzCore/QuartzCore.h>

#define NM_PLAYER_STATUS_CONTEXT		100
#define NM_PLAYER_CURRENT_ITEM_CONTEXT	101
#define NM_PLAYER_PROGRESS_BAR_WIDTH	632


#define NM_CONTROL_VIEW_FULL_SCREEN_ANIMATION_CONTEXT			1001
#define NM_CONTROL_VIEW_HALF_SCREEN_ANIMATION_CONTEXT			1002

#define NM_AUTHOR_SEGMENT_LEFT_INSET							10.0f

@implementation NMControlsView
@synthesize airPlayIndicatorView;

@synthesize controlDelegate;
@synthesize duration, timeElapsed;
@synthesize channelViewButton, playPauseButton;
@synthesize controlsHidden, timeRangeBuffered;
@synthesize seekBubbleButton, isSeeking;
@synthesize favoriteButton, watchLaterButton;
@synthesize controlContainerView;
@synthesize topbarContainerView;
@synthesize progressSlider;
@synthesize playbackMode=playbackMode_;

- (void)awakeFromNib {
	styleUtility = [NMStyleUtility sharedStyleUtility];
	channelDefaultWidth = segmentChannelButton.bounds.size.width;
	authorDefaultWidth = authorBackgroundView.bounds.size.width;
	channelTitleDefaultWidth = [[segmentChannelButton titleForState:UIControlStateNormal] sizeWithFont:segmentChannelButton.titleLabel.font].width;
	authorTitleDefaultWidth = authorNameLabel.bounds.size.width;
	maximumTitleSize = CGSizeMake(256.0f, 40.0f);

	playbackMode_ = NMFullScreenPlaybackMode;
	buttonPlayState = NO;
//	[self setPlaybackMode:NMHalfScreenMode animated:NO];
	// top bar view
	topbarContainerView.layer.shouldRasterize = YES;
	topbarContainerView.layer.contents = (id)[UIImage imageNamed:@"top-bar-title-background"].CGImage;
	
	// channel segment
//	channelBackgroundView.layer.shouldRasterize = YES;
//	channelBackgroundView.layer.contents = (id)[UIImage imageNamed:@"top-bar-channel-background"].CGImage;
	CGRect theRect = CGRectMake(0.3f, 0.0f, 0.4f, 1.0f);
//	channelBackgroundView.layer.contentsCenter = theRect;
	[segmentChannelButton setBackgroundImage:[[UIImage imageNamed:@"top-bar-channel-background"] stretchableImageWithLeftCapWidth:12 topCapHeight:0] forState:UIControlStateNormal];
	
	CALayer * imgLayer = [CALayer layer];
	imgLayer.shouldRasterize = YES;
	imgLayer.contents = (id)[UIImage imageNamed:@"top-bar-image-frame"].CGImage;
	imgLayer.frame = CGRectMake(13.0f, 7.0f, 29.0f, 29.0f);
	[segmentChannelButton.layer insertSublayer:imgLayer below:channelImageView.layer];
	
	// author segment
	CALayer * imgLayer2 = [CALayer layer];
	imgLayer2.shouldRasterize = YES;
	imgLayer2.frame = CGRectMake(19.0f, 7.0f, 29.0f, 29.0f);
	imgLayer2.contents = imgLayer.contents;
	[authorBackgroundView.layer insertSublayer:imgLayer2 below:authorImageView.layer];
	
	authorBackgroundView.layer.contents = (id)[UIImage imageNamed:@"top-bar-author-background"].CGImage;
	authorBackgroundView.layer.contentsCenter = theRect;
	//topbarContainerView.alpha = 0.0f;
	
	// airplay button
	if ( NM_RUNNING_IOS_5 ) {
		theRect = progressContainerView.frame;
		theRect.size.width -= (NM_RUNNING_ON_IPAD ? 61.0f : 31.0f);
		progressContainerView.frame = theRect;
		
		theRect.origin.x += (NM_RUNNING_ON_IPAD ? theRect.size.width : theRect.size.width - 20.0f);
		theRect.size.width = 60.0f;
        
		airPlayContainerView = [[NMAirPlayContainerView alloc] initWithFrame:theRect];
		airPlayContainerView.controlsView = self;
		airPlayContainerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		[controlContainerView addSubview:airPlayContainerView];
		
		volumeView = [[MPVolumeView alloc] init];
		[volumeView setShowsVolumeSlider:NO];
		[volumeView sizeToFit];
		volumeView.center = CGPointMake(26.5f, 18.0f);
		[airPlayContainerView addSubview:volumeView];
		
		[airPlayContainerView release];
	} else {
		videoTitleLabel.font = [NMStyleUtility sharedStyleUtility].videoDetailFont;
	}
	
	// load the progress bar image
	sliderRect = CGRectMake(126.0, 0.0, NM_RUNNING_IOS_5 ? 712.0f : 772.0f, 0.0f);
	
	// hide the bubble
	seekBubbleButton.alpha = 0.0f;
}

- (void)dealloc {
	[lastVideoMessage release];
	[volumeView release];
    [airPlayIndicatorView release];
    [progressSlider release];
    [super dealloc];
}

//- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//	UITouch * atouch = [touches anyObject];
//	if ( atouch.tapCount == 1 ) {
//		CGPoint touchPoint = [atouch locationInView:self];
//		if ( !CGRectContainsPoint(controlContainerView.frame, touchPoint) ) {
//			// the touch up does NOT happen in the control.
//			[target performSelector:action withObject:self];
//			return;
//		}
//	}
//	[super touchesEnded:touches withEvent:event];
//}

//- (void)addTarget:(id)atarget action:(SEL)anAction {
//	target = atarget;
//	action = anAction;
//}

- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated {
	if ( animated ) {
		[UIView beginAnimations:nil context:nil];
	}
	if ( hidden ) {
		self.alpha = 0.0;
	} else if ( !hidden ) {
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

- (void)setTopBarHidden:(BOOL)hidden animated:(BOOL)animated {
	if ( animated ) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDelay:0.1f];
	}
	if ( hidden ) {
		// set top bar to hidden
		topbarContainerView.alpha = 0.0f;
	} else {
		topbarContainerView.alpha = 1.0f;
	}
	if ( animated ) [UIView commitAnimations];
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
			sliderRect = CGRectMake(126.0, 0.0, NM_RUNNING_IOS_5 ? 712.0f : 772.0f, 0.0f);
			
			// show the top bar
//			topbarContainerView.alpha = 1.0f;
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
			sliderRect = CGRectMake(126.0, 0.0, NM_RUNNING_IOS_5 ? 328.0f : 388.0f, 0.0f);
			
//			topbarContainerView.alpha = 0.0f;
			[channelViewButton setImage:styleUtility.fullScreenImage forState:UIControlStateNormal];
			[channelViewButton setImage:styleUtility.fullScreenActiveImage forState:UIControlStateHighlighted];
			
			if ( animated ) [UIView commitAnimations];
			break;
		}
			
		default:
			break;
	}
	playbackMode_ = aMode;
	self.alpha = 0.0f;
}

- (void)setPlayButtonStateForRate:(CGFloat)aRate {
	if ( aRate == 0.0f && !buttonPlayState ) {
		// video is not playing && button not in play state
		// set button to play state
		[playPauseButton setImage:styleUtility.playImage forState:UIControlStateNormal];
		[playPauseButton setImage:styleUtility.playActiveImage forState:UIControlStateHighlighted];
		buttonPlayState = YES;
        if (NM_RUNNING_ON_IPAD) {
            [self setControlsHidden:NO animated:YES];
        }
	} else if ( aRate > 0.0f && buttonPlayState ) {
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

- (void)updateSeekBubbleLocation {
	CGPoint thePoint = seekBubbleButton.center;
    if (NM_RUNNING_ON_IPAD) {
        thePoint.x = progressSlider.nubPosition.x + sliderRect.origin.x - 1;
    } else {
        thePoint.x = [progressSlider convertPoint:progressSlider.nubPosition toView:self].x;
    }
	seekBubbleButton.center = thePoint;
}

#pragma mark properties
- (void)resetView {
	authorNameLabel.text = @"";
//	channelNameLabel.text = @"";
	[segmentChannelButton setTitle:@"" forState:UIControlStateNormal];
	videoTitleLabel.text = @"";
	durationLabel.text = (NM_RUNNING_ON_IPAD ? @"--:--" : @"00:00");
	currentTimeLabel.text = (NM_RUNNING_ON_IPAD ? @"--:--" : @"00:00");
	authorImageView.image = nil;
	channelImageView.image = nil;
	if ( lastVideoMessage ) {
		[lastVideoMessage removeFromSuperview];
		[lastVideoMessage release];
		lastVideoMessage = nil;
	}
	// reset progress bar
	progressSlider.duration = 0;
	
    if (NM_RUNNING_ON_IPAD) {
        self.alpha = 1.0;
        [self setControlsHidden:YES animated:NO];
    }
}

- (void)updateViewForVideo:(NMVideo *)aVideo {
	NMChannel * chn = aVideo.channel;
	// channel image
	[channelImageView setImageForChannel:chn];
	[segmentChannelButton setTitle:chn.title forState:UIControlStateNormal];
	// channel width
	CGSize theSize = [chn.title sizeWithFont:segmentChannelButton.titleLabel.font constrainedToSize:maximumTitleSize];
	CGFloat titleDiff = theSize.width - channelTitleDefaultWidth;
	// set channel segment width
	CGRect theRect = segmentChannelButton.frame;
	theRect.size.width = channelDefaultWidth + titleDiff;
	segmentChannelButton.frame = theRect;
	
	NMConcreteVideo * realVideo = aVideo.video;
	// check whether we should hide the author segment
	if ( [chn.thumbnail_uri isEqualToString:realVideo.author.thumbnail_uri] ) {
		authorBackgroundView.hidden = YES;
	} else {
		NMAuthor * theAuthor = realVideo.author;
		authorBackgroundView.hidden = NO;
		// set author segment position
		theRect = authorBackgroundView.frame;
		theRect.origin.x = segmentChannelButton.frame.size.width - 10.0f;
		// author label
		authorNameLabel.text = theAuthor.username;	
		// author size
		theSize = [authorNameLabel.text sizeWithFont:authorNameLabel.font constrainedToSize:maximumTitleSize];
		titleDiff = theSize.width - authorTitleDefaultWidth;
		theRect.size.width = authorDefaultWidth + titleDiff;
		authorBackgroundView.frame = theRect;
		// author image
		[authorImageView setImageForAuthorThumbnail:theAuthor];
	}
	
	titleDiff = theRect.size.width + theRect.origin.x;
	theRect = videoTitleLabel.frame;
	theRect.origin.x = titleDiff + 10.0f;
	theRect.size.width = 1024.0f - titleDiff - 10.0f - 146.0f;
	videoTitleLabel.frame = theRect;
	videoTitleLabel.text = realVideo.title;
	
#ifdef DEBUG_PLAYER_NAVIGATION
	NSLog(@"control view, duration: %d", [realVideo.duration integerValue]);
#endif
	self.duration = [realVideo.duration integerValue];
	NSValue * theRangeValue = [realVideo.nm_player_item.loadedTimeRanges lastObject];
	if ( theRangeValue ) {
		self.timeRangeBuffered = [theRangeValue CMTimeRangeValue];
	}
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
	//fduration = (CGFloat)aDur;
//	if ( aDur ) {
//		pxWidthPerSecond = progressBarWidth / (CGFloat)aDur;
//	} else {
//		pxWidthPerSecond = 0.0f;
//	}
	durationLabel.text = [NSString stringWithFormat:@"%02d:%02d", aDur / 60, aDur % 60];
	progressSlider.duration = aDur;
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
	if ( isSeeking ) {
		[seekBubbleButton setTitle:currentTimeLabel.text forState:UIControlStateNormal];
	}
	if ( !isSeeking && duration > 0.0f ) progressSlider.currentTime = aTime;
}

- (void)setTimeRangeBuffered:(CMTimeRange)aRange {
	progressSlider.bufferTime = (NSInteger)CMTimeGetSeconds(CMTimeAdd(aRange.start, aRange.duration));
}

#pragma mark Gesture delegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	// do not even begin recognizing the gesture
	CGPoint thePoint = [gestureRecognizer locationInView:self];
	if ( CGRectContainsPoint(controlContainerView.frame, thePoint) || CGRectContainsPoint(topbarContainerView.frame, thePoint) ) {
		return NO;
	}
	return YES;
}

@end
