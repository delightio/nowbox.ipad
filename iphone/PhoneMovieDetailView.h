//
//  PhoneMovieDetailView.h
//  ipad
//
//  Created by Chris Haugli on 2/13/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMMovieDetailView.h"
#import "NMChannel.h"
#import "PhoneVideoInfoOrientedView.h"
#import "PhoneControlsView.h"

@protocol PhoneMovieDetailViewDelegate;

@interface PhoneMovieDetailView : NMMovieDetailView <PhoneVideoInfoOrientedViewDelegate, BuzzViewDelegate> {
    PhoneVideoInfoOrientedView *currentOrientedView;
}

@property (nonatomic, retain) IBOutlet PhoneVideoInfoOrientedView *portraitView;
@property (nonatomic, retain) IBOutlet PhoneVideoInfoOrientedView *landscapeView;
@property (nonatomic, retain) IBOutlet PhoneControlsView *controlsView;
@property (nonatomic, assign) BOOL infoPanelExpanded;
@property (nonatomic, assign) BOOL buzzPanelExpanded;
@property (nonatomic, assign) BOOL videoOverlayHidden;
@property (nonatomic, assign) id<PhoneMovieDetailViewDelegate> delegate;

- (void)setInfoPanelExpanded:(BOOL)isInfoPanelExpanded animated:(BOOL)animated;
- (void)setBuzzPanelExpanded:(BOOL)buzzPanelExpanded animated:(BOOL)animated;
- (void)setVideoOverlayHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)setWatchLater:(BOOL)watchLater;
- (void)setFavorite:(BOOL)favorite;
- (void)updateViewForInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
- (IBAction)gridButtonPressed:(id)sender;
- (IBAction)playButtonPressed:(id)sender;
- (IBAction)thumbnailPressed:(id)sender;
- (IBAction)seekBarValueChanged:(id)sender;
- (IBAction)seekBarTouchDown:(id)sender;
- (IBAction)seekBarTouchUp:(id)sender;
- (IBAction)toggleInfoPanel:(id)sender;
- (IBAction)toggleBuzzPanel:(id)sender;

@end

// Used to notify the view controller when an action has been performed

@protocol PhoneMovieDetailViewDelegate <NSObject>
@optional
- (void)videoInfoViewDidTapGridButton:(PhoneMovieDetailView *)videoInfoView;
- (void)videoInfoViewDidTapPlayButton:(PhoneMovieDetailView *)videoInfoView;
- (void)videoInfoViewDidTapLikeButton:(PhoneMovieDetailView *)videoInfoView;
- (void)videoInfoViewDidTapThumbnail:(PhoneMovieDetailView *)videoInfoView;
- (void)videoInfoView:(PhoneMovieDetailView *)videoInfoView didSeek:(NMSeekBar *)seekBar;
- (void)videoInfoView:(PhoneMovieDetailView *)videoInfoView didTouchDownSeekBar:(NMSeekBar *)seekBar;
- (void)videoInfoView:(PhoneMovieDetailView *)videoInfoView didTouchUpSeekBar:(NMSeekBar *)seekBar;
- (void)videoInfoView:(PhoneMovieDetailView *)videoInfoView didToggleInfoPanelExpanded:(BOOL)expanded;
- (void)videoInfoView:(PhoneMovieDetailView *)videoInfoView didToggleBuzzPanelExpanded:(BOOL)expanded;
- (void)videoInfoView:(PhoneMovieDetailView *)videoInfoView willBeginDraggingScrollView:(UIScrollView *)scrollView;
- (void)videoInfoView:(PhoneMovieDetailView *)videoInfoView didEndDraggingScrollView:(UIScrollView *)scrollView;
@end
