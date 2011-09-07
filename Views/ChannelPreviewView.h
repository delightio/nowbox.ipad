//
//  ChannelPreviewView.h
//  ipad
//
//  Created by Tim Chen on 8/9/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMLibrary.h"
#import "NMCachedImageView.h"

@interface ChannelPreviewView : UIView {
    NMCachedImageView *civ;
    UILabel *titleLabel;
    UILabel *durationLabel;
    UILabel *dateLabel;
    UILabel *viewCountLabel;
}

@property (nonatomic, retain) NMCachedImageView *civ;

-(void)clearPreviewImage;
-(void)setPreviewImage:(NMPreviewThumbnail *)thePreview;

@end
