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
	UIImage * videoHighlightedBackgroundImage, * videoNormalBackgroundImage, * videoDimmedBackgroundImage;
    UIImage * videoStatusBadImage, * videoStatusHotImage, * videoStatusFavImage;
    UIImage * videoNewSessionIndicatorImage;
	// channel panel
	UIColor * channelPanelBackgroundColor;
	UIColor * channelPanelHighlightColor;
	UIColor * channelPanelPlayedColor;
    UIColor * channelBorderColor;
	UIImage * userPlaceholderImage, * channelContainerBackgroundNormalImage, * channelContainerBackgroundHighlightImage;
	// playback control
	UIImage * fullScreenImage, * fullScreenActiveImage;
	UIImage * splitScreenImage, * splitScreenActiveImage;
	
	UIImage * playImage, * playActiveImage;
	UIImage * pauseImage, * pauseActiveImage;
	
	UIColor * blackColor;
}

@property (nonatomic, readonly) NSDateFormatter * videoDateFormatter;
@property (nonatomic, readonly) NSNumberFormatter * viewCountFormatter;
@property (nonatomic, readonly) UIFont * channelNameFont;
@property (nonatomic, readonly) UIFont * videoTitleFont;
@property (nonatomic, readonly) UIFont * videoDetailFont;
@property (nonatomic, readonly) UIImage * videoShadowImage;
@property (nonatomic, readonly) UIImage * videoHighlightedBackgroundImage;
@property (nonatomic, readonly) UIImage * videoNormalBackgroundImage;
@property (nonatomic, readonly) UIImage * videoDimmedBackgroundImage;
@property (nonatomic, readonly) UIColor * videoTitleFontColor;
@property (nonatomic, readonly) UIColor * videoTitleHighlightedFontColor;
@property (nonatomic, readonly) UIColor * videoTitlePlayedFontColor;
@property (nonatomic, readonly) UIColor * videoDetailFontColor;
@property (nonatomic, readonly) UIColor * videoDetailHighlightedFontColor;
@property (nonatomic, readonly) UIColor * videoDetailPlayedFontColor;
@property (nonatomic, readonly) UIImage * videoStatusBadImage;
@property (nonatomic, readonly) UIImage * videoStatusHotImage;
@property (nonatomic, readonly) UIImage * videoStatusFavImage;
@property (nonatomic, readonly) UIImage * videoNewSessionIndicatorImage;

@property (nonatomic, readonly) UIColor * clearColor;
@property (nonatomic, readonly) UIColor * channelPanelFontColor;
@property (nonatomic, readonly) UIColor * channelPanelBackgroundColor;
@property (nonatomic, readonly) UIColor * channelPanelHighlightColor;
@property (nonatomic, readonly) UIColor * channelPanelPlayedColor;
@property (nonatomic, readonly) UIColor * channelBorderColor;
@property (nonatomic, readonly) UIImage * userPlaceholderImage;
@property (nonatomic, readonly) UIImage * channelContainerBackgroundNormalImage;
@property (nonatomic, readonly) UIImage * channelContainerBackgroundHighlightImage;

@property (nonatomic, readonly) UIImage * fullScreenImage;
@property (nonatomic, readonly) UIImage * fullScreenActiveImage;
@property (nonatomic, readonly) UIImage * splitScreenImage;
@property (nonatomic, readonly) UIImage * splitScreenActiveImage;

@property (nonatomic, readonly) UIImage * playImage;
@property (nonatomic, readonly) UIImage * playActiveImage;
@property (nonatomic, readonly) UIImage * pauseImage;
@property (nonatomic, readonly) UIImage * pauseActiveImage;

@property (nonatomic, readonly) UIColor * blackColor;

+ (NMStyleUtility *)sharedStyleUtility;

@end
