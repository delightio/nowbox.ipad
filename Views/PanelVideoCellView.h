//
//  PanelVideoCellView.h
//  ipad
//
//  Created by Tim Chen on 10/8/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PanelVideoContainerView;

@interface PanelVideoCellView : UIView {
    PanelVideoContainerView *cellData;
    BOOL cellIsHighlighted;
    BOOL videoHasPlayed;
    BOOL isWatchLaterChannel;
    BOOL isFavoritesChannel;
}

- (void)configureCellWithPanelVideoContainerView:(PanelVideoContainerView *)cell highlighted:(BOOL)isHighlighted videoPlayed:(BOOL)videoPlayedPreviously;
- (void)drawLabel:(UILabel *)labelToDraw inContext:(CGContextRef)context;
@end
