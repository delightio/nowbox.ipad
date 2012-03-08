//
//  NMStyleUtility.h
//  ipad
//
//  Created by Bill So on 16/06/2011.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NMStyleUtility : NSObject {
    NSDateFormatter * videoDateFormatter;
	NSNumberFormatter * viewCountFormatter;
	// video detail
	UIFont * channelNameFont, * videoTitleFont, * videoDetailFont;
	UIColor * videoTitleFontColor, * videoTitleHighlightedFontColor, * videoTitlePlayedFontColor;
	UIColor * videoDetailFontColor;
    UIColor * videoDetailHighlightedFontColor;
    UIColor * videoDetailPlayedFontColor;
	UIColor * clearColor, * channelPanelFontColor;
	UIImage * videoShadowImage;
//	UIImage * videoHighlightedBackgroundImage, * videoNormalBackgroundImage, * videoDimmedBackgroundImage;
    UIImage * videoStatusBadImage, * videoStatusHotImage, * videoStatusFavImage, * videoStatusQueuedImage;
    UIImage * videoNewSessionIndicatorImage;
	// channel panel
	UIColor * channelPanelBackgroundColor;
	UIColor * channelPanelHighlightColor;
	UIColor * channelPanelPlayedColor;
    
    UIColor * channelPanelCellDefaultBackgroundStart;
    UIColor * channelPanelCellDefaultBackgroundEnd;
    UIColor * channelPanelCellDefaultTopBorder;
    UIColor * channelPanelCellDefaultBottomBorder;
    UIColor * channelPanelCellDefaultDivider;
    UIColor * channelPanelCellHighlightedBackgroundStart;
    UIColor * channelPanelCellHighlightedBackgroundEnd;
    UIColor * channelPanelCellHighlightedTopBorder;
    UIColor * channelPanelCellHighlightedBottomBorder;
    UIColor * channelPanelCellHighlightedDivider;    
    UIColor * channelPanelCellDimmedBackgroundStart;
    UIColor * channelPanelCellDimmedBackgroundEnd;
    UIColor * channelPanelCellDimmedTopBorder;
    UIColor * channelPanelCellDimmedBottomBorder;
    UIColor * channelPanelCellDimmedDivider;

    UIColor * channelBorderColor;
	UIImage * userPlaceholderImage, * channelContainerBackgroundNormalImage, * channelContainerBackgroundHighlightImage;
	UIImage * channelPlaceholderImage;
	UIImage * toolbarExpandImage, * toolbarExpandHighlightedImage;
	UIImage * toolbarCollapseImage, * toolbarCollapseHighlightedImage;
	// playback control
	UIImage * fullScreenImage, * fullScreenActiveImage;
	UIImage * splitScreenImage, * splitScreenActiveImage;
	
	UIImage * playImage, * playActiveImage;
	UIImage * pauseImage, * pauseActiveImage;
	
	UIImage * favoriteImage, * favoriteActiveImage;
	UIImage * watchLaterImage, * watchLaterActiveImage;
	
	UIColor * blackColor;
}

@property (nonatomic, retain) NSDateFormatter * videoDateFormatter;
@property (nonatomic, retain) NSNumberFormatter * viewCountFormatter;
@property (nonatomic, retain) UIFont * channelNameFont;
@property (nonatomic, retain) UIFont * videoTitleFont;
@property (nonatomic, retain) UIFont * videoDetailFont;
@property (nonatomic, retain) UIImage * videoShadowImage;
//@property (nonatomic, retain) UIImage * videoHighlightedBackgroundImage;
//@property (nonatomic, retain) UIImage * videoNormalBackgroundImage;
//@property (nonatomic, retain) UIImage * videoDimmedBackgroundImage;
@property (nonatomic, retain) UIColor * videoTitleFontColor;
@property (nonatomic, retain) UIColor * videoTitleHighlightedFontColor;
@property (nonatomic, retain) UIColor * videoTitlePlayedFontColor;
@property (nonatomic, retain) UIColor * videoDetailFontColor;
@property (nonatomic, retain) UIColor * videoDetailHighlightedFontColor;
@property (nonatomic, retain) UIColor * videoDetailPlayedFontColor;
@property (nonatomic, retain) UIImage * videoStatusBadImage;
@property (nonatomic, retain) UIImage * videoStatusHotImage;
@property (nonatomic, retain) UIImage * videoStatusFavImage;
@property (nonatomic, retain) UIImage * videoStatusQueuedImage;
@property (nonatomic, retain) UIImage * videoNewSessionIndicatorImage;

