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
    UILabel * titleLabel;
	UILabel * datePostedLabel;
	UILabel * durationLabel;
	UILabel * viewsLabel;
	CGSize titleMaxSize;
	UIColor * highlightColor, * normalColor;
	NSInteger indexInTable;
	id panelDelegate;
	AGOrientedTableView * tableView;
	CGRect initialFrame;
	@private
	BOOL highlighted_;
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

- (void)setVideoInfo:(NMVideo *)aVideo;
- (void)changeViewToHighlighted:(BOOL)isHighlighted;

@end
