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
	UIColor * videoTitleFontColor, * videoTitleHighlightedFontColor;
	UIColor * videoDetailFontColor;
    UIColor * videoDetailHighlightedFontColor;
	UIColor * clearColor, * channelPanelFontColor;
	UIImage * videoShadowImage;
	UIImage * videoHighlightedBackgroundImage;
	// channel panel
	UIColor * channelPanelBackgroundColor;
	UIColor * channelPanelHighlightColor;
    UIColor * channelBorderColor;
	UIImage * userPlaceholderImage, * channelContainerBackgroundImage;
	// playback control
	UIImage * fullScreenImage, * fullScreenActiveImage;
	UIImage * splitScreenImage, * splitScreenActiveImage;
	
	UIColor * blackColor;
}

@property (nonatomic, readonly) NSDateFormatter * videoDateFormatter;
@property (nonatomic, readonly) NSNumberFormatter * viewCountFormatter;
@property (nonatomic, readonly) UIFont * channelNameFont;
@property (nonatomic, readonly) UIFont * videoTitleFont;
@property (nonatomic, readonly) UIFont * videoDetailFont;
@property (nonatomic, readonly) UIImage * videoShadowImage;
@property (nonatomic, readonly) UIImage * videoHighlightedBackgroundImage;
@property (nonatomic, readonly) UIColor * videoTitleFontColor;
@property (nonatomic, readonly) UIColor * videoTitleHighlightedFontColor;
@property (nonatomic, readonly) UIColor * videoDetailFontColor;
@property (nonatomic, readonly) UIColor * videoDetailHighlightedFontColor;

@property (nonatomic, readonly) UIColor * clearColor;
@property (nonatomic, readonly) UIColor * channelPanelFontColor;
@property (nonatomic, readonly) UIColor * channelPanelBackgroundColor;
@property (nonatomic, readonly) UIColor * channelPanelHighlightColor;
@property (nonatomic, readonly) UIColor * channelBorderColor;
@property (nonatomic, readonly) UIImage * userPlaceholderImage;
@property (nonatomic, readonly) UIImage * channelContainerBackgroundImage;

@property (nonatomic, readonly) UIImage * fullScreenImage;
@property (nonatomic, readonly) UIImage * fullScreenActiveImage;
@property (nonatomic, readonly) UIImage * splitScreenImage;
@property (nonatomic, readonly) UIImage * splitScreenActiveImage;


@property (nonatomic, readonly) UIColor * blackColor;

+ (NMStyleUtility *)sharedStyleUtility;

@end
