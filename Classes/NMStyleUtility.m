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
//@synthesize videoHighlightedBackgroundImage, videoNormalBackgroundImage, videoDimmedBackgroundImage;
@synthesize videoTitleFontColor;
@synthesize videoTitleHighlightedFontColor;
@synthesize videoTitlePlayedFontColor;
@synthesize videoDetailFontColor;
@synthesize videoDetailHighlightedFontColor;
@synthesize videoDetailPlayedFontColor;
@synthesize clearColor;
@synthesize channelPanelFontColor;
@synthesize channelPanelBackgroundColor;
@synthesize channelPanelHighlightColor;
@synthesize channelPanelPlayedColor;
@synthesize channelPanelCellDefaultBackgroundStart;
@synthesize channelPanelCellDefaultBackgroundEnd;
@synthesize channelPanelCellDefaultTopBorder;
@synthesize channelPanelCellDefaultBottomBorder;
@synthesize channelPanelCellDefaultDivider;
@synthesize channelPanelCellHighlightedBackgroundStart;
@synthesize channelPanelCellHighlightedBackgroundEnd;
@synthesize channelPanelCellHighlightedTopBorder;
@synthesize channelPanelCellHighlightedBottomBorder;
@synthesize channelPanelCellHighlightedDivider;
@synthesize channelPanelCellDimmedBackgroundStart;
@synthesize channelPanelCellDimmedBackgroundEnd;
@synthesize channelPanelCellDimmedTopBorder;
@synthesize channelPanelCellDimmedBottomBorder;
@synthesize channelPanelCellDimmedDivider;
@synthesize channelBorderColor;
@synthesize userPlaceholderImage;
@synthesize channelContainerBackgroundNormalImage;
@synthesize channelContainerBackgroundHighlightImage;
@synthesize toolbarExpandImage;
@synthesize toolbarExpandHighlightedImage;
@synthesize toolbarCollapseImage;
@synthesize toolbarCollapseHighlightedImage;
@synthesize fullScreenImage;
@synthesize fullScreenActiveImage;
@synthesize splitScreenImage;
@synthesize splitScreenActiveImage;
@synthesize playImage;
@synthesize playActiveImage;
@synthesize pauseImage;
@synthesize pauseActiveImage;
@synthesize blackColor;
@synthesize videoStatusBadImage;
@synthesize videoStatusFavImage;
@synthesize videoStatusQueuedImage;
@synthesize videoStatusHotImage;
@synthesize videoNewSessionIndicatorImage;
@synthesize favoriteImage;
@synthesize favoriteActiveImage;
@synthesize watchLaterImage;
@synthesize watchLaterActiveImage;

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
    channelNameFont = [[UIFont fontWithName:@"HelveticaNeue" size:12.0f] retain];
	videoDetailFont = [[UIFont fontWithName:@"HelveticaNeue" size:13.0f] retain];
	videoTitleFont = [[UIFont fontWithName:@"HelveticaNeue-Bold" size:13.0f] retain];
	videoShadowImage = [[UIImage imageNamed:@"playback_video_shadow"] retain];
