//
//  PagingGridViewCell.h
//  ipad
//
//  Created by Chris Haugli on 2/6/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMCachedImageView.h"

@protocol PagingGridViewCellDelegate;

@interface PagingGridViewCell : UIButton {
    NSTimer *pressAndHoldTimer;
    CGPoint dragAnchorPoint;
}

@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet NMCachedImageView *image;
@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, assign, getter=isDraggable) BOOL draggable;
@property (nonatomic, assign) CGPoint lastDragLocation;
@property (nonatomic, assign) IBOutlet id<PagingGridViewCellDelegate> delegate;

@end

@protocol PagingGridViewCellDelegate <NSObject>
@optional
- (void)gridViewCellDidTap:(PagingGridViewCell *)gridViewCell;
- (void)gridViewCellDidBeginRearranging:(PagingGridViewCell *)gridViewCell;
- (void)gridViewCellDidEndRearranging:(PagingGridViewCell *)gridViewCell;
- (void)gridViewCell:(PagingGridViewCell *)gridViewCell didDragToCenter:(CGPoint)center touchLocation:(CGPoint)touchLocation;
@end
