//
//  PhoneVideoInfoOrientedView.h
//  ipad
//
//  Created by Chris Haugli on 2/21/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMCachedImageView.h"

@protocol PhoneVideoInfoOrientedViewDelegate;
@class InfiniteScrollView;

// A movie detail view contains two of these, one for portrait and one for landscape.
@interface PhoneVideoInfoOrientedView : UIView <UIScrollViewDelegate> {
    CGRect originalVideoTitleFrame;
}

@property (nonatomic, retain) IBOutlet UIView *topView;
@property (nonatomic, retain) IBOutlet UIView *bottomView;
@property (nonatomic, retain) IBOutlet UIView *infoView;
@property (nonatomic, retain) IBOutlet UIView *buzzView;
@property (nonatomic, retain) IBOutlet NMCachedImageView *channelThumbnail;
@property (nonatomic, retain) IBOutlet InfiniteScrollView *infoButtonScrollView;
@property (nonatomic, retain) IBOutlet UILabel *channelTitleLabel;
@property (nonatomic, retain) IBOutlet UILabel *videoTitleLabel;
@property (nonatomic, retain) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, retain) IBOutlet UIButton *moreVideosButton;
@property (nonatomic, retain) IBOutlet UIImageView *buzzBackgroundImage;
@property (nonatomic, assign) BOOL infoPanelExpanded;
@property (nonatomic, assign) BOOL buzzPanelExpanded;
@property (nonatomic, assign) IBOutlet id<PhoneVideoInfoOrientedViewDelegate> delegate;

- (void)positionLabels;
- (void)setInfoPanelExpanded:(BOOL)isInfoPanelExpanded animated:(BOOL)animated;
- (void)setBuzzPanelExpanded:(BOOL)isBuzzPanelExpanded animated:(BOOL)animated;
@end

@protocol PhoneVideoInfoOrientedViewDelegate <NSObject>
- (void)phoneVideoInfoOrientedView:(PhoneVideoInfoOrientedView *)view willBeginDraggingWithScrollView:(UIScrollView *)scrollView;
- (void)phoneVideoInfoOrientedView:(PhoneVideoInfoOrientedView *)view didEndDraggingWithScrollView:(UIScrollView *)scrollView;
@end

@interface InfiniteScrollView : UIScrollView

- (NSInteger)centerViewIndex;
- (void)centerContentOffset;

@end