//    videoHighlightedBackgroundImage = [[UIImage imageNamed:@"channel-video-background-highlight"] retain];
//    videoNormalBackgroundImage = [[UIImage imageNamed:@"channel-video-background-normal"] retain];
//    videoDimmedBackgroundImage = [[UIImage imageNamed:@"channel-video-background-dimmed"] retain];
	videoDetailFontColor = [[UIColor colorWithRed:90.0f / 255.0f green:90.0f / 255.0f blue:90.0f / 255.0f alpha:1.0f] retain];
	videoDetailHighlightedFontColor = [[UIColor colorWithRed:162.0f / 255.0f green:162.0f / 255.0f blue:162.0f / 255.0f alpha:1.0f] retain];
	videoDetailPlayedFontColor = [[UIColor colorWithRed:159 / 255.0f green:159 / 255.0f blue:159 / 255.0f alpha:1.0f] retain];
	videoTitleFontColor = [[UIColor colorWithRed:33.0f / 255.0f green:33.0f / 255.0f blue:33.0f / 255.0f alpha:1.0f] retain];
	videoTitleHighlightedFontColor = [[UIColor whiteColor] retain];
    videoTitlePlayedFontColor = [[UIColor colorWithRed:133.0f / 255.0f green:133.0f / 255.0f blue:133.0f / 255.0f alpha:1.0f] retain];
	clearColor = [[UIColor clearColor] retain];
	channelPanelFontColor = [[UIColor colorWithRed:225.0f / 255.0f green:225.0f / 255.0f blue:225.0f / 255.0f alpha:1.0] retain];
	channelPanelHighlightColor = [[UIColor colorWithRed:62.0f/255.0f green:62.0f / 255.0f blue:62.0f / 255.0f alpha:1.0] retain];
	channelPanelBackgroundColor = [[UIColor colorWithRed:245.0f / 255.0f green:245.0f / 255.0f blue:245.0f / 255.0f alpha:1.0] retain];
    channelPanelPlayedColor = [[UIColor colorWithRed:233 / 255.0f green:233 / 255.0f blue:233 / 255.0f alpha:1.0] retain];
    
    channelPanelCellDefaultBackgroundStart = [[UIColor colorWithRed:240 / 255.0f green:240 / 255.0f blue:240 / 255.0f alpha:1.0] retain];    
    channelPanelCellDefaultBackgroundEnd = [[UIColor colorWithRed:231 / 255.0f green:231 / 255.0f blue:231 / 255.0f alpha:1.0] retain];    
    channelPanelCellDefaultTopBorder = [[UIColor colorWithRed:255 / 255.0f green:255 / 255.0f blue:255 / 255.0f alpha:1.0] retain];    
    channelPanelCellDefaultBottomBorder = [[UIColor colorWithRed:170 / 255.0f green:170 / 255.0f blue:170 / 255.0f alpha:1.0] retain];    
    channelPanelCellDefaultDivider = [[UIColor colorWithRed:170 / 255.0f green:170 / 255.0f blue:170 / 255.0f alpha:1.0] retain];    
    
    channelPanelCellHighlightedBackgroundStart = [[UIColor colorWithRed:47 / 255.0f green:47 / 255.0f blue:47 / 255.0f alpha:1.0] retain];    
    channelPanelCellHighlightedBackgroundEnd = [[UIColor colorWithRed:61 / 255.0f green:61 / 255.0f blue:61 / 255.0f alpha:1.0] retain];    
    channelPanelCellHighlightedTopBorder = [[UIColor colorWithRed:36 / 255.0f green:36 / 255.0f blue:36 / 255.0f alpha:1.0] retain];    
    channelPanelCellHighlightedBottomBorder = [[UIColor colorWithRed:36 / 255.0f green:36 / 255.0f blue:36 / 255.0f alpha:1.0] retain];    
    channelPanelCellHighlightedDivider = [[UIColor colorWithRed:36 / 255.0f green:36 / 255.0f blue:36 / 255.0f alpha:1.0] retain];    
    
    channelPanelCellDimmedBackgroundStart = [[UIColor colorWithRed:211 / 255.0f green:211 / 255.0f blue:211 / 255.0f alpha:1.0] retain];    
    channelPanelCellDimmedBackgroundEnd = [[UIColor colorWithRed:211 / 255.0f green:211 / 255.0f blue:211 / 255.0f alpha:1.0] retain];    
    channelPanelCellDimmedTopBorder = [[UIColor colorWithRed:238 / 255.0f green:238 / 255.0f blue:238 / 255.0f alpha:1.0] retain];    
    channelPanelCellDimmedBottomBorder = [[UIColor colorWithRed:170 / 255.0f green:170 / 255.0f blue:170 / 255.0f alpha:1.0] retain];       
    channelPanelCellDimmedDivider = [[UIColor colorWithRed:170 / 255.0f green:170 / 255.0f blue:170 / 255.0f alpha:1.0] retain];       
    
	channelBorderColor = [[UIColor colorWithRed:170 / 255.0f green:170 / 255.0f blue:170 / 255.0 alpha:1.0] retain];
	
	blackColor = [[UIColor blackColor] retain];
    
	return self;
}

