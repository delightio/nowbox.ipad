//
//  PhoneMovieDetailView.h
//  ipad
//
//  Created by Chris Haugli on 2/13/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMMovieDetailView.h"
#import "NMCachedImageView.h"
#import "NMControlsView.h"
#import "NMChannel.h"

@protocol PhoneMovieDetailViewDelegate;
@class PhoneVideoInfoOrientedView;
@class InfiniteScrollView;

@interface PhoneMovieDetailView : NMMovieDetailView {
    PhoneVideoInfoOrientedView *currentOrientedView;
}

@property (nonatomic, retain) IBOutlet PhoneVideoInfoOrientedView *portraitView;
@property (nonatomic, retain) IBOutlet PhoneVideoInfoOrientedView *landscapeView;
@property (nonatomic, retain) IBOutlet NMControlsView *controlsView;
@property (nonatomic, assign) BOOL infoPanelExpanded;
@property (nonatomic, assign) BOOL videoOverlayHidden;
@property (nonatomic, assign) id<PhoneMovieDetailViewDelegate> delegate;

- (void)setChannelTitle:(NSString *)channelTitle;
- (void)setVideoTitle:(NSString *)videoTitle;
- (void)setDescriptionText:(NSString *)descriptionText;
- (void)setChannelThumbnailForChannel:(NMChannel *)channel;
- (void)setInfoPanelExpanded:(BOOL)isInfoPanelExpanded animated:(BOOL)animated;
- (void)setVideoOverlayHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)updateViewForInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
- (IBAction)gridButtonPressed:(id)sender;
- (IBAction)playButtonPressed:(id)sender;
- (IBAction)seekBarValueChanged:(id)sender;
- (IBAction)seekBarTouchDown:(id)sender;
- (IBAction)seekBarTouchUp:(id)sender;
- (IBAction)toggleInfoPanel:(id)sender;

@end

// Used to notify the view controller when an action has been performed

@protocol PhoneMovieDetailViewDelegate <NSObject>
@optional
- (void)videoInfoViewDidTapGridButton:(PhoneMovieDetailView *)videoInfoView;
- (void)videoInfoViewDidTapPlayButton:(PhoneMovieDetailView *)videoInfoView;
- (void)videoInfoView:(PhoneMovieDetailView *)videoInfoView didSeek:(NMSeekBar *)seekBar;
- (void)videoInfoView:(PhoneMovieDetailView *)videoInfoView didTouchDownSeekBar:(NMSeekBar *)seekBar;
- (void)videoInfoView:(PhoneMovieDetailView *)videoInfoView didTouchUpSeekBar:(NMSeekBar *)seekBar;
- (void)videoInfoView:(PhoneMovieDetailView *)videoInfoView didToggleInfoPanelExpanded:(BOOL)expanded;
@end

// A video info view contains two of these, one for portrait and one for landscape.

@interface PhoneVideoInfoOrientedView : UIView {
    CGRect originalVideoTitleFrame;
}

@property (nonatomic, retain) IBOutlet UIView *topView;
@property (nonatomic, retain) IBOutlet UIView *bottomView;
@property (nonatomic, retain) IBOutlet UIView *infoView;
@property (nonatomic, retain) IBOutlet NMCachedImageView *channelThumbnail;
@property (nonatomic, retain) IBOutlet InfiniteScrollView *infoButtonScrollView;
@property (nonatomic, retain) IBOutlet UILabel *channelTitleLabel;
@property (nonatomic, retain) IBOutlet UILabel *videoTitleLabel;
@property (nonatomic, retain) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, assign) BOOL infoPanelExpanded;

- (void)positionLabels;
- (void)setInfoPanelExpanded:(BOOL)isInfoPanelExpanded animated:(BOOL)animated;

@end

@interface InfiniteScrollView : UIScrollView <UIScrollViewDelegate>

- (NSInteger)centerViewIndex;

@end