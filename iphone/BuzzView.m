//
//  BuzzView.m
//  ipad
//
//  Created by Chris Haugli on 2/23/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "BuzzView.h"
#import "UIFont+BackupFont.h"

@interface BuzzView (PrivateMethods)
- (void)repositionComments;
@end

@implementation BuzzView

@synthesize contentView;
@synthesize scrollView;
@synthesize touchArea;
@synthesize noCommentsView;
@synthesize noCommentsLabel;
@synthesize actionButtonsView;
@synthesize showsActionButtons;
@synthesize delegate;

- (void)setup
{    
    [[NSBundle mainBundle] loadNibNamed:@"BuzzView" owner:self options:nil];
    contentView.frame = self.bounds;
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:contentView];
    
    commentViews = [[NSMutableArray alloc] init];  
    
    noCommentsLabel.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:16.0f backupFontName:@"Futura-Medium" size:14.0f];
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
    [commentViews release];
    [scrollView release];
    [touchArea release];
    [noCommentsView release];
    [noCommentsLabel release];
    [actionButtonsView release];

    [super dealloc];
}

- (IBAction)touchAreaPressed:(id)sender
{
    if ([delegate respondsToSelector:@selector(buzzViewDidTap:)]) {
        [delegate buzzViewDidTap:self];
    }
}

- (BuzzCommentView *)addCommentWithText:(NSString *)text username:(NSString *)username
{
    noCommentsView.hidden = YES;
    
    BuzzCommentView *commentView = [[[BuzzCommentView alloc] initWithFrame:scrollView.bounds] autorelease];
    commentView.commentLabel.text = text;
    commentView.userLabel.text = username;
    
    if ([commentViews count] == 0) {
        commentView.frame = scrollView.bounds;
    } else {
        [commentView sizeToFit];
    }
    
    [scrollView insertSubview:commentView belowSubview:touchArea];
    [commentViews addObject:commentView];
    [self repositionComments];
    
    return commentView;
}

- (void)addComment:(NSString *)comment fromUser:(NSString *)user withImage:(UIImage *)userImage withSocialNetworkImage:(UIImage *)networkImage atTime:(NSString *)timeText
{
    noCommentsView.hidden = YES;
    
    BuzzCommentView *commentView = [[[BuzzCommentView alloc] initWithFrame:scrollView.bounds] autorelease];
    commentView.userImageView.image = userImage;
    commentView.userLabel.text = user;
    commentView.commentLabel.text = comment;
    commentView.timeLabel.text = timeText;
    
    if ([commentViews count] == 0) {
        commentView.frame = scrollView.bounds;
    } else {
        [commentView sizeToFit];
    }
    
    [scrollView insertSubview:commentView belowSubview:touchArea];
    [commentViews addObject:commentView];
    [self repositionComments];
}

- (void)removeAllComments
{
    for (UIView *view in commentViews) {
        [view removeFromSuperview];
    }
    [commentViews removeAllObjects];
    noCommentsView.hidden = NO;
}

- (void)repositionComments
{    
    CGFloat y = 0;
    NSUInteger i = 0;
    for (BuzzCommentView *commentView in commentViews) {
        CGRect frame = commentView.frame;
        frame.origin.y = y;

        if (showsActionButtons || i > 0) {
            frame.size.width = scrollView.bounds.size.width - actionButtonsView.bounds.size.width;
            frame.size.height = 1000;    // Limit height arbitrarily to 1000 points
        } else {
            frame.size.width = scrollView.bounds.size.width;
            frame.size.height = scrollView.bounds.size.height;
        }
        
        commentView.frame = frame;
        [commentView sizeToFit];
        
        y += commentView.bounds.size.height;
        i++;        
    }
    
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, y);
    touchArea.frame = CGRectMake(0, 0, scrollView.contentSize.width, MAX(scrollView.contentSize.height, scrollView.frame.size.height));
}

- (void)setShowsActionButtons:(BOOL)isShowsActionButtons
{
    if (showsActionButtons != isShowsActionButtons) {
        showsActionButtons = isShowsActionButtons;
        actionButtonsView.alpha = (showsActionButtons && [commentViews count] ? 1.0f : 0.0f);
        scrollView.scrollEnabled = showsActionButtons && [commentViews count];
        if (!showsActionButtons) {
            scrollView.contentOffset = CGPointZero;
        }
        [self repositionComments];
    }
}

@end