- (UIImage *)userPlaceholderImage {
	if ( userPlaceholderImage == nil ) {
		userPlaceholderImage = [[UIImage imageNamed:@"user_placeholder_image"] retain];
	}
	return userPlaceholderImage;
}

- (UIImage *)channelContainerBackgroundNormalImage {
	if ( channelContainerBackgroundNormalImage == nil ) {
		channelContainerBackgroundNormalImage = [[UIImage imageNamed:@"channel-list-cell-normal"] retain];
	
	}
	return channelContainerBackgroundNormalImage;
}

- (UIImage *)channelContainerBackgroundHighlightImage {
	if ( channelContainerBackgroundHighlightImage == nil ) {
		channelContainerBackgroundHighlightImage = [[UIImage imageNamed:@"channel-list-cell-highlighted"] retain];
	}
	return channelContainerBackgroundHighlightImage;
}

- (UIImage *)toolbarExpandImage {
	if ( toolbarExpandImage == nil ) {
		toolbarExpandImage = [[UIImage imageNamed:@"toolbar-expand"] retain];
	}
	return toolbarExpandImage;
}

- (UIImage *)toolbarExpandHighlightedImage {
	if ( toolbarExpandHighlightedImage == nil ) {
		toolbarExpandHighlightedImage = [[UIImage imageNamed:@"toolbar-expand-active"] retain];
	}
	return toolbarExpandHighlightedImage;
}

- (UIImage *)toolbarCollapseImage {
	if ( toolbarCollapseImage == nil ) {
		toolbarCollapseImage = [[UIImage imageNamed:@"toolbar-collapse"] retain];
	}
	return toolbarCollapseImage;
}

- (UIImage *)toolbarCollapseHighlightedImage {
	if ( toolbarCollapseHighlightedImage == nil ) {
		toolbarCollapseHighlightedImage = [[UIImage imageNamed:@"toolbar-collapse-active"] retain];
	}
	return toolbarCollapseHighlightedImage;
}

- (UIImage *)fullScreenImage {
	if ( fullScreenImage == nil ) {
		fullScreenImage = [[UIImage imageNamed:@"playback-full-screen"] retain];
	}
	return fullScreenImage;
}

- (UIImage *)fullScreenActiveImage {
	if ( fullScreenActiveImage == nil ) {
		fullScreenActiveImage = [[UIImage imageNamed:@"playback-full-screen-active"] retain];
	}
	return fullScreenActiveImage;
}

- (UIImage *)splitScreenImage {
	if ( splitScreenImage == nil ) {
		splitScreenImage = [[UIImage imageNamed:@"playback-normal-screen"] retain];
	}
	return splitScreenImage;
}

- (UIImage *)playImage {
	if ( playImage == nil ) {
		playImage = [[UIImage imageNamed:@"playback-play"] retain];
	}
	return playImage;
}

- (UIImage *)splitScreenActiveImage {
	if ( splitScreenActiveImage == nil ) {
		splitScreenActiveImage = [[UIImage imageNamed:@"playback-normal-screen-active"] retain];
	}
	return splitScreenActiveImage;
}

- (UIImage *)playActiveImage {
	if ( playActiveImage == nil ) {
		playActiveImage = [[UIImage imageNamed:@"playback-play-active"] retain];
	}
	return playActiveImage;
}

- (UIImage *)pauseImage {
	if ( pauseImage == nil ) {
		pauseImage = [[UIImage imageNamed:@"playback-pause"] retain];
	}
	return pauseImage;
}

- (UIImage *)pauseActiveImage {
	if ( pauseActiveImage== nil ) {
		pauseActiveImage = [[UIImage imageNamed:@"playback-pause-active"] retain];
	}
	return pauseActiveImage;
}

- (UIImage *)videoStatusBadImage {
	if ( videoStatusBadImage == nil ) {
		videoStatusBadImage = [[UIImage imageNamed:@"channel-video-status-bad"] retain];
	}
	return videoStatusBadImage;
}

- (UIImage *)videoStatusHotImage {
	if ( videoStatusHotImage == nil ) {
		videoStatusHotImage = [[UIImage imageNamed:@"channel-video-status-hot"] retain];
	}
	return videoStatusHotImage;
}

