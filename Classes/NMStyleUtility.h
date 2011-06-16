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
	UIFont * channelNameFont, * videoTitleFont, * videoDetailFont;
	UIColor * clearColor, * channelPanelFontColor;
}

@property (nonatomic, readonly) NSDateFormatter * videoDateFormatter;
@property (nonatomic, readonly) UIFont * channelNameFont;
@property (nonatomic, readonly) UIFont * videoTitleFont;
@property (nonatomic, readonly) UIFont * videoDetailFont;
@property (nonatomic, readonly) UIColor * clearColor;
@property (nonatomic, readonly) UIColor * channelPanelFontColor;

+ (NMStyleUtility *)sharedStyleUtility;

@end
