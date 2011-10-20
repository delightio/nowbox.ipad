//
//  PanelVideoCell.m
//  ipad
//
//  Created by Chris Haugli on 10/18/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "PanelVideoCell.h"
#import "NMStyleUtility.h"
#import "VideoRowController.h"
#import "ToolTipController.h"

#define NM_VIDEO_CELL_PADDING 10.0

@implementation PanelVideoCell

@synthesize title;
@synthesize duration;
@synthesize dateString;
@synthesize state;
@synthesize viewed;
@synthesize firstCell;
@synthesize sessionStartCell;
@synthesize isPlayingVideo;
@synthesize statusImage;
@synthesize videoRowDelegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.opaque = YES;
        self.clearsContextBeforeDrawing = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.userInteractionEnabled = YES;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UITapGestureRecognizer *singleFingerDTap = [[UITapGestureRecognizer alloc]
                                                    initWithTarget:self action:@selector(handleSingleDoubleTap:)];
        singleFingerDTap.numberOfTapsRequired = 1;
        [self addGestureRecognizer:singleFingerDTap];
        [singleFingerDTap release];
    }
    return self;
}

- (void)dealloc
{
    [title release];
    [duration release];
    [dateString release];
    [statusImage release];
    
    [super dealloc];
}

- (void)setState:(PanelVideoCellState)aState
{
    if (state == aState) return;
    
    state = aState;
    switch (state) {
        case PanelVideoCellStateDefault:
            self.statusImage = nil;
            break;
        case PanelVideoCellStateFavorite:
            self.statusImage = [NMStyleUtility sharedStyleUtility].videoStatusFavImage;
            break;
        case PanelVideoCellStateQueued:
            self.statusImage = [NMStyleUtility sharedStyleUtility].videoStatusQueuedImage;
            break;
        case PanelVideoCellStateHot:
            self.statusImage = [NMStyleUtility sharedStyleUtility].videoStatusHotImage;
            break;
        case PanelVideoCellStateUnplayable:
            self.statusImage = [NMStyleUtility sharedStyleUtility].videoStatusBadImage;
            break;
    }
    
    [self setNeedsDisplay];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self setNeedsDisplay];
}

+ (void)drawGradientInRect:(CGRect)rect startColor:(UIColor *)startColor endColor:(UIColor *)endColor context:(CGContextRef)context
{
    CGGradientRef gradient;
    CGColorSpaceRef rgbColorspace;
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    
    const CGFloat *startComponents = CGColorGetComponents(startColor.CGColor);
    const CGFloat *endComponents = CGColorGetComponents(endColor.CGColor);
    
    CGFloat components[8] = { startComponents[0], startComponents[1], startComponents[2], startComponents[3],  // Start color
        endComponents[0], endComponents[1], endComponents[2], endComponents[3] }; // End color
    
    rgbColorspace = CGColorSpaceCreateDeviceRGB();
    gradient = CGGradientCreateWithColorComponents(rgbColorspace, components, locations, num_locations);
    
    CGPoint topCenter = CGPointMake(CGRectGetMidX(rect), 0.0f);
    CGPoint bottomCenter = CGPointMake(CGRectGetMidX(rect), rect.size.height);
    CGContextDrawLinearGradient(context, gradient, topCenter, bottomCenter, 0);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(rgbColorspace); 
}

