//
//  FindChannelTableCell.m
//  ipad
//
//  Created by Chris Haugli on 10/31/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "FindChannelTableCell.h"

@implementation FindChannelTableCell

@synthesize subscribeButton;

- (void)dealloc
{
    [subscribeButton release];
    [super dealloc];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated 
{
    [super setHighlighted:highlighted animated:animated];
    subscribeButton.highlighted = NO;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
    [super setSelected:selected animated:animated];
    subscribeButton.selected = NO;
    subscribeButton.highlighted = NO;
}

@end
