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
- (UIView *)loadCommentViewFromNib:(NSString *)nibName;
@end

@implementation BuzzView

@synthesize loadedCommentView;
@synthesize delegate;

- (void)setup
{    
    self.clipsToBounds = YES;
    commentViews = [[NSMutableArray alloc] init];  
    
    // Create a scroll view for scrolling through comments
    scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:scrollView];
    
    touchArea = [UIButton buttonWithType:UIButtonTypeCustom];
    touchArea.frame = scrollView.bounds;
    touchArea.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [touchArea addTarget:self action:@selector(touchAreaPressed:) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:touchArea];
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
    [commentViews release];
    [loadedCommentView release];
    [scrollView release];
    
    [super dealloc];
}

- (void)touchAreaPressed:(id)sender
{
    if ([delegate respondsToSelector:@selector(buzzViewDidTap:)]) {
        [delegate buzzViewDidTap:self];
    }
}

- (UIView *)loadCommentViewFromNib:(NSString *)nibName
{
    [[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil];
    CGFloat y = 0;
    if ([commentViews count]) {
        y = CGRectGetMaxY([[commentViews lastObject] frame]);
    }
    loadedCommentView.frame = CGRectMake(0, y, self.frame.size.width, loadedCommentView.frame.size.height);
    loadedCommentView.backgroundColor = [UIColor clearColor];

    UIView *theView = [[loadedCommentView retain] autorelease];
    self.loadedCommentView = nil;
    
    return theView;
}

- (void)addComment:(NSString *)comment fromUser:(NSString *)user withImage:(UIImage *)userImage atTime:(NSString *)timeText
{
    UIView *commentView = [self loadCommentViewFromNib:@"BuzzCommentView"];
    [commentViews addObject:commentView];
    [scrollView insertSubview:commentView belowSubview:touchArea];
    
    // Configure the comment view
    UIImageView *userImageView = (UIImageView *) [commentView viewWithTag:1];
    UILabel *userLabel = (UILabel *) [commentView viewWithTag:2];
    UIImageView *serviceIcon = (UIImageView *) [commentView viewWithTag:3];
    UILabel *timeLabel = (UILabel *) [commentView viewWithTag:4];
    UILabel *commentLabel = (UILabel *) [commentView viewWithTag:5];
    
    UIFont *labelFont = [UIFont fontWithName:@"Futura-CondensedMedium" size:14.0f backupFontName:@"Futura-Medium" size:12.0f];
    userLabel.font = labelFont;
    timeLabel.font = labelFont;
    commentLabel.font = labelFont;
    
    userImageView.image = userImage;
    userLabel.text = user;
    commentLabel.text = comment;
    timeLabel.text = timeText;
    
    // Position views based on how much text there is in labels
    [userLabel sizeToFit];
    CGRect frame = serviceIcon.frame;
    frame.origin.x = CGRectGetMaxX(userLabel.frame) + 5;
    serviceIcon.frame = frame;
    
    frame = timeLabel.frame;
    frame.origin.x = CGRectGetMaxX(serviceIcon.frame) + 5;
    timeLabel.frame = frame;
    
    [commentLabel sizeToFit];
    frame = commentView.frame;
    frame.size.height = CGRectGetMaxY(commentLabel.frame) + userLabel.frame.origin.y;
    commentView.frame = frame;
    
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width, CGRectGetMaxY(commentView.frame));
    touchArea.frame = CGRectMake(0, 0, scrollView.contentSize.width, scrollView.contentSize.height);
}

- (void)removeAllComments
{
    for (UIView *view in commentViews) {
        [view removeFromSuperview];
    }
    [commentViews removeAllObjects];
}

@end