- (UIImage *)videoStatusFavImage {
	if ( videoStatusFavImage == nil ) {
		videoStatusFavImage = [[UIImage imageNamed:@"channel-video-status-fav"] retain];
	}
	return videoStatusFavImage;
}

- (UIImage *)videoStatusQueuedImage {
	if ( videoStatusQueuedImage == nil ) {
		videoStatusQueuedImage = [[UIImage imageNamed:@"channel-video-status-watch-later"] retain];
	}
	return videoStatusQueuedImage;
}

- (UIImage *)videoNewSessionIndicatorImage {
	if ( videoNewSessionIndicatorImage == nil ) {
		videoNewSessionIndicatorImage = [[UIImage imageNamed:@"channel-view-new-session"] retain];
	}
	return videoNewSessionIndicatorImage;
}

- (UIImage *)favoriteImage {
	if ( favoriteImage == nil ) {
		favoriteImage = [[UIImage imageNamed:@"button-like"] retain];
	}
	return favoriteImage;
}

- (UIImage *)favoriteActiveImage {
	if ( favoriteActiveImage == nil ) {
		favoriteActiveImage = [[UIImage imageNamed:@"button-like-active"] retain];
	}
	return favoriteActiveImage;
}

- (UIImage *)watchLaterImage {
	if ( watchLaterImage == nil ) {
		watchLaterImage = [[UIImage imageNamed:@"button-watch-later"] retain];
	}
	return watchLaterImage;
}

- (UIImage *)watchLaterActiveImage {
	if ( watchLaterActiveImage == nil ) {
		watchLaterActiveImage = [[UIImage imageNamed:@"button-watch-later-active"] retain];
	}
	return watchLaterActiveImage;
}

- (void)dealloc {
	[channelContainerBackgroundNormalImage release];
	[channelContainerBackgroundHighlightImage release];
	[videoDateFormatter release];
	[viewCountFormatter release];
	[channelNameFont release];
	[videoDetailFont release];
	[videoTitleFont release];
	[videoShadowImage release];
//    [videoHighlightedBackgroundImage release];
//    [videoNormalBackgroundImage release];
//    [videoDimmedBackgroundImage release];
	[videoTitleFontColor release];
	[videoTitleHighlightedFontColor release];
	[videoDetailFontColor release];
    [videoDetailHighlightedFontColor release];
	[clearColor release];
	[channelPanelFontColor release];
	[channelPanelHighlightColor release];
	[channelPanelBackgroundColor release];
    
    [channelPanelCellDefaultBackgroundStart release];
    [channelPanelCellDefaultBackgroundEnd release];
    [channelPanelCellDefaultTopBorder release];
    [channelPanelCellDefaultBottomBorder release];
    [channelPanelCellDefaultDivider release];
    [channelPanelCellHighlightedBackgroundStart release];
    [channelPanelCellHighlightedBackgroundEnd release];
    [channelPanelCellHighlightedTopBorder release];
    [channelPanelCellHighlightedBottomBorder release];
    [channelPanelCellHighlightedDivider release];

    [channelPanelCellDimmedBackgroundStart release];
    [channelPanelCellDimmedBackgroundEnd release];
    [channelPanelCellDimmedTopBorder release];
    [channelPanelCellDimmedBottomBorder release];
    [channelPanelCellDimmedDivider release];
    
    [channelBorderColor release];
	[userPlaceholderImage release];
	[toolbarExpandImage release], [toolbarExpandHighlightedImage release];
	[toolbarCollapseImage release], [toolbarCollapseHighlightedImage release];

    [videoStatusBadImage release];
    [videoStatusHotImage release];
    [videoStatusFavImage release];
    [videoStatusQueuedImage release];
    [videoNewSessionIndicatorImage release];
    
	[fullScreenImage release], [fullScreenActiveImage release];
	[splitScreenImage release],	[splitScreenActiveImage release];
	
	[playImage release], [playActiveImage release];
	[pauseImage release], [pauseActiveImage release];
	
	[favoriteImage release], [favoriteActiveImage release];
	[watchLaterImage release], [watchLaterActiveImage release];
	
	[blackColor release];
	[super dealloc];
}

@end
