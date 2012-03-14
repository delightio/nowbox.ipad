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
@synthesize likesCountLabel;
@synthesize showsLikesCount;

- (void)setup
{    
    [[NSBundle mainBundle] loadNibNamed:@"BuzzCommentView" owner:self options:nil];
    contentView.frame = self.bounds;
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:contentView];
    
    contentView.backgroundColor = [UIColor clearColor];
    commentRightPadding = self.frame.size.width - CGRectGetMaxX(commentLabel.frame);
    
    UIFont *labelFont = [UIFont fontWithName:@"Futura-CondensedMedium" size:14.0f backupFontName:@"Futura-Medium" size:12.0f];
    userLabel.font = labelFont;
    timeLabel.font = labelFont;
    commentLabel.font = labelFont;
    likesCountLabel.font = labelFont;
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
    [likesCountLabel release];
    
    [super dealloc];
}

- (void)setShowsLikesCount:(BOOL)aShowsLikesCount
{
    showsLikesCount = aShowsLikesCount;
    likesCountLabel.hidden = !showsLikesCount;
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

    if ([commentLabel.text length] > 0) {
        likesCountLabel.frame = CGRectMake(frame.origin.x, frame.origin.y + frame.size.height + padding, frame.size.width, likesCountLabel.frame.size.height);    
    } else {
        // No comment - show likes instead
        likesCountLabel.frame = CGRectMake(frame.origin.x, frame.origin.y, likesCountLabel.frame.size.width, likesCountLabel.frame.size.height);
    }

    CGFloat maxY;
    if (CGRectGetMaxY(commentLabel.frame) + padding > size.height) {
        // Comment label too tall for view - shrink it
        frame.size.height = size.height - padding - frame.origin.y;
        
        maxY = CGRectGetMaxY(frame) + padding;
        likesCountLabel.hidden = YES;
    } else if (showsLikesCount && (CGRectGetMaxY(likesCountLabel.frame) + padding > size.height || [commentLabel.text length] == 0)) {
        // Comment label and likes count fit
        maxY = CGRectGetMaxY(likesCountLabel.frame) + padding;    
        likesCountLabel.hidden = NO;        
    } else {
        // Comment label fits but likes count doesn't, or likes count hidden
        maxY = CGRectGetMaxY(frame) + padding;
        likesCountLabel.hidden = YES;
    }
    
    commentLabel.frame = frame;
    
    return CGSizeMake(theSize.width, maxY);
}

@end
