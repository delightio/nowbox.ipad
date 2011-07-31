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
	NMVideo * video_;
	CGRect descriptionDefaultFrame;
}

@property (nonatomic, assign) NMVideo * video;

@end
