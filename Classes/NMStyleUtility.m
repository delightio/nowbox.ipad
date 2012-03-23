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
@synthesize channelPlaceholderImage;
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
	    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLowMemoryNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	
	return self;
}

- (void)handleLowMemoryNotification:(NSNotification *)aNotification {
	self.channelNameFont = nil;
	self.videoTitleFont = nil;
	self.channelNameFont = nil;
	self.videoTitleFont = nil;
	self.videoDetailFont = nil;
	self.videoShadowImage = nil;
	self.videoTitleFontColor = nil;
	self.videoTitleHighlightedFontColor = nil;
	self.videoTitlePlayedFontColor = nil;
	self.videoDetailFontColor = nil;
	self.videoDetailHighlightedFontColor = nil;
	self.videoDetailPlayedFontColor = nil;
	self.clearColor = nil;
	self.channelPanelFontColor = nil;
	self.channelPanelBackgroundColor = nil;
	self.channelPanelHighlightColor = nil;
	self.channelPanelPlayedColor = nil;
	self.channelPanelCellDefaultBackgroundStart = nil;
	self.channelPanelCellDefaultBackgroundEnd = nil;
	self.channelPanelCellDefaultTopBorder = nil;
	self.channelPanelCellDefaultBottomBorder = nil;
	self.channelPanelCellDefaultDivider = nil;
	self.channelPanelCellHighlightedBackgroundStart = nil;
	self.channelPanelCellHighlightedBackgroundEnd = nil;
	self.channelPanelCellHighlightedTopBorder = nil;
	self.channelPanelCellHighlightedBottomBorder = nil;
	self.channelPanelCellHighlightedDivider = nil;
	self.channelPanelCellDimmedBackgroundStart = nil;
	self.channelPanelCellDimmedBackgroundEnd = nil;
	self.channelPanelCellDimmedTopBorder = nil;
	self.channelPanelCellDimmedBottomBorder = nil;
	self.channelPanelCellDimmedDivider = nil;
	self.channelBorderColor = nil;
	self.userPlaceholderImage = nil;
	self.channelContainerBackgroundNormalImage = nil;
	self.channelContainerBackgroundHighlightImage = nil;
	self.toolbarExpandImage = nil;
	self.toolbarExpandHighlightedImage = nil;
	self.toolbarCollapseImage = nil;
	self.toolbarCollapseHighlightedImage = nil;
	self.fullScreenImage = nil;
	self.fullScreenActiveImage = nil;
	self.splitScreenImage = nil;
	self.splitScreenActiveImage = nil;
	self.playImage = nil;
	self.playActiveImage = nil;
	self.pauseImage = nil;
	self.pauseActiveImage = nil;
	self.blackColor = nil;
	self.videoStatusBadImage = nil;
	self.videoStatusFavImage = nil;
	self.videoStatusQueuedImage = nil;
	self.videoStatusHotImage = nil;
	self.videoNewSessionIndicatorImage = nil;
	self.favoriteImage = nil;
	self.favoriteActiveImage = nil;
	self.watchLaterImage = nil;
	self.watchLaterActiveImage = nil;
}

#pragma mark - Fonts
- (UIFont *)channelNameFont  {
	if ( channelNameFont == nil ) {
		channelNameFont = [[UIFont fontWithName:@"HelveticaNeue" size:12.0f] retain];
	}
	return channelNameFont;
}

- (UIFont *)videoTitleFont  {
	if ( videoTitleFont == nil ) {
		videoTitleFont = [[UIFont fontWithName:@"HelveticaNeue-Bold" size:13.0f] retain];
	}
	return videoTitleFont;
}

- (UIFont *)videoDetailFont  {
	if ( videoDetailFont == nil ) {
		videoDetailFont = [[UIFont fontWithName:@"HelveticaNeue" size:13.0f] retain];
	}
	return videoDetailFont;
}

#pragma mark - Colors

- (UIColor *)videoTitleFontColor {
	if ( videoTitleFontColor == nil ) {
		videoTitleFontColor = [[UIColor colorWithRed:33.0f / 255.0f green:33.0f / 255.0f blue:33.0f / 255.0f alpha:1.0f] retain];
	}
	return videoTitleFontColor;
}

- (UIColor *)videoTitleHighlightedFontColor {
	if ( videoTitleHighlightedFontColor == nil ) {
		videoTitleHighlightedFontColor = [[UIColor whiteColor] retain];
	}
	return videoTitleHighlightedFontColor;
}

- (UIColor *)videoTitlePlayedFontColor {
	if ( videoTitlePlayedFontColor == nil ) {
		videoTitlePlayedFontColor = [[UIColor colorWithRed:133.0f / 255.0f green:133.0f / 255.0f blue:133.0f / 255.0f alpha:1.0f] retain];
	}
	return videoTitlePlayedFontColor;
}

