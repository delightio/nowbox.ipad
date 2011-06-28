//
//  PanelVideoContainerView.h
//  ipad
//
//  Created by Bill So on 20/06/2011.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "HorizontalTableView.h"
@class NMVideo;

@interface PanelVideoContainerView : UIView {
    UILabel * titleLabel;
	UILabel * datePostedLabel;
	UILabel * durationLabel;
	CGSize titleMaxSize;
	UIColor * highlightColor, * normalColor;
	NSInteger indexInTable;
	id panelDelegate;
	HorizontalTableView * tableView;
	
	@private
	BOOL highlighted_;
}

@property (nonatomic, readonly) UILabel * titleLabel;
@property (nonatomic, readonly) UILabel * datePostedLabel;
@property (nonatomic, readonly) UILabel * durationLabel;
@property (nonatomic, retain) UIColor * highlightColor;
@property (nonatomic, retain) UIColor * normalColor;
@property (nonatomic, assign) NSInteger indexInTable;
@property (nonatomic, assign) id<HorizontalTableViewParentPanelDelegate> panelDelegate;
@property (nonatomic, assign) HorizontalTableView * tableView;
@property (nonatomic, assign) BOOL highlighted;

- (void)setVideoInfo:(NMVideo *)aVideo;

@end
