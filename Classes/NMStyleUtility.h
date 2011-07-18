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
	UIColor * clearColor, * channelPanelFontColor;
	UIImage * videoShadowImage;
	// channel panel
	UIColor * channelPanelBackgroundColor;
	UIColor * channelPanelHighlightColor;
	UIImage * userPlaceholderImage, * channelContainerBackgroundImage;
	
	UIColor * blackColor;
}

@property (nonatomic, readonly) NSDateFormatter * videoDateFormatter;
@property (nonatomic, readonly) NSNumberFormatter * viewCountFormatter;
@property (nonatomic, readonly) UIFont * channelNameFont;
@property (nonatomic, readonly) UIFont * videoTitleFont;
@property (nonatomic, readonly) UIFont * videoDetailFont;
@property (nonatomic, readonly) UIImage * videoShadowImage;
@property (nonatomic, readonly) UIColor * videoTitleFontColor;
@property (nonatomic, readonly) UIColor * videoTitleHighlightedFontColor;
@property (nonatomic, readonly) UIColor * videoDetailFontColor;

@property (nonatomic, readonly) UIColor * clearColor;
@property (nonatomic, readonly) UIColor * channelPanelFontColor;
@property (nonatomic, readonly) UIColor * channelPanelBackgroundColor;
@property (nonatomic, readonly) UIColor * channelPanelHighlightColor;
@property (nonatomic, readonly) UIImage * userPlaceholderImage;
@property (nonatomic, readonly) UIImage * channelContainerBackgroundImage;

@property (nonatomic, readonly) UIColor * blackColor;

+ (NMStyleUtility *)sharedStyleUtility;

@end
