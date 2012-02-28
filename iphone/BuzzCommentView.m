//
//  BuzzCommentView.m
//  ipad
//
//  Created by Chris Haugli on 2/28/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "BuzzCommentView.h"
#import "UIFont+BackupFont.h"

@implementation BuzzCommentView

@synthesize contentView;
@synthesize userImageView;
@synthesize userLabel;
@synthesize serviceIcon;
@synthesize timeLabel;
@synthesize commentLabel;

- (void)setup
{    
    [[NSBundle mainBundle] loadNibNamed:@"BuzzCommentView" owner:self options:nil];
    contentView.frame = self.bounds;
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:contentView];
    
    contentView.backgroundColor = [UIColor clearColor];
    commentRightPadding = self.frame.size.width - CGRectGetMaxX(commentLabel.frame);
    
    userLabel.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:14.0f backupFontName:@"Futura-Medium" size:12.0f];
    timeLabel.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:14.0f backupFontName:@"Futura-Medium" size:12.0f];
    commentLabel.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:14.0f backupFontName:@"Futura-Medium" size:12.0f];
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
    [userImageView release];
    [userLabel release];
    [serviceIcon release];
    [timeLabel release];
    [commentLabel release];
    
    [super dealloc];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize theSize = [super sizeThatFits:size];
    CGFloat padding = userLabel.frame.origin.y;
    
    // Position views based on how much text there is in labels
    [userLabel sizeToFit];
    CGRect frame = serviceIcon.frame;
    frame.origin.x = CGRectGetMaxX(userLabel.frame) + 5;
    serviceIcon.frame = frame;
    
    frame = timeLabel.frame;
    frame.origin.x = CGRectGetMaxX(serviceIcon.frame) + 5;
    timeLabel.frame = frame;
    
    [commentLabel sizeToFit];
    frame = commentLabel.frame;
    frame.size.width = self.frame.size.width - commentRightPadding - frame.origin.x;

    // Comment label too tall for view - shrink it
    if (CGRectGetMaxY(commentLabel.frame) + padding > size.height) {
        frame.size.height = size.height - padding - frame.origin.y;
    }
    
    commentLabel.frame = frame;
    
    return CGSizeMake(theSize.width, CGRectGetMaxY(commentLabel.frame) + padding);
}

@end
