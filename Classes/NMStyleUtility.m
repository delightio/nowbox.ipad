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
@synthesize videoHighlightedBackgroundImage;
@synthesize videoTitleFontColor;
@synthesize videoTitleHighlightedFontColor;
@synthesize videoDetailFontColor;
@synthesize videoDetailHighlightedFontColor;
@synthesize clearColor;
@synthesize channelPanelFontColor;
@synthesize channelPanelBackgroundColor;
@synthesize channelPanelHighlightColor;
@synthesize channelBorderColor;
@synthesize userPlaceholderImage;
@synthesize channelContainerBackgroundImage;
@synthesize fullScreenImage;
@synthesize fullScreenActiveImage;
@synthesize splitScreenImage;
@synthesize splitScreenActiveImage;
@synthesize playImage;
@synthesize playActiveImage;
@synthesize pauseImage;
@synthesize pauseActiveImage;
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
	channelNameFont = [[UIFont fontWithName:@"ArialMT" size:13.0f] retain];
	videoDetailFont = [[UIFont fontWithName:@"ArialMT" size:12.0f] retain];
	videoTitleFont = [[UIFont fontWithName:@"Arial-BoldMT" size:13.0f] retain];
	videoShadowImage = [[UIImage imageNamed:@"playback_video_shadow"] retain];
    videoHighlightedBackgroundImage = [[UIImage imageNamed:@"channel-video-background"] retain];
	videoDetailFontColor = [[UIColor colorWithRed:90.0f / 255.0f green:90.0f / 255.0f blue:90.0f / 255.0f alpha:1.0f] retain];
	videoDetailHighlightedFontColor = [[UIColor colorWithRed:162.0f / 255.0f green:162.0f / 255.0f blue:162.0f / 255.0f alpha:1.0f] retain];
	videoTitleFontColor = [[UIColor colorWithRed:33.0f / 255.0f green:33.0f / 255.0f blue:33.0f / 255.0f alpha:1.0f] retain];
	videoTitleHighlightedFontColor = [[UIColor whiteColor] retain];
	clearColor = [[UIColor clearColor] retain];
	channelPanelFontColor = [[UIColor colorWithRed:48.0f / 255.0f green:100.0f / 255.0f blue:138.0f / 255.0f alpha:1.0] retain];
	channelPanelHighlightColor = [[UIColor colorWithRed:62.0f/255.0f green:62.0f / 255.0f blue:62.0f / 255.0f alpha:1.0] retain];
	channelPanelBackgroundColor = [[UIColor colorWithRed:245.0f / 255.0f green:245.0f / 255.0f blue:245.0f / 255.0f alpha:1.0] retain];
	channelBorderColor = [[UIColor colorWithRed:182.0f / 255.0f green:182.0f / 255.0f blue:182.0f / 255.0f alpha:1.0] retain];
	userPlaceholderImage = [[UIImage imageNamed:@"user_placeholder_image"] retain];
	channelContainerBackgroundImage = [[UIImage imageNamed:@"channel-shadow-background"] retain];
//	channelContainerBackgroundImage = [[UIImage imageNamed:@"channel-background"] retain];
	
	fullScreenImage = [[UIImage imageNamed:@"playback-full-screen"] retain];
	fullScreenActiveImage = [[UIImage imageNamed:@"playback-full-screen-active"] retain];
	splitScreenImage = [[UIImage imageNamed:@"playback-normal-screen"] retain];
	splitScreenActiveImage = [[UIImage imageNamed:@"playback-normal-screen-active"] retain];
	
	playImage = [[UIImage imageNamed:@"playback-play"] retain];
	playActiveImage = [[UIImage imageNamed:@"playback-play-active"] retain];
	pauseImage = [[UIImage imageNamed:@"playback-pause"] retain];
	pauseActiveImage = [[UIImage imageNamed:@"playback-pause-active"] retain];
	
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
    [videoHighlightedBackgroundImage release];
	[videoTitleFontColor release];
	[videoTitleHighlightedFontColor release];
	[videoDetailFontColor release];
    [videoDetailHighlightedFontColor release];
	[clearColor release];
	[channelPanelFontColor release];
	[channelPanelHighlightColor release];
	[channelPanelBackgroundColor release];
    [channelBorderColor release];
	[userPlaceholderImage release];
	
	[fullScreenImage release], [fullScreenActiveImage release];
	[splitScreenImage release],	[splitScreenActiveImage release];
	
	[playImage release], [playActiveImage release];
	[pauseImage release], [pauseActiveImage release];
	
	[blackColor release];
	[super dealloc];
}

@end
