//
//  PanelVideoContainerView.h
//  ipad
//
//  Created by Bill So on 20/06/2011.
//  Copyright 2011 Pipely Inc. All rights reserved.
//


@class NMVideo;

@interface PanelVideoContainerView : UIView {
    UILabel * titleLabel;
	UILabel * datePostedLabel;
	UILabel * durationLabel;
	CGSize titleMaxSize;
}

@property (nonatomic, readonly) UILabel * titleLabel;
@property (nonatomic, readonly) UILabel * datePostedLabel;
@property (nonatomic, readonly) UILabel * durationLabel;

- (void)setVideoInfo:(NMVideo *)aVideo;

@end