- (UIColor *)videoDetailFontColor {
	if ( videoDetailFontColor == nil ) {
		videoDetailFontColor = [[UIColor colorWithRed:90.0f / 255.0f green:90.0f / 255.0f blue:90.0f / 255.0f alpha:1.0f] retain];
	}
	return videoDetailFontColor;
}

- (UIColor *)videoDetailHighlightedFontColor {
	if ( videoDetailHighlightedFontColor == nil ) {
		videoDetailHighlightedFontColor = [[UIColor colorWithRed:162.0f / 255.0f green:162.0f / 255.0f blue:162.0f / 255.0f alpha:1.0f] retain];
	}
	return videoDetailHighlightedFontColor;
}

- (UIColor *)videoDetailPlayedFontColor {
	if ( videoDetailHighlightedFontColor == nil ) {
		videoDetailPlayedFontColor = [[UIColor colorWithRed:159 / 255.0f green:159 / 255.0f blue:159 / 255.0f alpha:1.0f] retain];
	}
	return videoDetailHighlightedFontColor;
}


- (UIColor *)clearColor {
	if ( clearColor == nil ) {
		clearColor = [[UIColor clearColor] retain];
	}
	return clearColor;
}

- (UIColor *)channelPanelFontColor {
	if ( channelPanelFontColor == nil ) {
		channelPanelFontColor = [[UIColor colorWithRed:225.0f / 255.0f green:225.0f / 255.0f blue:225.0f / 255.0f alpha:1.0] retain];
	}
	return channelPanelFontColor;
}

- (UIColor *)channelPanelBackgroundColor {
	if ( channelPanelBackgroundColor == nil ) {
		channelPanelBackgroundColor = [[UIColor colorWithRed:245.0f / 255.0f green:245.0f / 255.0f blue:245.0f / 255.0f alpha:1.0] retain];
	}
	return channelPanelBackgroundColor;
}

- (UIColor *)channelPanelHighlightColor {
	if ( channelPanelHighlightColor == nil ) {
		channelPanelHighlightColor = [[UIColor colorWithRed:62.0f/255.0f green:62.0f / 255.0f blue:62.0f / 255.0f alpha:1.0] retain];
	}
	return channelPanelHighlightColor;
}

- (UIColor *)channelPanelPlayedColor {
	if ( channelPanelPlayedColor == nil ) {
		channelPanelPlayedColor = [[UIColor colorWithRed:233 / 255.0f green:233 / 255.0f blue:233 / 255.0f alpha:1.0] retain];
	}
	return channelPanelPlayedColor;
}


- (UIColor *)channelPanelCellDefaultBackgroundStart {
	if ( channelPanelCellDefaultBackgroundStart == nil ) {
		channelPanelCellDefaultBackgroundStart = [[UIColor colorWithRed:240 / 255.0f green:240 / 255.0f blue:240 / 255.0f alpha:1.0] retain];    
	}
	return channelPanelCellDefaultBackgroundStart;
}

- (UIColor *)channelPanelCellDefaultBackgroundEnd {
	if ( channelPanelCellDefaultBackgroundEnd == nil ) {
		channelPanelCellDefaultBackgroundEnd = [[UIColor colorWithRed:231 / 255.0f green:231 / 255.0f blue:231 / 255.0f alpha:1.0] retain];    
	}
	return channelPanelCellDefaultBackgroundEnd;
}

- (UIColor *)channelPanelCellDefaultTopBorder {
	if ( channelPanelCellDefaultTopBorder == nil ) {
		channelPanelCellDefaultTopBorder = [[UIColor colorWithRed:255 / 255.0f green:255 / 255.0f blue:255 / 255.0f alpha:1.0] retain];    
	}
	return channelPanelCellDefaultTopBorder;
}

- (UIColor *)channelPanelCellDefaultBottomBorder {
	if ( channelPanelCellDefaultBottomBorder == nil ) {
		channelPanelCellDefaultBottomBorder = [[UIColor colorWithRed:170 / 255.0f green:170 / 255.0f blue:170 / 255.0f alpha:1.0] retain];    
	}
	return channelPanelCellDefaultBottomBorder;
}

- (UIColor *)channelPanelCellDefaultDivider {
	if ( channelPanelCellDefaultDivider == nil ) {
		channelPanelCellDefaultDivider = [[UIColor colorWithRed:170 / 255.0f green:170 / 255.0f blue:170 / 255.0f alpha:1.0] retain];    
	}
	return channelPanelCellDefaultDivider;
}


- (UIColor *)channelPanelCellHighlightedBackgroundStart {
	if ( channelPanelCellHighlightedBackgroundStart == nil ) {
		channelPanelCellHighlightedBackgroundStart = [[UIColor colorWithRed:47 / 255.0f green:47 / 255.0f blue:47 / 255.0f alpha:1.0] retain];    
	}
	return channelPanelCellHighlightedBackgroundStart;
}

