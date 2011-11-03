//
//  OnBoardProcessChannelView.m
//  ipad
//
//  Created by Chris Haugli on 11/3/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "OnBoardProcessChannelView.h"

@implementation OnBoardProcessChannelView

@synthesize contentView;
@synthesize thumbnailImage;
@synthesize titleLabel;
@synthesize reasonLabel;
@synthesize title;
@synthesize reason;

- (void)setup
{
    [[NSBundle mainBundle] loadNibNamed:@"OnBoardProcessChannelView" owner:self options:nil];
    contentView.frame = self.bounds;
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:contentView];
    
    contentView.backgroundColor = [UIColor clearColor];
    titleLabel.text = @"";
    reasonLabel.text = @"";
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    [contentView release];
    [thumbnailImage release];
    [titleLabel release];
    [reasonLabel release];
    
    [super dealloc];
}

- (void)setTitle:(NSString *)aTitle
{
    if (title != aTitle) {
        [title release];
        title = [aTitle copy];
        titleLabel.text = aTitle;
    }
}

- (void)setReason:(NSString *)aReason
{
    if (reason != aReason) {
        [reason release];
        reason = [aReason copy];
        reasonLabel.text = aReason;        
    }    
}

@end