//- (void)drawContentView:(CGRect)rect highlighted:(BOOL)aHighlighted
- (void)drawRect:(CGRect)rect
{    
    NMStyleUtility *styleUtility = [NMStyleUtility sharedStyleUtility];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect bounds = self.bounds;
    
    UIColor *backgroundStartColor;
    UIColor *backgroundEndColor;
    UIColor *borderTopColor;
    UIColor *borderBottomColor;
    UIColor *dividerColor;
    UIColor *titleFontColor;
    UIColor *detailFontColor;
    
    // Get colors from style utility
    if (highlighted) {
        backgroundStartColor = [styleUtility channelPanelCellHighlightedBackgroundStart];
        backgroundEndColor = [styleUtility channelPanelCellHighlightedBackgroundEnd];
        borderTopColor = [styleUtility channelPanelCellHighlightedTopBorder];
        borderBottomColor = [styleUtility channelPanelCellHighlightedBottomBorder];
        dividerColor = [styleUtility channelPanelCellHighlightedDivider];
        titleFontColor = [styleUtility videoTitleHighlightedFontColor];
        detailFontColor = [styleUtility videoDetailHighlightedFontColor];
    } else if (viewed) {
        backgroundStartColor = [styleUtility channelPanelCellDimmedBackgroundStart];
        backgroundEndColor = [styleUtility channelPanelCellDimmedBackgroundEnd];
        borderTopColor = [styleUtility channelPanelCellDimmedTopBorder];
        borderBottomColor = [styleUtility channelPanelCellDimmedBottomBorder];
        dividerColor = [styleUtility channelPanelCellDimmedDivider];
        titleFontColor = [styleUtility videoTitlePlayedFontColor];
        detailFontColor = [styleUtility videoDetailPlayedFontColor];
    } else {
        backgroundStartColor = [styleUtility channelPanelCellDefaultBackgroundStart];
        backgroundEndColor = [styleUtility channelPanelCellDefaultBackgroundEnd];
        borderTopColor = [styleUtility channelPanelCellDefaultTopBorder];
        borderBottomColor = [styleUtility channelPanelCellDefaultBottomBorder];
        dividerColor = [styleUtility channelPanelCellDefaultDivider];
        
        if (state == PanelVideoCellStateUnplayable) {            
            titleFontColor = [styleUtility videoTitlePlayedFontColor];
            detailFontColor = [styleUtility videoDetailPlayedFontColor];            
        } else {
            titleFontColor = [styleUtility videoTitleFontColor]; 
            detailFontColor = [styleUtility videoDetailFontColor];
        }
    }
    
    // Draw background gradient
    [PanelVideoCell drawGradientInRect:bounds startColor:backgroundStartColor endColor:backgroundEndColor context:context];
    
//    CGContextSetFillColorWithColor(context, [backgroundStartColor CGColor]);
//    CGContextFillRect(context, bounds);
    
    // Draw dividers
    CGContextSetFillColorWithColor(context, [borderTopColor CGColor]);
    CGContextFillRect(context, CGRectMake(0, 0, bounds.size.width, 1));
    CGContextSetFillColorWithColor(context, [borderBottomColor CGColor]);
    CGContextFillRect(context, CGRectMake(0, bounds.size.height - 1, bounds.size.width, 1));
    CGContextSetFillColorWithColor(context, [dividerColor CGColor]);
    CGContextFillRect(context, CGRectMake(bounds.size.width - 1, 0, 1, bounds.size.height));
    
    if (firstCell) {
        CGContextFillRect(context, CGRectMake(0, 0, 1, bounds.size.height));
    }
    
    // Draw labels
    CGRect titleRect = CGRectMake(NM_VIDEO_CELL_PADDING, NM_VIDEO_CELL_PADDING, bounds.size.width - NM_VIDEO_CELL_PADDING*2, bounds.size.height - NM_VIDEO_CELL_PADDING*2 - 12);
    CGRect dateRect = CGRectMake(NM_VIDEO_CELL_PADDING, NM_VIDEO_CELL_HEIGHT - 24.0f, bounds.size.width - NM_VIDEO_CELL_PADDING * 2.0f, 13.0f);
    CGRect durationRect = CGRectMake(NM_VIDEO_CELL_PADDING, NM_VIDEO_CELL_HEIGHT - 24.0f, bounds.size.width - NM_VIDEO_CELL_PADDING * 2.0f, 13.0f);
    
    if (viewed && !highlighted) {
        // Draw text shadows
        CGRect titleShadowRect = CGRectOffset(titleRect, 0, 1);
        CGRect dateShadowRect = CGRectOffset(dateRect, 0, 1);
        CGRect durationShadowRect = CGRectOffset(durationRect, 0, 1);
        CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
        
        [title drawInRect:titleShadowRect 
                 withFont:styleUtility.videoTitleFont 
            lineBreakMode:UILineBreakModeWordWrap
                alignment:UITextAlignmentLeft];
        
        [dateString drawInRect:dateShadowRect
                      withFont:styleUtility.videoDetailFont 
                 lineBreakMode:UILineBreakModeClip
                     alignment:UITextAlignmentLeft];
        
        [duration drawInRect:durationShadowRect
                    withFont:styleUtility.videoDetailFont 
               lineBreakMode:UILineBreakModeClip
                   alignment:UITextAlignmentRight];
    }    
    
    CGContextSetFillColorWithColor(context, [titleFontColor CGColor]);
    [title drawInRect:titleRect 
             withFont:styleUtility.videoTitleFont 
        lineBreakMode:UILineBreakModeWordWrap
            alignment:UITextAlignmentLeft];
    
    CGContextSetFillColorWithColor(context, [detailFontColor CGColor]);
    [dateString drawInRect:dateRect
                  withFont:styleUtility.videoDetailFont 
             lineBreakMode:UILineBreakModeClip
                 alignment:UITextAlignmentLeft];
    
    CGContextSetFillColorWithColor(context, [detailFontColor CGColor]);
    [duration drawInRect:durationRect
                withFont:styleUtility.videoDetailFont 
           lineBreakMode:UILineBreakModeClip
               alignment:UITextAlignmentRight];
    
    [statusImage drawInRect:CGRectMake(bounds.size.width - 27, 0, 28, 26)];
    
    if (sessionStartCell) {
        [[styleUtility videoNewSessionIndicatorImage] drawInRect:CGRectMake(0, 0, 6, bounds.size.height)];
    }
}

- (void)setIsPlayingVideo:(BOOL)playing {
    isPlayingVideo = playing;
    [self changeViewToHighlighted:playing];
}

- (void)setHighlighted:(BOOL)isHighlighted animated:(BOOL)animated
{
    // Do nothing, we will handle highlighting ourselves
}

- (void)setViewed:(BOOL)isViewed
{
    viewed = isViewed;
    [self setNeedsDisplay];
}

- (void)changeViewToHighlighted:(BOOL)isHighlighted 
{
    highlighted = isHighlighted;
    [self setNeedsDisplay];
}

- (void)removeFromSuperview
{
    [videoRowDelegate recycleCell:self];
    [super removeFromSuperview];
}

#pragma mark UIResponder

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	// highlight
    [self changeViewToHighlighted:YES];
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	// check if touch up inside the view itself
    [self changeViewToHighlighted:isPlayingVideo];
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	// remove highlight
    // only if it wasn't highlighted previously
    [self changeViewToHighlighted:isPlayingVideo];
    [super touchesCancelled:touches withEvent:event];
}

- (void)handleSingleDoubleTap:(UIGestureRecognizer *)sender {
    if (state != PanelVideoCellStateUnplayable) {
        if (videoRowDelegate) {
            [self changeViewToHighlighted:YES];
            [videoRowDelegate playVideoForIndexPath:[NSIndexPath indexPathForRow:self.tag inSection:0]];
            [[ToolTipController sharedToolTipController] notifyEvent:ToolTipEventVideoTap];            
        }
    } else {
        [[ToolTipController sharedToolTipController] notifyEvent:ToolTipEventBadVideoTap];
    }
}

@end
