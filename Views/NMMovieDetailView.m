//
//  NMMovieDetailView.m
//  ipad
//
//  Created by Bill So on 6/14/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "NMMovieDetailView.h"
#import "NMLibrary.h"
#import "NMStyleUtility.h"
#import <QuartzCore/QuartzCore.h>


@implementation NMMovieDetailView
@synthesize video=video_;

//- (id)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code
//    }
//    return self;
//}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

//- (void)dealloc
//{
//    [super dealloc];
//}

- (void)awakeFromNib {
	cacheController = [NMCacheController sharedCacheController];
	descriptionDefaultFrame  = descriptionLabel.frame;
	shadowImageView.image = [[NMStyleUtility sharedStyleUtility].videoShadowImage stretchableImageWithLeftCapWidth:0 topCapHeight:2];
	CALayer * blackLayer = [CALayer layer];
	blackLayer.backgroundColor = [NMStyleUtility sharedStyleUtility].channelPanelHighlightColor.CGColor;
	blackLayer.frame = CGRectMake(0.0, 0.0, 640.0, 380.0);
	[self.layer addSublayer:blackLayer];
}

- (void)setVideo:(NMVideo *)aVideo {
	if ( aVideo && aVideo != video_ ) {
		// assigned property. no need to retain
		video_ = aVideo;
	} else if ( aVideo == nil ) {
		video_ = nil;
		
		// reset the view
		channelLogoView.image = nil;
		channelLabel.text = nil;
		titleLabel.text = nil;
		otherInfoLabel.text = nil;
		descriptionLabel.text = nil;
		return;
	} else {
		return;
	}
	// update the view with the video's attribute
	NMVideoDetail * dtlObj = aVideo.detail;
	
	// channel info
	[cacheController setAuthorImage:dtlObj.author_thumbnail_uri forAuthorImageView:channelLogoView];
	channelLabel.text = dtlObj.author_username;
	// video info
	titleLabel.text = aVideo.title;
//	NSLog(@"setting movie detail: %@", aVideo.title);
	
	NMStyleUtility * style = [NMStyleUtility sharedStyleUtility];
	otherInfoLabel.text = [NSString stringWithFormat:@"%@  |  %@ views", [style.videoDateFormatter stringFromDate:aVideo.published_at], [style.viewCountFormatter stringFromNumber:aVideo.view_count]];
	// set position of the description
	if ( aVideo.detail.nm_description ) {
		CGRect theFrame;
		theFrame.size = [aVideo.detail.nm_description sizeWithFont:descriptionLabel.font constrainedToSize:descriptionDefaultFrame.size];
		theFrame.origin = descriptionDefaultFrame.origin;
		descriptionLabel.frame = theFrame;
		descriptionLabel.text = aVideo.detail.nm_description;
		
	} else {
		descriptionLabel.text = @"";
	}
	
	if ( self.alpha == 0.0f ) self.alpha = 1.0f;
}

@end
