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
- (void)addNoCommentsViewWithIndex:(NSUInteger)index;
- (UIView *)noCommentsViewWithFrame:(CGRect)frame socialMentionIndex:(NSUInteger)index;
@end

@implementation BuzzView

@synthesize contentView;
@synthesize mentionsScrollView;
@synthesize showsActionButtons;
@synthesize delegate;

- (UIView *)noCommentsViewWithFrame:(CGRect)frame socialMentionIndex:(NSUInteger)index
{
    UIView *noCommentsView = [[[UIView alloc] initWithFrame:frame] autorelease];
    noCommentsView.backgroundColor = [UIColor clearColor];
    noCommentsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UILabel *noCommentsLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 16, noCommentsView.bounds.size.width - 30, 40)];
    noCommentsLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    noCommentsLabel.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:16.0f backupFontName:@"Futura-Medium" size:14.0f];
    noCommentsLabel.text = @"It's quiet here. Be the first to add a comment.";
    noCommentsLabel.textColor = [UIColor whiteColor];
    noCommentsLabel.backgroundColor = [UIColor clearColor];
    noCommentsLabel.alpha = 0.74;
    [noCommentsView addSubview:noCommentsLabel];
    [noCommentsLabel release];
    
    UIButton *addCommentButton = [UIButton buttonWithType:UIButtonTypeCustom];
    addCommentButton.frame = CGRectMake(noCommentsView.bounds.size.width - 55, 11, 50, 50);
    addCommentButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    addCommentButton.tag = index;
    [addCommentButton setImage:[UIImage imageNamed:@"phone_button_add_comment.png"] forState:UIControlStateNormal];
    [addCommentButton addTarget:self action:@selector(commentButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [noCommentsView addSubview:addCommentButton];
    
    return noCommentsView;
}

- (void)setup
{    
    [[NSBundle mainBundle] loadNibNamed:@"BuzzView" owner:self options:nil];
    contentView.frame = self.bounds;
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:contentView];
    
    commentScrollViews = [[NSMutableArray alloc] init];
    commentViews = [[NSMutableArray alloc] init];  
    noCommentViews = [[NSMutableArray alloc] init];
    actionButtonViews = [[NSMutableArray alloc] init];
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
    [noCommentViews release];
    [mentionsScrollView release];
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

- (void)addNoCommentsViewWithIndex:(NSUInteger)index
{
    UIView *noCommentsView = [self noCommentsViewWithFrame:CGRectMake(mentionsScrollView.contentSize.width - mentionsScrollView.bounds.size.width, 0,
                                                                      mentionsScrollView.bounds.size.width, mentionsScrollView.bounds.size.height)
                                        socialMentionIndex:index];
    [mentionsScrollView insertSubview:noCommentsView atIndex:0];
    [noCommentViews addObject:noCommentsView];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapView:)];
    [tapGestureRecognizer setNumberOfTapsRequired:1];
    [noCommentsView addGestureRecognizer:tapGestureRecognizer];
    [tapGestureRecognizer release];
}

- (void)addMentionLiked:(BOOL)liked
{
    currentMentionIsLiked = liked;
    
    // Did last mention have no comments? If so, add a "no comments" view
    if ([commentScrollViews count] > 0 && [commentViews count] == 0) {
        [self addNoCommentsViewWithIndex:[commentScrollViews count] - 1];
    }
    [commentViews removeAllObjects];
    
    // Create the comments scroll view
    UIScrollView *commentScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake([commentScrollViews count] * mentionsScrollView.bounds.size.width,
                                                                                     0,
                                                                                     mentionsScrollView.bounds.size.width,
                                                                                     mentionsScrollView.bounds.size.height)];
    commentScrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    commentScrollView.tag = [commentScrollViews count];
    commentScrollView.scrollEnabled = NO;
    commentScrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    [mentionsScrollView insertSubview:commentScrollView atIndex:0];
    [commentScrollViews addObject:commentScrollView];
    [commentScrollView release];

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapView:)];
    [tapGestureRecognizer setNumberOfTapsRequired:1];
    [commentScrollView addGestureRecognizer:tapGestureRecognizer];
    [tapGestureRecognizer release];
    
    mentionsScrollView.contentSize = CGSizeMake(CGRectGetMaxX(commentScrollView.frame), mentionsScrollView.bounds.size.height);   
}

- (BuzzCommentView *)addCommentWithText:(NSString *)text username:(NSString *)username
{    
    BuzzCommentView *commentView = [[[BuzzCommentView alloc] initWithFrame:mentionsScrollView.bounds] autorelease];
    commentView.commentLabel.text = text;
    commentView.userLabel.text = username;

    UIScrollView *commentScrollView = [commentScrollViews lastObject];
    
    if ([commentViews count] > 0) {
        [commentView setShowsLikesCount:NO];
        [commentView sizeToFit];
    } else {
        // This is the first comment
        [commentView setShowsLikesCount:YES];

        // Create the action buttons
        UIButton *likeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        likeButton.frame = CGRectMake(commentScrollView.frame.origin.x + 244, 4, 50, 50);
        likeButton.tag = commentScrollView.tag;
        likeButton.alpha = 0;
        if (currentMentionIsLiked) {
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
    }
    
    [commentScrollView addSubview:commentView];
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
    
    for (UIView *view in noCommentViews) {
        [view removeFromSuperview];
    }
    
    [commentScrollViews removeAllObjects];
    [commentViews removeAllObjects];
    [noCommentViews removeAllObjects];
    [actionButtonViews removeAllObjects];
    
    mentionsScrollView.contentSize = mentionsScrollView.bounds.size;
    mentionsScrollView.contentOffset = CGPointZero;
}

- (void)doneAdding
{
    // Did last mention have no comments? If so, add a "no comments" view
    if (commentViews && [commentViews count] == 0) {
        [self addNoCommentsViewWithIndex:[commentScrollViews count] - 1];
    }
    
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
        view.alpha = (showsActionButtons ? 1.0f : 0.0f);
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
