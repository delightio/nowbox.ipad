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
@synthesize mentionsScrollView;
@synthesize touchArea;
@synthesize noCommentsView;
@synthesize noCommentsLabel;
@synthesize showsActionButtons;
@synthesize delegate;

- (void)setup
{    
    [[NSBundle mainBundle] loadNibNamed:@"BuzzView" owner:self options:nil];
    contentView.frame = self.bounds;
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:contentView];
    
    commentScrollViews = [[NSMutableArray alloc] init];
    commentViews = [[NSMutableArray alloc] init];  
    actionButtonViews = [[NSMutableArray alloc] init];
    
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
    [commentScrollViews release];
    [commentViews release];
    [mentionsScrollView release];
    [touchArea release];
    [noCommentsView release];
    [noCommentsLabel release];
    [actionButtonViews release];
    
    [super dealloc];
}

- (IBAction)touchAreaPressed:(id)sender
{
    if ([delegate respondsToSelector:@selector(buzzViewDidTap:)]) {
        [delegate buzzViewDidTap:self];
    }
}

- (IBAction)likeButtonPressed:(id)sender
{
    if ([delegate respondsToSelector:@selector(buzzView:didPressLikeButton:)]) {
        [delegate buzzView:self didPressLikeButton:sender];
    }
}

- (IBAction)commentButtonPressed:(id)sender
{
    if ([delegate respondsToSelector:@selector(buzzView:didPressCommentButton:)]) {
        [delegate buzzView:self didPressCommentButton:sender];
    }    
}

- (void)addMention
{
    noCommentsView.hidden = YES;
    [commentViews removeAllObjects];
    
    // Create the comments scroll view
    UIScrollView *commentScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake([commentScrollViews count] * mentionsScrollView.bounds.size.width,
                                                                                     0,
                                                                                     mentionsScrollView.bounds.size.width,
                                                                                     mentionsScrollView.bounds.size.height)];
    commentScrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    commentScrollView.tag = [commentScrollViews count];
    [mentionsScrollView insertSubview:commentScrollView belowSubview:touchArea];
    [commentScrollViews addObject:commentScrollView];
    [commentScrollView release];
    
    // Create the action buttons
    UIButton *likeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIButton *commentButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [likeButton setImage:[UIImage imageNamed:@"phone_button_like.png"] forState:UIControlStateNormal];
    [commentButton setImage:[UIImage imageNamed:@"phone_button_comment.png"] forState:UIControlStateNormal];
    likeButton.frame = CGRectMake(commentScrollView.frame.origin.x + 244, 4, 50, 50);
    commentButton.frame = CGRectMake(commentScrollView.frame.origin.x + 244, 52, 50, 50);
    likeButton.tag = commentScrollView.tag;
    commentButton.tag = commentScrollView.tag;
    likeButton.alpha = 0;
    commentButton.alpha = 0;
    [likeButton addTarget:self action:@selector(likeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [commentButton addTarget:self action:@selector(commentButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [mentionsScrollView addSubview:likeButton];
    [mentionsScrollView addSubview:commentButton];
    [actionButtonViews addObject:likeButton];
    [actionButtonViews addObject:commentButton];
    
    mentionsScrollView.contentSize = CGSizeMake(CGRectGetMaxX(commentScrollView.frame), mentionsScrollView.bounds.size.height);
    touchArea.frame = CGRectMake(0, 0, mentionsScrollView.contentSize.width, mentionsScrollView.contentSize.height);
}

- (BuzzCommentView *)addCommentWithText:(NSString *)text username:(NSString *)username
{    
    BuzzCommentView *commentView = [[[BuzzCommentView alloc] initWithFrame:mentionsScrollView.bounds] autorelease];
    commentView.commentLabel.text = text;
    commentView.userLabel.text = username;
    
    if ([commentViews count] > 0) {
        [commentView sizeToFit];
    }
    
    [[commentScrollViews lastObject] insertSubview:commentView belowSubview:touchArea];
    [commentViews addObject:commentView];
    [self repositionComments];
    
    return commentView;
}

- (void)removeAllMentions
{
    for (UIScrollView *scrollView in commentScrollViews) {
        [scrollView removeFromSuperview];
    }
    
    for (UIView *view in actionButtonViews) {
        [view removeFromSuperview];
    }
    
    [commentScrollViews removeAllObjects];
    [commentViews removeAllObjects];
    [actionButtonViews removeAllObjects];
    noCommentsView.hidden = NO;
    
    mentionsScrollView.contentSize = mentionsScrollView.bounds.size;
    mentionsScrollView.contentOffset = CGPointZero;
    touchArea.frame = CGRectMake(0, 0, mentionsScrollView.contentSize.width, mentionsScrollView.contentSize.height);    
}

- (void)repositionComments
{    
    for (UIScrollView *commentScrollView in commentScrollViews) {
        CGFloat y = 0;
        NSUInteger i = 0;

        for (UIView *view in commentScrollView.subviews) {
            if ([view isKindOfClass:[BuzzCommentView class]]) {
                BuzzCommentView *commentView = (BuzzCommentView *)view;
                CGRect frame = commentView.frame;
                frame.origin.y = y;

                if (showsActionButtons || i > 0) {
                    frame.size.width = commentScrollView.bounds.size.width - 55;
                    frame.size.height = 1000;    // Limit height arbitrarily to 1000 points
                } else {
                    frame.size.width = commentScrollView.bounds.size.width;
                    frame.size.height = commentScrollView.bounds.size.height;
                }
                
                commentView.frame = frame;
                
                if (showsActionButtons || i > 0) {
                    [commentView sizeToFit];
                }
                
                y += commentView.bounds.size.height;
                i++;
            }
        }
        
        commentScrollView.contentSize = CGSizeMake(commentScrollView.bounds.size.width, y);
    }    
}

- (void)setShowsActionButtons:(BOOL)isShowsActionButtons
{
    if (showsActionButtons != isShowsActionButtons) {
        showsActionButtons = isShowsActionButtons;
        
        for (UIView *view in actionButtonViews) {
            view.alpha = (showsActionButtons && [commentViews count] ? 1.0f : 0.0f);
        }

        for (UIScrollView *scrollView in commentScrollViews) {
            if (!showsActionButtons) {
                scrollView.contentOffset = CGPointZero;
                scrollView.scrollEnabled = NO;
            } else {
                scrollView.scrollEnabled = YES;
            }
        }
        
        [self repositionComments];
    }
}

@end
