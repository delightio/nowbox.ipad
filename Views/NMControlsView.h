//
//  NMControlsView.h
//  Nowmov
//
//  Created by Bill So on 11/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import "ChannelPanelController.h"
#import "NMStyleUtility.h"
#import "NMCachedImageView.h"
#import "NMSeekBar.h"

@class NMMovieView;
@class NMAirPlayContainerView;

@protocol NMControlsViewDelegate <NSObject>

- (void)didTapAirPlayContainerView:(NMAirPlayContainerView *)ctnView;

@end


@interface NMControlsView : UIView <UIGestureRecognizerDelegate> {
	IBOutlet UILabel * videoTitleLabel;
	IBOutlet UILabel * otherInfoLabel;
	
	IBOutlet UIButton *playPauseButton;
	BOOL buttonPlayState;
	
	// seek label
	IBOutlet UIButton * seekBubbleButton;
	BOOL isSeeking;
	// playback control
	IBOutlet UIButton * channelViewButton;
	IBOutlet UILabel * durationLabel;
	IBOutlet UILabel * currentTimeLabel;
	IBOutlet UIView * progressContainerView;
    NMAirPlayContainerView * airPlayContainerView;
	MPVolumeView * volumeView;
	// top bar
//	IBOutlet UILabel * channelNameLabel;
	IBOutlet UILabel * authorNameLabel;
	IBOutlet NMCachedImageView * channelImageView;
	IBOutlet NMCachedImageView * authorImageView;
//	IBOutlet UIView * channelBackgroundView;
	IBOutlet UIView * authorBackgroundView;
	IBOutlet UIView * topbarContainerView;
	IBOutlet UIButton * segmentChannelButton;
	UIButton * favoriteButton;
	UIButton * watchLaterButton;
    
	// segment width
	CGFloat channelDefaultWidth, authorDefaultWidth;
	CGFloat channelTitleDefaultWidth, authorTitleDefaultWidth;
	CGSize maximumTitleSize;
	
	IBOutlet NMSeekBar * progressSlider;
	CGRect sliderRect;
		
//	CGFloat pxWidthPerSecond;
//	CGFloat progressBarWidth;
	
	CMTimeRange timeRangeBuffered;
	NSInteger duration;
	NSInteger timeElapsed;
	CGFloat fduration;
	
	UIButton * lastVideoMessage;
	
	NMStyleUtility * styleUtility;
	
	id<NMControlsViewDelegate> controlDelegate;
	
	@private
//	SEL action;
//	id target;
	NMPlaybackViewModeType playbackMode_;
}

@property (nonatomic, assign) id<NMControlsViewDelegate> controlDelegate;
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, assign) NSInteger timeElapsed;
@property (nonatomic, assign) CMTimeRange timeRangeBuffered;
@property (nonatomic, readonly) BOOL controlsHidden;
@property (nonatomic, readonly) NMPlaybackViewModeType playbackMode;

@property (nonatomic, assign) UIButton * channelViewButton;
@property (nonatomic, assign) UIButton * playPauseButton;
@property (nonatomic, retain) UIButton * seekBubbleButton;
@property (nonatomic, assign) IBOutlet UIButton * favoriteButton;
@property (nonatomic, assign) IBOutlet UIButton * watchLaterButton;
@property (nonatomic, assign) IBOutlet UIView * controlContainerView;

//@property (nonatomic, readonly) IBOutlet UIView * channelBackgroundView;
//@property (nonatomic, readonly) IBOutlet UIView * authorBackgroundView;
@property (nonatomic, assign) IBOutlet UIView * topbarContainerView;

@property (retain, nonatomic) IBOutlet UIView *airPlayIndicatorView;
@property (retain, nonatomic) IBOutlet UIButton *toggleGridButton;
@property (nonatomic, assign) BOOL isSeeking;

//- (void)addTarget:(id)atarget action:(SEL)anAction;

- (void)setPlaybackMode:(NMPlaybackViewModeType)aMode animated:(BOOL)animated;
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)resetView;
- (void)updateViewForVideo:(NMVideo *)aVideo;
- (void)setTopBarHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)setPlayButtonStateForRate:(CGFloat)aRate;

- (void)showLastVideoMessage;
- (void)didTapAirPlayContainerView:(NMAirPlayContainerView *)ctnView;

// bubble
- (void)updateSeekBubbleLocation;
- (void)setToggleGridButtonHidden:(BOOL)hidden;

@end
