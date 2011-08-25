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
	IBOutlet UIView * moviePlaceholderView;
	IBOutlet UIButton * watchLaterButton;
	IBOutlet UIButton * likeButton;
	IBOutlet UIImageView * shadowImageView;
	
@private
	NMStyleUtility * style;
	NMVideo * video_;
	CGRect descriptionDefaultFrame;
	CGRect titleDefaultFrame;
	CGPoint otherInfoDefaultPosition;
	CGSize titleMaxSize;
}

@property (nonatomic, assign) NMVideo * video;
@property (nonatomic, assign) UIButton * watchLaterButton;
@property (nonatomic, assign) UIButton * likeButton;

@end
