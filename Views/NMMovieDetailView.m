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

- (void)awakeFromNib {
	UIImage * img = [UIImage imageNamed:@"movie-detail-view-background"];
	self.layer.contents = (id)img.CGImage;
	self.layer.contentsCenter = CGRectMake(0.2, 0.0, 0.6, 1.0);
	moviePlaceholderView.layer.borderColor = [UIColor colorWithRed:102.0f/255.0f green:102.0f/255.0f blue:102.0f/255.0f alpha:1.0f].CGColor;
	moviePlaceholderView.layer.borderWidth = 1.0f;
}

- (void)dealloc
{
    [super dealloc];
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
		descriptionTextView.text = nil;
		return;
	} else {
		return;
	}
	// update the view with the video's attribute
	NMChannel * theChannel = aVideo.channel;
	
	// channel info
	NMCacheController * cacheCtrl = [NMCacheController sharedCacheController];
	[cacheCtrl setImageInChannel:theChannel forImageView:channelLogoView];
	channelLabel.text = theChannel.title;
	// video info
	titleLabel.text = aVideo.title;
//	NSLog(@"setting movie detail: %@", aVideo.title);
	
	otherInfoLabel.text = [NSString stringWithFormat:@"%@  |  xx,xxx views", [[NMStyleUtility sharedStyleUtility].videoDateFormatter stringFromDate:aVideo.published_at]];
	descriptionTextView.text = aVideo.detail.nm_description;
}

@end
