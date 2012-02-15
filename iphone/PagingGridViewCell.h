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
@property (nonatomic, retain) IBOutlet UIButton *deleteButton;
@property (nonatomic, retain) IBOutlet UIView *highlightView;
@property (nonatomic, assign, getter=isEditing) BOOL editing;
@property (nonatomic, assign, getter=isDragging) BOOL dragging;
@property (nonatomic, assign) CGPoint lastDragLocation;
@property (nonatomic, assign) IBOutlet id<PagingGridViewCellDelegate> delegate;

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
- (IBAction)deleteButtonPressed:(id)sender;

@end

@protocol PagingGridViewCellDelegate <NSObject>
@optional
- (void)gridViewCellDidTap:(PagingGridViewCell *)gridViewCell;
- (void)gridViewCellDidPressAndHold:(PagingGridViewCell *)gridViewCell;
- (BOOL)gridViewCellShouldShowDeleteButton:(PagingGridViewCell *)gridViewCell;
- (void)gridViewCellDidPressDeleteButton:(PagingGridViewCell *)gridViewCell;
- (BOOL)gridViewCellShouldStartDragging:(PagingGridViewCell *)gridViewCell;
- (void)gridViewCellDidStartDragging:(PagingGridViewCell *)gridViewCell;
- (void)gridViewCellDidEndDragging:(PagingGridViewCell *)gridViewCell;
- (void)gridViewCell:(PagingGridViewCell *)gridViewCell didDragToCenter:(CGPoint)center touchLocation:(CGPoint)touchLocation;
@end
