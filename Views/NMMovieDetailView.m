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
@synthesize thumbnailContainerView;

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
	
	if ( NM_RUNNING_ON_IPAD ) {
		descriptionDefaultFrame  = descriptionLabel.frame;
		titleDefaultFrame = titleLabel.frame;
		titleMaxSize = titleDefaultFrame.size;
		titleMaxSize.height *= 3.0f;
		otherInfoDefaultPosition = otherInfoLabel.center;
		
		bitmapShadow = [CALayer layer];
		bitmapShadow.frame = CGRectMake(0.0f, 0.0f, 20.0f, 380.0f);
		bitmapShadow.contents = (id)[NMStyleUtility sharedStyleUtility].videoShadowImage.CGImage;
		[infoContainerView.layer insertSublayer:bitmapShadow above:infoContainerView.layer];
		//	[self.layer addSublayer:bitmapShadow];
		// the background image
		self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"playback_background_pattern"]];
		// the fake movie view box
		blackLayer = [CALayer layer];
		blackLayer.shouldRasterize = YES;
		blackLayer.backgroundColor = [NMStyleUtility sharedStyleUtility].blackColor.CGColor;
		blackLayer.frame = CGRectMake(0.0, 0.0, 640.0, 380.0);
		[self.layer insertSublayer:blackLayer below:thumbnailContainerView.layer];
		// update the font
		if ( !NM_RUNNING_IOS_5 ) {
			UIFont * theFont = [NMStyleUtility sharedStyleUtility].channelNameFont;
			descriptionLabel.font = theFont;
			otherInfoLabel.font = theFont;
			authorLabel.font = [NMStyleUtility sharedStyleUtility].videoDetailFont;
		}
	} else {
		// dump the whole thing
		[infoContainerView removeFromSuperview];
		infoContainerView = nil;
		authorLabel = nil;
		titleLabel = nil;
		otherInfoLabel = nil;
		descriptionLabel = nil;
		authorThumbnailView = nil;
		// resize the view
		thumbnailContainerView.frame = self.bounds;
		thumbnailContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	}
	
	CALayer * theLayer = activityView.layer;
	theLayer.backgroundColor = [[NMStyleUtility sharedStyleUtility].blackColor colorWithAlphaComponent:0.5f].CGColor;
	theLayer.cornerRadius = 10.0f;
}

- (void)setVideo:(NMVideo *)aVideo {
	if ( aVideo && aVideo != video_ ) {
		// assigned property. no need to retain
		video_ = aVideo;
	} else if ( aVideo == nil ) {
		video_ = nil;
		
		// reset the view
		[movieThumbnailView cancelDownload];
		movieThumbnailView.image = nil;
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
		NSLog(@"movie detail view did nothing");
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
	
	// movie thumbnail
	thumbnailContainerView.alpha = 1.0f;
	[self setActivityViewHidden:YES];
	[movieThumbnailView setImageForVideoThumbnail:aVideo];
	
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
	
}

- (void)fadeOutThumbnailView:(id)sender context:(void *)ctx {
	[UIView beginAnimations:nil context:ctx];
	[UIView setAnimationDuration:0.25f];
	[UIView setAnimationDelay:0.5f];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView setAnimationDelegate:sender];
	thumbnailContainerView.alpha = 0.0f;
	[UIView commitAnimations];
}

- (void)slowFadeOutThumbnailView:(id)sender context:(void *)ctx {
	[UIView beginAnimations:nil context:ctx];
	[UIView setAnimationDuration:0.25f];
	[UIView setAnimationDelay:0.75f];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView setAnimationDelegate:sender];
	thumbnailContainerView.alpha = 0.0f;
	[UIView commitAnimations];
}

- (void)restoreThumbnailView {
	if ( thumbnailContainerView.alpha == 0.0f ) thumbnailContainerView.alpha = 1.0f;
}

- (void)setLayoutWhenPinchedForFullScreen:(BOOL)isFullScreen {
	if ( isFullScreen ) {
		infoContainerView.alpha = 0.0f;
		infoContainerView.center = CGPointMake(1216.0f, 190.0f);
		// resize view
		thumbnailContainerView.frame = CGRectMake(0.0f, 0.0f, 1024.0f, 768.0f);
	} else {
		infoContainerView.hidden = NO;
		infoContainerView.alpha = 1.0f;
		infoContainerView.center = CGPointMake(832.0f, 190.0f);
//		bitmapShadow.position = CGPointMake(650.0f, 190.0f);
		thumbnailContainerView.frame = CGRectMake(0.0f, 0.0f, 640.0f, 380.0f);
	}
}

- (void)resetLayoutAfterPinchedForFullScreen:(BOOL)isFullScreen {
	CGRect theFrame = thumbnailContainerView.frame;
	if ( isFullScreen ) {
		infoContainerView.hidden = YES;
		theFrame.size.width = 1044.0f;
	} /*else {
		infoContainerView.hidden = NO;
		bitmapShadow.hidden = NO;
	}*/
	blackLayer.frame = theFrame;
}

- (void)configureMovieThumbnailForFullScreen:(BOOL)isFullScreen {
	CGRect theFrame;
	if ( isFullScreen ) {
		infoContainerView.hidden = YES;
		infoContainerView.alpha = 0.0f;
		infoContainerView.center = CGPointMake(1216.0f, 190.0f);
//		bitmapShadow.position = CGPointMake(1034.0f, 190.0f);
		// resize view
		theFrame = CGRectMake(0.0f, 0.0f, 1024.0f, 768.0f);
		thumbnailContainerView.frame = theFrame;
		theFrame.size.width = 1044.0f;
	} else {
		infoContainerView.hidden = NO;
		infoContainerView.alpha = 1.0f;
		infoContainerView.center = CGPointMake(832.0f, 190.0f);
//		bitmapShadow.position = CGPointMake(650.0f, 190.0f);
		theFrame = CGRectMake(0.0f, 0.0f, 640.0f, 380.0f);
		thumbnailContainerView.frame = theFrame;
	}
	blackLayer.frame = theFrame;
}

- (void)setActivityViewHidden:(BOOL)aflag {
	activityView.hidden = aflag;
	if ( aflag ) {
		[loaderView stopAnimating];
	} else {
		[loaderView startAnimating];
	}
}

@end
