//
//  PhoneVideoInfoOrientedView.h
//  ipad
//
//  Created by Chris Haugli on 2/21/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BuzzView.h"
#import "GlowLabel.h"

@protocol PhoneVideoInfoOrientedViewDelegate;
@class InfiniteScrollView;

// A movie detail view contains two of these, one for portrait and one for landscape.
@interface PhoneVideoInfoOrientedView : UIView <UIScrollViewDelegate> {
    CGRect originalVideoTitleFrame;
    CGRect originalDescriptionFrame;
    UIButton *mostRecentActionButton;
}

@property (nonatomic, retain) IBOutlet UIView *topView;
@property (nonatomic, retain) IBOutlet UIView *bottomView;
@property (nonatomic, retain) IBOutlet UIView *infoView;
@property (nonatomic, retain) IBOutlet BuzzView *buzzView;
@property (nonatomic, retain) IBOutlet UIView *authorThumbnailPlaceholder;
@property (nonatomic, retain) IBOutlet UIScrollView *infoScrollView;
@property (nonatomic, retain) IBOutlet InfiniteScrollView *infoButtonScrollView;
@property (nonatomic, retain) IBOutlet GlowLabel *channelTitleLabel;
@property (nonatomic, retain) IBOutlet UILabel *videoTitleLabel;
@property (nonatomic, retain) IBOutlet UIView *descriptionLabelContainer;
@property (nonatomic, retain) IBOutlet UILabel *authorLabel;
@property (nonatomic, retain) IBOutlet UILabel *dateLabel;
@property (nonatomic, retain) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, retain) IBOutlet UIButton *moreVideosButton;
@property (nonatomic, retain) IBOutlet UIButton *watchLaterButton;
@property (nonatomic, retain) IBOutlet UIButton *shareButton;
@property (nonatomic, retain) IBOutlet UIButton *favoriteButton;
@property (nonatomic, retain) IBOutlet UIButton *toggleInfoPanelButton;
@property (nonatomic, assign) BOOL infoPanelExpanded;
@property (nonatomic, assign) BOOL buzzPanelExpanded;
@property (nonatomic, assign) IBOutlet id<PhoneVideoInfoOrientedViewDelegate> delegate;

- (void)positionLabels;
- (void)setTopActionButtonIndex:(NSUInteger)actionButtonIndex;
- (void)setInfoPanelExpanded:(BOOL)isInfoPanelExpanded animated:(BOOL)animated;
- (void)setBuzzPanelExpanded:(BOOL)isBuzzPanelExpanded animated:(BOOL)animated;
- (void)setWatchLater:(BOOL)watchLater;
- (void)setFavorite:(BOOL)favorite;
- (IBAction)actionButtonPressed:(id)sender;

@end

@protocol PhoneVideoInfoOrientedViewDelegate <NSObject>
- (void)phoneVideoInfoOrientedView:(PhoneVideoInfoOrientedView *)view willBeginDraggingWithScrollView:(UIScrollView *)scrollView;
- (void)phoneVideoInfoOrientedView:(PhoneVideoInfoOrientedView *)view didEndDraggingWithScrollView:(UIScrollView *)scrollView;
@end

@interface InfiniteScrollView : UIScrollView

- (NSInteger)centerViewIndex;
- (void)centerViewAtIndex:(NSUInteger)index;
- (void)centerViewAtIndex:(NSUInteger)index avoidMovingViewsToAbove:(BOOL)avoidMovingAbove;
- (void)centerContentOffset;

@end