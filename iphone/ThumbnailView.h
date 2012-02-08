//
//  ThumbnailView.h
//  ipad
//
//  Created by Chris Haugli on 2/6/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMCachedImageView.h"

@protocol ThumbnailViewDelegate;

@interface ThumbnailView : UIButton {
    NSTimer *pressAndHoldTimer;
    BOOL movable;
    CGPoint dragAnchorPoint;    
}

@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet NMCachedImageView *image;
@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, assign) IBOutlet id<ThumbnailViewDelegate> delegate;

@end

@protocol ThumbnailViewDelegate <NSObject>
@optional
- (void)thumbnailViewDidTap:(ThumbnailView *)thumbnailView;
- (void)thumbnailViewDidBeginRearranging:(ThumbnailView *)thumbnailView;
- (void)thumbnailViewDidEndRearranging:(ThumbnailView *)thumbnailView;
- (void)thumbnailView:(ThumbnailView *)thumbnailView didDragToLocation:(CGPoint)location;
@end
