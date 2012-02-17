//
//  PhoneMovieDetailView.h
//  ipad
//
//  Created by Chris Haugli on 2/13/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMCachedImageView.h"
#import "NMChannel.h"
#import "NMMovieDetailView.h"

@protocol PhoneMovieDetailViewDelegate;
@class PhoneVideoInfoOrientedView;
@class InfiniteScrollView;

@interface PhoneMovieDetailView : NMMovieDetailView {
    PhoneVideoInfoOrientedView *currentOrientedView;
}

@property (nonatomic, retain) IBOutlet PhoneVideoInfoOrientedView *portraitView;
@property (nonatomic, retain) IBOutlet PhoneVideoInfoOrientedView *landscapeView;
@property (nonatomic, assign) BOOL infoPanelExpanded;
@property (nonatomic, assign) id<PhoneMovieDetailViewDelegate> delegate;

- (void)setChannelTitle:(NSString *)channelTitle;
- (void)setVideoTitle:(NSString *)videoTitle;
- (void)setDescriptionText:(NSString *)descriptionText;
- (void)setChannelThumbnailForChannel:(NMChannel *)channel;
- (void)setElapsedTime:(NSInteger)elapsedTime;
- (void)setDuration:(NSInteger)duration;
- (void)setInfoPanelExpanded:(BOOL)isInfoPanelExpanded animated:(BOOL)animated;
- (void)updateViewForInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
- (IBAction)gridButtonPressed:(id)sender;
- (IBAction)playButtonPressed:(id)sender;
- (IBAction)toggleInfoPanel:(id)sender;

@end

// Used to notify the view controller when an action has been performed

@protocol PhoneMovieDetailViewDelegate <NSObject>
@optional
- (void)videoInfoViewDidTapGridButton:(PhoneMovieDetailView *)videoInfoView;
- (void)videoInfoViewDidTapPlayButton:(PhoneMovieDetailView *)videoInfoView;
- (void)videoInfoView:(PhoneMovieDetailView *)videoInfoView didToggleInfoPanelExpanded:(BOOL)expanded;
@end

// A video info view contains two of these, one for portrait and one for landscape.

@interface PhoneVideoInfoOrientedView : UIView

@property (nonatomic, retain) IBOutlet UIView *topView;
@property (nonatomic, retain) IBOutlet UIView *bottomView;
@property (nonatomic, retain) IBOutlet UIView *infoView;
@property (nonatomic, retain) IBOutlet NMCachedImageView *channelThumbnail;
@property (nonatomic, retain) IBOutlet InfiniteScrollView *infoButtonScrollView;
@property (nonatomic, retain) IBOutlet UILabel *channelTitleLabel;
@property (nonatomic, retain) IBOutlet UILabel *videoTitleLabel;
@property (nonatomic, retain) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, retain) IBOutlet UILabel *elapsedTimeLabel;
@property (nonatomic, retain) IBOutlet UILabel *durationLabel;
@property (nonatomic, assign) BOOL infoPanelExpanded;

- (void)positionLabels;
- (void)setInfoPanelExpanded:(BOOL)isInfoPanelExpanded animated:(BOOL)animated;

@end

@interface InfiniteScrollView : UIScrollView <UIScrollViewDelegate>

- (NSInteger)centerViewIndex;

@end