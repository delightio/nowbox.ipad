//
//  PanelVideoContainerView.h
//  ipad
//
//  Created by Bill So on 20/06/2011.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "AGOrientedTableView.h"
@class NMVideo;

@interface PanelVideoContainerView : UITableViewCell {
    UIView *backgroundColorView;
    UILabel * titleLabel;
	UILabel * datePostedLabel;
	UILabel * durationLabel;
	UILabel * viewsLabel;
	CGSize titleMaxSize;
	UIColor * highlightColor, * normalColor;
	NSInteger indexInTable;
	AGOrientedTableView * tableView;
	CGRect initialFrame;
	@private
	BOOL currentVideoIsPlaying;
    VideoRowController *videoRowDelegate;
    UIView *separatorView;
    UIImageView *highlightedBackgroundImage;
}

@property (nonatomic, readonly) UILabel * titleLabel;
@property (nonatomic, readonly) UILabel * datePostedLabel;
@property (nonatomic, readonly) UILabel * durationLabel;
@property (nonatomic, readonly) UILabel * viewsLabel;
@property (nonatomic, retain) UIColor * highlightColor;
@property (nonatomic, retain) UIColor * normalColor;
@property (nonatomic, assign) NSInteger indexInTable;
@property (nonatomic, assign) AGOrientedTableView * tableView;
@property (nonatomic, assign) VideoRowController *videoRowDelegate;

- (void)setVideoInfo:(NMVideo *)aVideo;
- (void)changeViewToHighlighted:(BOOL)isHighlighted;
- (void)setIsPlayingVideo:(BOOL)abool;

@end
