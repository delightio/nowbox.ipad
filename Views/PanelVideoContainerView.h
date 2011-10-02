//
//  PanelVideoContainerView.h
//  ipad
//
//  Created by Bill So on 20/06/2011.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "AGOrientedTableView.h"
@class NMVideo, PanelVideoCellView;

@interface PanelVideoContainerView : UITableViewCell {
    UIView *backgroundColorView;
    UILabel * titleLabel;
	UILabel * datePostedLabel;
	UILabel * durationLabel;
//	UILabel * viewsLabel;
	CGSize titleMaxSize;
	NSInteger indexInTable;
	AGOrientedTableView * tableView;
	CGRect initialFrame;
	BOOL videoNewSession;

    @private
	BOOL currentVideoIsPlaying;
    VideoRowController *videoRowDelegate;
//    UIImageView *highlightedBackgroundImage;
    UIImageView *videoStatusImageView;
    BOOL isVideoPlayable;
    
    BOOL isFirstCell;
    
    PanelVideoCellView *cellView, *highlightedCellView;

}

//@property (nonatomic, readonly) UIImageView *highlightedBackgroundImage;
@property (nonatomic, readonly) UIImageView *videoStatusImageView;
@property (nonatomic, readonly) UIView *backgroundColorView;
@property (nonatomic, readonly) UILabel * titleLabel;
@property (nonatomic, readonly) UILabel * datePostedLabel;
@property (nonatomic, readonly) UILabel * durationLabel;
//@property (nonatomic, readonly) UILabel * viewsLabel;
@property (nonatomic, assign) NSInteger indexInTable;
@property (nonatomic, assign) AGOrientedTableView * tableView;
@property (nonatomic, assign) VideoRowController *videoRowDelegate;
@property (nonatomic, assign) BOOL videoNewSession;
@property (nonatomic, assign) BOOL isFirstCell;

- (void)setVideoInfo:(NMVideo *)aVideo;
- (void)setIsLoadingCell;
- (void)changeViewToHighlighted:(BOOL)isHighlighted;
- (void)setIsPlayingVideo:(BOOL)abool;
-(void)handleSingleDoubleTap:(UIGestureRecognizer *)sender;

@end