- (UIColor *)channelPanelCellHighlightedBackgroundEnd {
	if ( channelPanelCellHighlightedBackgroundEnd == nil ) {
		channelPanelCellHighlightedBackgroundEnd = [[UIColor colorWithRed:61 / 255.0f green:61 / 255.0f blue:61 / 255.0f alpha:1.0] retain];    
	}
	return channelPanelCellHighlightedBackgroundEnd;
}

- (UIColor *)channelPanelCellHighlightedTopBorder {
	if ( channelPanelCellHighlightedTopBorder == nil ) {
		channelPanelCellHighlightedTopBorder = [[UIColor colorWithRed:36 / 255.0f green:36 / 255.0f blue:36 / 255.0f alpha:1.0] retain];    
	}
	return channelPanelCellHighlightedTopBorder;
}

- (UIColor *)channelPanelCellHighlightedBottomBorder {
	if ( channelPanelCellHighlightedBottomBorder == nil ) {
		channelPanelCellHighlightedBottomBorder = [[UIColor colorWithRed:36 / 255.0f green:36 / 255.0f blue:36 / 255.0f alpha:1.0] retain];    
	}
	return channelPanelCellHighlightedBottomBorder;
}

- (UIColor *)channelPanelCellHighlightedDivider {
	if ( channelPanelCellHighlightedDivider == nil ) {
		channelPanelCellHighlightedDivider = [[UIColor colorWithRed:36 / 255.0f green:36 / 255.0f blue:36 / 255.0f alpha:1.0] retain];    
	}
	return channelPanelCellHighlightedDivider;
}


- (UIColor *)channelPanelCellDimmedBackgroundStart {
	if ( channelPanelCellDimmedBackgroundStart == nil ) {
		channelPanelCellDimmedBackgroundStart = [[UIColor colorWithRed:211 / 255.0f green:211 / 255.0f blue:211 / 255.0f alpha:1.0] retain];    
	}
	return channelPanelCellDimmedBackgroundStart;
}

- (UIColor *)channelPanelCellDimmedBackgroundEnd {
	if ( channelPanelCellDimmedBackgroundEnd == nil ) {
		channelPanelCellDimmedBackgroundEnd = [[UIColor colorWithRed:211 / 255.0f green:211 / 255.0f blue:211 / 255.0f alpha:1.0] retain];
	}
	return channelPanelCellDimmedBackgroundEnd;
}

- (UIColor *)channelPanelCellDimmedTopBorder {
	if ( channelPanelCellDimmedTopBorder == nil ) {
		channelPanelCellDimmedTopBorder = [[UIColor colorWithRed:238 / 255.0f green:238 / 255.0f blue:238 / 255.0f alpha:1.0] retain];    
	}
	return channelPanelCellDimmedTopBorder;
}

- (UIColor *)channelPanelCellDimmedBottomBorder {
	if ( channelPanelCellDimmedBottomBorder == nil ) {
		channelPanelCellDimmedBottomBorder = [[UIColor colorWithRed:170 / 255.0f green:170 / 255.0f blue:170 / 255.0f alpha:1.0] retain];       
	}
	return channelPanelCellDimmedBottomBorder;
}

- (UIColor *)channelPanelCellDimmedDivider {
	if ( channelPanelCellDimmedDivider == nil ) {
		channelPanelCellDimmedDivider = [[UIColor colorWithRed:170 / 255.0f green:170 / 255.0f blue:170 / 255.0f alpha:1.0] retain];
	}
	return channelPanelCellDimmedDivider;
}

- (UIColor *)channelBorderColor {
	if ( channelBorderColor == nil ) {
		channelBorderColor = [[UIColor colorWithRed:170 / 255.0f green:170 / 255.0f blue:170 / 255.0 alpha:1.0] retain];
	}
	return channelBorderColor;
}

- (UIColor *)blackColor {
	if ( blackColor == nil ) {
		blackColor = [[UIColor blackColor] retain];
	}
	return blackColor;
}


#pragma mark - Images

- (UIImage *)videoShadowImage {
	if ( videoShadowImage == nil ) {
		videoShadowImage = [[UIImage imageNamed:@"playback_video_shadow"] retain];
	}
	return videoShadowImage;
}

- (UIImage *)userPlaceholderImage {
	if ( userPlaceholderImage == nil ) {
		userPlaceholderImage = [[UIImage imageNamed:@"user_placeholder_image"] retain];
	}
	return userPlaceholderImage;
}

- (UIImage *)channelPlaceholderImage {
	if ( channelPlaceholderImage == nil ) {
		channelPlaceholderImage = [[UIImage imageNamed:@"onboard-category-icon.png"] retain];
	}
	return channelPlaceholderImage;
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
	[videoDetailPlayedFontColor release];
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
	[userPlaceholderImage release], [channelPlaceholderImage release];
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