@property (nonatomic, retain) UIColor * clearColor;
@property (nonatomic, retain) UIColor * channelPanelFontColor;
@property (nonatomic, retain) UIColor * channelPanelBackgroundColor;
@property (nonatomic, retain) UIColor * channelPanelHighlightColor;
@property (nonatomic, retain) UIColor * channelPanelPlayedColor;

@property (nonatomic, retain) UIColor * channelPanelCellDefaultBackgroundStart;
@property (nonatomic, retain) UIColor * channelPanelCellDefaultBackgroundEnd;
@property (nonatomic, retain) UIColor * channelPanelCellDefaultTopBorder;
@property (nonatomic, retain) UIColor * channelPanelCellDefaultBottomBorder;
@property (nonatomic, retain) UIColor * channelPanelCellDefaultDivider;

@property (nonatomic, retain) UIColor * channelPanelCellHighlightedBackgroundStart;
@property (nonatomic, retain) UIColor * channelPanelCellHighlightedBackgroundEnd;
@property (nonatomic, retain) UIColor * channelPanelCellHighlightedTopBorder;
@property (nonatomic, retain) UIColor * channelPanelCellHighlightedBottomBorder;
@property (nonatomic, retain) UIColor * channelPanelCellHighlightedDivider;

@property (nonatomic, retain) UIColor * channelPanelCellDimmedBackgroundStart;
@property (nonatomic, retain) UIColor * channelPanelCellDimmedBackgroundEnd;
@property (nonatomic, retain) UIColor * channelPanelCellDimmedTopBorder;
@property (nonatomic, retain) UIColor * channelPanelCellDimmedBottomBorder;
@property (nonatomic, retain) UIColor * channelPanelCellDimmedDivider;

@property (nonatomic, retain) UIColor * channelBorderColor;
@property (nonatomic, retain) UIImage * userPlaceholderImage;
@property (nonatomic, retain) UIImage * channelPlaceholderImage;
@property (nonatomic, retain) UIImage * channelContainerBackgroundNormalImage;
@property (nonatomic, retain) UIImage * channelContainerBackgroundHighlightImage;
@property (nonatomic, retain) UIImage * toolbarExpandImage;
@property (nonatomic, retain) UIImage * toolbarExpandHighlightedImage;
@property (nonatomic, retain) UIImage * toolbarCollapseImage;
@property (nonatomic, retain) UIImage * toolbarCollapseHighlightedImage;

@property (nonatomic, retain) UIImage * fullScreenImage;
@property (nonatomic, retain) UIImage * fullScreenActiveImage;
@property (nonatomic, retain) UIImage * splitScreenImage;
@property (nonatomic, retain) UIImage * splitScreenActiveImage;

@property (nonatomic, retain) UIImage * playImage;
@property (nonatomic, retain) UIImage * playActiveImage;
@property (nonatomic, retain) UIImage * pauseImage;
@property (nonatomic, retain) UIImage * pauseActiveImage;
@property (nonatomic, retain) UIImage * favoriteImage;
@property (nonatomic, retain) UIImage * favoriteActiveImage;
@property (nonatomic, retain) UIImage * watchLaterImage;
@property (nonatomic, retain) UIImage * watchLaterActiveImage;

@property (nonatomic, retain) UIColor * blackColor;

+ (NMStyleUtility *)sharedStyleUtility;

@end
