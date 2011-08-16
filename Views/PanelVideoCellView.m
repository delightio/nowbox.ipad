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
        CGContextSetFillColorWithColor(context, cellData.highlightColor.CGColor);
    } else if (videoHasPlayed) {
        CGContextSetFillColorWithColor(context, cellData.playedColor.CGColor);
    } else {
        CGContextSetFillColorWithColor(context, cellData.normalColor.CGColor);
    }
    CGContextFillRect(context, rectangle);
    
    if (cellIsHighlighted) {
        [cellData.highlightedBackgroundImage.image drawInRect:cellData.highlightedBackgroundImage.frame];
    }
    
    [self drawLabel:cellData.titleLabel inContext:context];
    [self drawLabel:cellData.datePostedLabel inContext:context];
    [self drawLabel:cellData.durationLabel inContext:context];
    [self drawLabel:cellData.viewsLabel inContext:context];
    
    [cellData.videoStatusImageView.image drawInRect:CGRectMake(rectangle.size.width-24, 0, 24, 24)];
    
//    CGContextSetFillColorWithColor(context, [NMStyleUtility sharedStyleUtility].channelBorderColor.CGColor);
//    CGContextFillRect(context, CGRectMake(0, 87, rectangle.size.width, 1));
    
}

- (void)drawLabel:(UILabel *)labelToDraw inContext:(CGContextRef)context {
    if (cellIsHighlighted) {
        CGContextSetFillColorWithColor(context, labelToDraw.highlightedTextColor.CGColor);
    } else {
        CGContextSetFillColorWithColor(context, labelToDraw.textColor.CGColor);
    }
    [labelToDraw.text drawInRect:labelToDraw.frame withFont:labelToDraw.font lineBreakMode:labelToDraw.lineBreakMode alignment:labelToDraw.textAlignment];
}

@end
