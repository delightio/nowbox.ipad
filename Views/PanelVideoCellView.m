//
//  PanelVideoCellView.m
//  ipad
//
//  Created by Tim Chen on 10/8/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "PanelVideoCellView.h"
#import "PanelVideoContainerView.h"
#import <QuartzCore/QuartzCore.h>

@implementation PanelVideoCellView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.opaque = YES;
        self.clipsToBounds = NO;
    }
    return self;
}

- (void)configureCellWithPanelVideoContainerView:(PanelVideoContainerView *)cell highlighted:(BOOL)isHighlighted videoPlayed:(BOOL)videoPlayedPreviously {
    cellData = cell;
    cellIsHighlighted = isHighlighted;
    videoHasPlayed = videoPlayedPreviously;
    self.frame = cell.frame;
    [self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // background
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rectangle = self.frame;
    
    if (cellIsHighlighted) {
        [[[NMStyleUtility sharedStyleUtility] videoHighlightedBackgroundImage] drawInRect:rectangle];
        CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:36/255 green:36/255 blue:36/255 alpha:1] CGColor]);
    } else if (videoHasPlayed) {
        [[[NMStyleUtility sharedStyleUtility] videoDimmedBackgroundImage] drawInRect:rectangle];
        CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:238/255 green:238/255 blue:238/255 alpha:1] CGColor]);
    } else {
        [[[NMStyleUtility sharedStyleUtility] videoNormalBackgroundImage] drawInRect:rectangle];
        CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
    }
//    CGContextFillRect(context, CGRectMake(0, 0, 1, 99));

    // "fake" separator border"
    if (cellIsHighlighted) {
        CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:36/255 green:36/255 blue:36/255 alpha:1] CGColor]);
    } else if (videoHasPlayed) {
        CGContextSetFillColorWithColor(context, [[[NMStyleUtility sharedStyleUtility] channelBorderColor] CGColor]);
    } else {
        CGContextSetFillColorWithColor(context, [[[NMStyleUtility sharedStyleUtility] channelBorderColor] CGColor]);
    }
    CGContextFillRect(context, CGRectMake(rectangle.size.width-1, 0, 1, 100));
    
    [self drawLabel:cellData.titleLabel inContext:context];
    [self drawLabel:cellData.datePostedLabel inContext:context];
    [self drawLabel:cellData.durationLabel inContext:context];
//    [self drawLabel:cellData.viewsLabel inContext:context];
    
    [cellData.videoStatusImageView.image drawInRect:CGRectMake(rectangle.size.width-27, 0, 28, 26)];
    
    if (cellData.videoNewSession) {
        [[[NMStyleUtility sharedStyleUtility] videoNewSessionIndicatorImage] drawInRect:CGRectMake(0, 0, 7, 100)];
    }
    
//    CGContextSetFillColorWithColor(context, [NMStyleUtility sharedStyleUtility].channelBorderColor.CGColor);
//    CGContextFillRect(context, CGRectMake(0, 87, rectangle.size.width, 1));
    
}

- (void)drawLabel:(UILabel *)labelToDraw inContext:(CGContextRef)context {
    CGRect shadowFrame = labelToDraw.frame;
    shadowFrame.origin.y++;
    
    if (cellIsHighlighted) {
        CGContextSetFillColorWithColor(context, [[UIColor blackColor] CGColor]);
    } else {
        CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
    }
    [labelToDraw.text drawInRect:shadowFrame withFont:labelToDraw.font lineBreakMode:labelToDraw.lineBreakMode alignment:labelToDraw.textAlignment];

    if (cellIsHighlighted) {
        CGContextSetFillColorWithColor(context, labelToDraw.highlightedTextColor.CGColor);
    } else {
        CGContextSetFillColorWithColor(context, labelToDraw.textColor.CGColor);
    }
    [labelToDraw.text drawInRect:labelToDraw.frame withFont:labelToDraw.font lineBreakMode:labelToDraw.lineBreakMode alignment:labelToDraw.textAlignment];
}

@end
