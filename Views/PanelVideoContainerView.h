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
	CGSize titleMaxSize;
	UIColor * highlightColor, * normalColor;
	NSInteger indexInTable;
	AGOrientedTableView * tableView;
	CGRect initialFrame;
	@private
	BOOL highlighted_;
    VideoRowController *videoRowDelegate;
}

@property (nonatomic, readonly) UILabel * titleLabel;
@property (nonatomic, readonly) UILabel * datePostedLabel;
@property (nonatomic, readonly) UILabel * durationLabel;
@property (nonatomic, retain) UIColor * highlightColor;
@property (nonatomic, retain) UIColor * normalColor;
@property (nonatomic, assign) NSInteger indexInTable;
@property (nonatomic, assign) AGOrientedTableView * tableView;
@property (nonatomic, assign) VideoRowController *videoRowDelegate;

- (void)setVideoInfo:(NMVideo *)aVideo;

@end
