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
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapView:)];
    [tapGestureRecognizer setNumberOfTapsRequired:1];
    [self addGestureRecognizer:tapGestureRecognizer];
    [tapGestureRecognizer release];
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
    [noCommentsView release];
    [noCommentsLabel release];
    [actionButtonViews release];
    
    [super dealloc];
}

- (IBAction)didTapView:(id)sender
{
    if ([delegate respondsToSelector:@selector(buzzViewDidTap:)]) {
        [delegate buzzViewDidTap:self];
    }
}

- (IBAction)likeButtonPressed:(id)sender
{
    [sender setImage:[UIImage imageNamed:@"phone_button_like_active.png"] forState:UIControlStateNormal];
    [sender removeTarget:self action:@selector(likeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [sender addTarget:self action:@selector(unlikeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([delegate respondsToSelector:@selector(buzzView:didPressLikeButton:)]) {
        [delegate buzzView:self didPressLikeButton:sender];
    }
}

- (IBAction)unlikeButtonPressed:(id)sender
{    
    [sender setImage:[UIImage imageNamed:@"phone_button_like.png"] forState:UIControlStateNormal];
    [sender removeTarget:self action:@selector(unlikeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [sender addTarget:self action:@selector(likeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    if ([delegate respondsToSelector:@selector(buzzView:didPressUnlikeButton:)]) {
        [delegate buzzView:self didPressUnlikeButton:sender];
    }
}

- (IBAction)commentButtonPressed:(id)sender
{
    if ([delegate respondsToSelector:@selector(buzzView:didPressCommentButton:)]) {
        [delegate buzzView:self didPressCommentButton:sender];
    }    
}

- (void)addMentionLiked:(BOOL)liked
{
    [commentViews removeAllObjects];
    
    // Create the comments scroll view
    UIScrollView *commentScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake([commentScrollViews count] * mentionsScrollView.bounds.size.width,
                                                                                     0,
                                                                                     mentionsScrollView.bounds.size.width,
                                                                                     mentionsScrollView.bounds.size.height)];
    commentScrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    commentScrollView.tag = [commentScrollViews count];
    commentScrollView.scrollEnabled = NO;
    [mentionsScrollView addSubview:commentScrollView];
    [commentScrollViews addObject:commentScrollView];
    [commentScrollView release];
    
    // Create the action buttons
    UIButton *likeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    likeButton.frame = CGRectMake(commentScrollView.frame.origin.x + 244, 4, 50, 50);
    likeButton.tag = commentScrollView.tag;
    likeButton.alpha = 0;
    if (liked) {
        [likeButton setImage:[UIImage imageNamed:@"phone_button_like_active.png"] forState:UIControlStateNormal];
        [likeButton addTarget:self action:@selector(unlikeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [likeButton setImage:[UIImage imageNamed:@"phone_button_like.png"] forState:UIControlStateNormal];
        [likeButton addTarget:self action:@selector(likeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    [mentionsScrollView addSubview:likeButton];
    [actionButtonViews addObject:likeButton];
    
    UIButton *commentButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [commentButton setImage:[UIImage imageNamed:@"phone_button_comment.png"] forState:UIControlStateNormal];
    commentButton.frame = CGRectMake(commentScrollView.frame.origin.x + 244, 52, 50, 50);
    commentButton.tag = commentScrollView.tag;
    commentButton.alpha = 0;
    [commentButton addTarget:self action:@selector(commentButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [mentionsScrollView addSubview:commentButton];
    [actionButtonViews addObject:commentButton];
    
    mentionsScrollView.contentSize = CGSizeMake(CGRectGetMaxX(commentScrollView.frame), mentionsScrollView.bounds.size.height);
}

- (BuzzCommentView *)addCommentWithText:(NSString *)text username:(NSString *)username
{    
    noCommentsView.hidden = YES;

    BuzzCommentView *commentView = [[[BuzzCommentView alloc] initWithFrame:mentionsScrollView.bounds] autorelease];
    commentView.commentLabel.text = text;
    commentView.userLabel.text = username;
    
    if ([commentViews count] > 0) {
        [commentView sizeToFit];
    }
    
    [[commentScrollViews lastObject] addSubview:commentView];
    [commentViews addObject:commentView];
    
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
}

- (void)doneAdding
{
    [self repositionComments];
    [self setShowsActionButtons:showsActionButtons];
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
                    frame.size.width = commentScrollView.bounds.size.width - 50;
                    frame.size.height = 1000;    // Limit height arbitrarily to 1000 points
                } else {
                    frame.size.width = commentScrollView.bounds.size.width;
                    frame.size.height = commentScrollView.bounds.size.height;
                }
                
                commentView.frame = frame;
                [commentView sizeToFit];        // Positions all the labels property and makes the comment view only as big as it needs to be

                if (!showsActionButtons && i == 0) {
                    // We only want to show the first comment if the buzz view is not expanded
                    commentView.frame = frame;
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
    showsActionButtons = isShowsActionButtons;
    
    for (UIView *view in actionButtonViews) {
        view.alpha = (showsActionButtons && [commentViews count] ? 1.0f : 0.0f);
    }

    for (UIScrollView *scrollView in commentScrollViews) {
        if (!showsActionButtons) {
            scrollView.contentOffset = CGPointZero;
        }
        scrollView.scrollEnabled = showsActionButtons;
    }
    
    [self repositionComments];
}

@end
