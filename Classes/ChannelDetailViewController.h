//
//  ChannelDetailViewController.h
//  ipad
//
//  Created by Bill So on 1/9/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMLibrary.h"
#import "NMCachedImageView.h"

@interface ChannelDetailViewController : UIViewController {
	IBOutlet UIScrollView * thumbnailScrollView;
	IBOutlet UILabel * descriptionLabel;
	IBOutlet UILabel * titleLabel;
	IBOutlet UILabel * metricLabel;
	IBOutlet UIButton * subscribeAndWatchButton;
	IBOutlet UIButton * subscribeButton;
	IBOutlet NMCachedImageView * channelThumbnailView;
	CGRect descriptionDefaultFrame;
	
	NMChannel * channel;
	NSMutableArray * videoThumbnailArray;
}

@property (nonatomic, retain) NMChannel * channel;

- (void)setDescriptionLabelText;
- (void)setPreviewImages;

@end
