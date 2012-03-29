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
@synthesize thumbnailImageView;
@synthesize titleLabel;
@synthesize reasonLabel;
@synthesize title;
@synthesize reason;

- (void)setupWithExistingFrame:(BOOL)useExistingFrame
{
    [[NSBundle mainBundle] loadNibNamed:@"OnBoardProcessChannelView" owner:self options:nil];
    
    if (useExistingFrame) {
        contentView.frame = self.bounds;
    } else {
        self.frame = contentView.bounds;
    }
    
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:contentView];
    
    titleLabel.text = @"";
    reasonLabel.text = @"";
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setupWithExistingFrame:NO];
    }
    return self;
}

- (void)dealloc
{
    [contentView release];
    [thumbnailImageView release];
    [titleLabel release];
    [reasonLabel release];
    [title release];
    
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
