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
@synthesize watchLaterButton, likeButton;

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
	style = [NMStyleUtility sharedStyleUtility];
	
	descriptionDefaultFrame  = descriptionLabel.frame;
	titleDefaultFrame = titleLabel.frame;
	titleMaxSize = titleDefaultFrame.size;
	titleMaxSize.height *= 3.0f;
	otherInfoDefaultPosition = otherInfoLabel.center;
	
	shadowImageView.image = [[NMStyleUtility sharedStyleUtility].videoShadowImage stretchableImageWithLeftCapWidth:0 topCapHeight:2];
	CALayer * blackLayer = [CALayer layer];
	blackLayer.shouldRasterize = YES;
	blackLayer.backgroundColor = [NMStyleUtility sharedStyleUtility].blackColor.CGColor;
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
		authorThumbnailView.image = nil;
		authorLabel.text = nil;
		titleLabel.text = nil;
		otherInfoLabel.text = nil;
		descriptionLabel.text = nil;
		// reset size
		titleLabel.frame = titleDefaultFrame;
		descriptionLabel.frame = descriptionDefaultFrame;
		otherInfoLabel.center = otherInfoDefaultPosition;
		return;
	} else {
		return;
	}
	// video info - try to show the whole title, max three lines
	CGRect theRect = titleLabel.frame;
	theRect.size = [aVideo.title sizeWithFont:titleLabel.font constrainedToSize:titleMaxSize];
	titleLabel.frame = theRect;
	
	titleLabel.text = aVideo.title;
	// update the view with the video's attribute
	NMVideoDetail * dtlObj = aVideo.detail;
	
	CGFloat titleHeightDiff = theRect.size.height - titleDefaultFrame.size.height;
	
	// other info
	CGPoint thePoint = otherInfoDefaultPosition;
	thePoint.y += titleHeightDiff;
	otherInfoLabel.text = [NSString stringWithFormat:@"%@  |  %@ views", [style.videoDateFormatter stringFromDate:aVideo.published_at], [style.viewCountFormatter stringFromNumber:aVideo.view_count]];
	otherInfoLabel.center = thePoint;
	
	// author info
	[authorThumbnailView setImageForAuthorThumbnail:dtlObj];
	authorLabel.text = dtlObj.author_username;
//	NSLog(@"setting movie detail: %@", aVideo.title);
	
	// set position of the description
	if ( aVideo.detail.nm_description ) {
		CGRect theFrame = descriptionDefaultFrame;
		theFrame.size.height -= titleHeightDiff;
		theFrame.origin.y += titleHeightDiff;
		theFrame.size = [aVideo.detail.nm_description sizeWithFont:descriptionLabel.font constrainedToSize:theFrame.size];
		descriptionLabel.frame = theFrame;
		descriptionLabel.text = aVideo.detail.nm_description;
		
	} else {
		descriptionLabel.text = @"";
	}
	
	if ( self.alpha == 0.0f ) self.alpha = 1.0f;
}

@end
