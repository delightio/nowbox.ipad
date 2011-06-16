//
//  NMControlsView.h
//  Nowmov
//
//  Created by Bill So on 11/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>
#import <QuartzCore/QuartzCore.h>

@class NMMovieView;


@interface NMControlsView : UIView {
	IBOutlet UILabel * channelNameLabel;
	IBOutlet UILabel * videoTitleLabel;
	IBOutlet UILabel * onLabel;
	IBOutlet UIButton *playPauseButton;
	IBOutlet UIButton *shareButton;
	IBOutlet UIButton *voteUpButton;
	IBOutlet UILabel * durationLabel;
	IBOutlet UILabel * currentTimeLabel;
	IBOutlet UIImageView *progressView;
	
	CALayer * progressBarLayer;
	CALayer * nubLayer;
	CGFloat pxWidthPerSecond;
	CGFloat progressBarWidth;
	
	CMTimeRange timeRangeBuffered;
	NSInteger duration;
	NSInteger timeElapsed;
	
	UIButton * lastVideoMessage;
	
	SEL action;
	id target;
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
@property (nonatomic, assign) UIButton * voteUpButton;
@property (nonatomic, assign) UIButton * voteDownButton;

- (void)addTarget:(id)atarget action:(SEL)anAction;

- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)resetView;
//- (void)observeMovieView:(NMMovieView *)mvView;
//- (void)stopObservingMovieView:(NMMovieView *)mvView;

- (void)showLastVideoMessage;

@end
