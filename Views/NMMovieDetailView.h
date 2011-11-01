//
//  NMMovieDetailView.h
//  ipad
//
//  Created by Bill So on 6/14/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMCacheController.h"
#import "NMCachedImageView.h"
#import "NMStyleUtility.h"

@class NMVideo;

@interface NMMovieDetailView : UIView {
    IBOutlet NMCachedImageView * authorThumbnailView;
	IBOutlet UILabel * authorLabel;
	IBOutlet UILabel * titleLabel;
	IBOutlet UILabel * otherInfoLabel;
	IBOutlet UILabel * descriptionLabel;
	IBOutlet UIView * infoContainerView;
	// movie thumbnail
	IBOutlet NMCachedImageView * movieThumbnailView;
	// loading view
	IBOutlet UIView * activityView;
	IBOutlet UIActivityIndicatorView * loaderView;
	// container view of both movie thumbnail and loading view
	IBOutlet UIView * thumbnailContainerView;
	
@private
	NMStyleUtility * style;
	NMVideo * video_;
	CGRect descriptionDefaultFrame;
	CGRect titleDefaultFrame;
	CGPoint otherInfoDefaultPosition;
	CGSize titleMaxSize;
	
//	CALayer * blackLayer, * bitmapShadow;
	CALayer * bitmapShadow;
}

@property (nonatomic, assign) NMVideo * video;
@property (nonatomic, readonly) UIView * thumbnailContainerView;

- (void)fadeOutThumbnailView:(id)sender context:(void *)ctx;
- (void)slowFadeOutThumbnailView:(id)sender context:(void *)ctx;
- (void)restoreThumbnailView;
- (void)configureMovieThumbnailForFullScreen:(BOOL)isFullScreen;

- (void)setActivityViewHidden:(BOOL)aflag;

@end
