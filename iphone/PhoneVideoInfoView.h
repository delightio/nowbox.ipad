//
//  PhoneVideoInfoView.h
//  ipad
//
//  Created by Chris Haugli on 2/13/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMCachedImageView.h"
#import "NMChannel.h"

@protocol PhoneVideoInfoViewDelegate;
@class PhoneVideoInfoOrientedView;
@class InfiniteScrollView;

@interface PhoneVideoInfoView : UIView {
    PhoneVideoInfoOrientedView *currentOrientedView;
}

@property (nonatomic, retain) IBOutlet PhoneVideoInfoOrientedView *portraitView;
@property (nonatomic, retain) IBOutlet PhoneVideoInfoOrientedView *landscapeView;
@property (nonatomic, assign) id<PhoneVideoInfoViewDelegate> delegate;

- (void)setChannelTitle:(NSString *)channelTitle;
- (void)setVideoTitle:(NSString *)videoTitle;
- (void)setDescriptionText:(NSString *)descriptionText;
- (void)setChannelThumbnailForChannel:(NMChannel *)channel;
- (void)setElapsedTime:(NSInteger)elapsedTime;
- (void)setDuration:(NSInteger)duration;
- (void)updateViewForInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
- (IBAction)gridButtonPressed:(id)sender;
- (IBAction)playButtonPressed:(id)sender;
- (IBAction)toggleInfoPanel:(id)sender;

@end

// Used to notify the view controller when an action has been performed

@protocol PhoneVideoInfoViewDelegate <NSObject>
@optional
- (void)videoInfoViewDidTapGridButton:(PhoneVideoInfoView *)videoInfoView;
- (void)videoInfoViewDidTapPlayButton:(PhoneVideoInfoView *)videoInfoView;
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

- (void)positionLabels;
- (void)toggleInfoPanel;

@end

@interface InfiniteScrollView : UIScrollView <UIScrollViewDelegate>

- (NSInteger)centerViewIndex;

@end