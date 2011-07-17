//
//  NMStyleUtility.m
//  ipad
//
//  Created by Bill So on 16/06/2011.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "NMStyleUtility.h"


static NMStyleUtility * sharedStyleUtility_ = nil;

@implementation NMStyleUtility

@synthesize videoDateFormatter;
@synthesize viewCountFormatter;
@synthesize channelNameFont;
@synthesize videoTitleFont;
@synthesize videoDetailFont;
@synthesize videoShadowImage;
@synthesize clearColor;
@synthesize channelPanelFontColor;
@synthesize channelPanelBackgroundColor;
@synthesize channelPanelHighlightColor;
@synthesize userPlaceholderImage;
@synthesize channelContainerBackgroundImage;
@synthesize blackColor;

+ (NMStyleUtility *)sharedStyleUtility {
	if ( sharedStyleUtility_ == nil ) {
		sharedStyleUtility_ = [[NMStyleUtility alloc] init];
	}
	
	return sharedStyleUtility_;
}

- (id)init {
	self = [super init];
	
	videoDateFormatter = [[NSDateFormatter alloc] init];
	[videoDateFormatter setDateStyle:NSDateFormatterShortStyle];
	[videoDateFormatter setDoesRelativeDateFormatting:YES];
	
	viewCountFormatter = [[NSNumberFormatter alloc] init];
	[viewCountFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	
	// video detail view font
	channelNameFont = [[UIFont boldSystemFontOfSize:14.0f] retain];
	videoDetailFont = [[UIFont systemFontOfSize:11.0f] retain];
	videoTitleFont = [[UIFont boldSystemFontOfSize:13.0f] retain];
	videoShadowImage = [[UIImage imageNamed:@"playback_video_shadow"] retain];
	clearColor = [[UIColor clearColor] retain];
	channelPanelFontColor = [[UIColor colorWithRed:90.0f / 255.0f green:90.0f / 255.0f blue:90.0f / 255.0f alpha:1.0] retain];
	channelPanelHighlightColor = [[UIColor grayColor] retain];
	channelPanelBackgroundColor = [[UIColor colorWithRed:232.0f/255.0f green:233.0f / 255.0f blue:237.0f / 255.0f alpha:1.0] retain];
	userPlaceholderImage = [[UIImage imageNamed:@"user_placeholder_image"] retain];
	channelContainerBackgroundImage = [[UIImage imageNamed:@"channel-shadow-background"] retain];
//	channelContainerBackgroundImage = [[UIImage imageNamed:@"channel-background"] retain];
	
	blackColor = [[UIColor blackColor] retain];
	
	return self;
}

- (void)dealloc {
	[channelContainerBackgroundImage release];
	[videoDateFormatter release];
	[viewCountFormatter release];
	[channelNameFont release];
	[videoDetailFont release];
	[videoTitleFont release];
	[videoShadowImage release];
	[clearColor release];
	[channelPanelFontColor release];
	[channelPanelHighlightColor release];
	[channelPanelBackgroundColor release];
	[userPlaceholderImage release];
	[blackColor release];
	[super dealloc];
}

@end
