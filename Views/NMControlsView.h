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
	IBOutlet UIButton *authorButton;
	IBOutlet UIButton *socialLoginButton;
	IBOutlet UIButton *prevVideoButton;
	IBOutlet UIButton *nextVideoButton;
	IBOutlet UIButton *playPauseButton;
	IBOutlet UIButton *channelViewButton;
	IBOutlet UIButton *shareButton;
	IBOutlet UILabel * durationLabel;
	IBOutlet UILabel * currentTimeLabel;
	IBOutlet UIImageView *progressView;
	
	CALayer * progressBarLayer;
	CGFloat pxWidthPerSecond;
	CGFloat progressBarWidth;
	
	NSString * authorProfileURLString;
	CMTimeRange timeRangeBuffered;
	
	SEL action;
	id target;
}

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * authorProfileURLString;
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, assign) NSInteger timeElapsed;
@property (nonatomic, assign) CMTimeRange timeRangeBuffered;
@property (nonatomic, readonly) BOOL controlsHidden;

@property (nonatomic, assign) UIButton * channelViewButton;
@property (nonatomic, assign) UIButton * shareButton;
@property (nonatomic, assign) UIButton * playPauseButton;
@property (nonatomic, assign) UIButton * nextVideoButton;

- (void)addTarget:(id)atarget action:(SEL)anAction;

- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)setChannel:(NSString *)cname author:(NSString *)authName;
- (void)resetView;
//- (void)observeMovieView:(NMMovieView *)mvView;
//- (void)stopObservingMovieView:(NMMovieView *)mvView;

- (IBAction)goToAuthorProfilePage:(id)sender;

@end
