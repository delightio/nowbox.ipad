//
//  PanelVideoCell.h
//  ipad
//
//  Created by Chris Haugli on 10/18/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VideoRowController;

typedef enum {
    PanelVideoCellStateDefault,
    PanelVideoCellStateUnplayable,
    PanelVideoCellStateFavorite,
    PanelVideoCellStateHot,
    PanelVideoCellStateQueued
} PanelVideoCellState;

@interface PanelVideoCell : UITableViewCell {
    BOOL highlighted;
}

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *duration;
@property (nonatomic, copy) NSString *dateString;
@property (nonatomic, assign) PanelVideoCellState state;
@property (nonatomic, assign, getter=isViewed) BOOL viewed;
@property (nonatomic, assign, getter=isLastCell) BOOL lastCell;
@property (nonatomic, assign, getter=isLoadingCell) BOOL loadingCell;
@property (nonatomic, assign, getter=isSessionStartCell) BOOL sessionStartCell;
@property (nonatomic, assign) BOOL isPlayingVideo;
@property (nonatomic, retain) UIImage *statusImage;
@property (nonatomic, retain) IBOutlet UILabel *loadingText;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, assign) VideoRowController *videoRowDelegate;
@property (nonatomic, assign) BOOL highlightOnTouch;

- (void)changeViewToHighlighted:(BOOL)isHighlighted;

@end
