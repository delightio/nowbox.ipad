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
	IBOutlet UIButton * unsubscribeButton;
    IBOutlet UIView * subscribeView;
    IBOutlet UIView * unsubscribeView;
    IBOutlet NMCachedImageView * channelThumbnailView;
    IBOutlet UIView * containerView;
	CGRect descriptionDefaultFrame;
    BOOL shouldDismiss;
	
	NMChannel * channel;
	NSMutableArray * previewViewsArray;
	NSNumberFormatter * countFormatter;    
}

@property (nonatomic, retain) NMChannel * channel;

- (void)setDescriptionLabelText;
- (void)setPreviewImages;
-(IBAction)subscribeChannel:(id)sender;
-(IBAction)subscribeAndWatchChannel:(id)sender;
-(IBAction)unsubscribeChannel:(id)sender;


@end
