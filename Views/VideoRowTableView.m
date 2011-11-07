//
//  VideoRowTableView.m
//  ipad
//
//  Created by Chris Haugli on 11/1/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "VideoRowTableView.h"

@implementation VideoRowTableView

- (void)drawRect:(CGRect)rect
{    
    NMStyleUtility *styleUtility = [NMStyleUtility sharedStyleUtility];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect bounds = self.bounds;
    
    UIColor *borderTopColor = [styleUtility channelPanelCellDefaultTopBorder];
    UIColor *borderBottomColor = [styleUtility channelPanelCellDefaultBottomBorder];
    
    // Draw dividers
    CGContextSetFillColorWithColor(context, [borderTopColor CGColor]);
    CGContextFillRect(context, CGRectMake(bounds.size.width - 1, 0, 1, bounds.size.height));
    CGContextSetFillColorWithColor(context, [borderBottomColor CGColor]);
    CGContextFillRect(context, CGRectMake(0, 0, 1, bounds.size.height));    
}

@end
