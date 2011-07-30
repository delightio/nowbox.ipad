//
//  NMControlsView.h
//  Nowmov
//
//  Created by Bill So on 11/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>
#import <QuartzCore/QuartzCore.h>
#import "ChannelPanelController.h"
#import "NMStyleUtility.h"

@class NMMovieView;


@interface NMControlsView : UIView {
	IBOutlet UILabel * channelNameLabel;
	IBOutlet UILabel * videoTitleLabel;
	IBOutlet UILabel * otherInfoLabel;
	
	IBOutlet UIButton *playPauseButton;
	BOOL buttonPlayState;
	
	IBOutlet UIButton * channelViewButton;
	IBOutlet UIButton *shareButton;
	IBOutlet UILabel * durationLabel;
	IBOutlet UILabel * currentTimeLabel;
	IBOutlet UIView * controlContainerView;
	// top bar
	IBOutlet UIView * channelBackgroundView;
	IBOutlet UIView * topbarContainerView;
	IBOutlet UIButton * subscribeButton;
	
	IBOutlet UISlider * progressSlider;
		
	CGFloat pxWidthPerSecond;
	CGFloat progressBarWidth;
	
	CMTimeRange timeRangeBuffered;
	NSInteger duration;
	NSInteger timeElapsed;
	CGFloat fduration;
	
	UIButton * lastVideoMessage;
	
	NMStyleUtility * styleUtility;
	
	@private
	SEL action;
	id target;
	NMPlaybackViewModeType playbackMode_;
}

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * channel;
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, assign) NSInteger timeElapsed;
@property (nonatomic, assign) CMTimeRange timeRangeBuffered;
@property (nonatomic, readonly) BOOL controlsHidden;

@property (nonatomic, assign) UIButton * channelViewButton;
@property (nonatomic, assign) UIButton * shareButton;
@property (nonatomic, assign) UIButton * playPauseButton;
@property (nonatomic, assign) UIButton * nextVideoButton;

- (void)addTarget:(id)atarget action:(SEL)anAction;

- (void)setPlaybackMode:(NMPlaybackViewModeType)aMode animated:(BOOL)animated;
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)resetView;
- (void)setPlayButtonStateForRate:(CGFloat)aRate;
//- (void)observeMovieView:(NMMovieView *)mvView;
//- (void)stopObservingMovieView:(NMMovieView *)mvView;

- (void)showLastVideoMessage;

@end
