//
//  BuzzView.m
//  ipad
//
//  Created by Chris Haugli on 2/23/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "BuzzView.h"

@implementation BuzzView

@synthesize commentView;
@synthesize delegate;

- (void)setup
{    
    self.clipsToBounds = YES;
    commentViews = [[NSMutableArray alloc] init];  
    
    // Create a stretchable image for the buzz background
    backgroundImage = [[UIImageView alloc] initWithFrame:self.bounds];
    if ([backgroundImage respondsToSelector:@selector(resizableImageWithCapInsets:)]) {
        backgroundImage.image = [[UIImage imageNamed:@"phone_video_buzz_background.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(16, 6, 6, 6)];
    } else {
        backgroundImage.image = [[UIImage imageNamed:@"phone_video_buzz_background.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:16];
    }
    backgroundImage.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self insertSubview:backgroundImage atIndex:0];
    
    // Create a scroll view for scrolling through comments
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 16, self.bounds.size.width, self.bounds.size.height - 22)];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self insertSubview:scrollView aboveSubview:backgroundImage];
    
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
    [backgroundImage release];
    [commentViews release];
    [commentView release];
    [scrollView release];
    
    [super dealloc];
}

- (void)touchAreaPressed:(id)sender
{
    if ([delegate respondsToSelector:@selector(buzzViewDidTap:)]) {
        [delegate buzzViewDidTap:self];
    }
}

- (void)addComment:(NSString *)comment fromUser:(NSString *)user withImage:(UIImage *)userImage
{
    // Load the comment view from a nib
    [[NSBundle mainBundle] loadNibNamed:@"BuzzCommentView" owner:self options:nil];
    CGFloat y = 0;
    if ([commentViews count]) {
        y = CGRectGetMaxY([[commentViews lastObject] frame]);
    }
    commentView.frame = CGRectMake(0, y, self.frame.size.width, commentView.frame.size.height);
    commentView.backgroundColor = [UIColor clearColor];
    [commentViews addObject:commentView];
    [scrollView insertSubview:commentView belowSubview:touchArea];
    
    // Configure the comment view
    UIImageView *userImageView = (UIImageView *) [commentView viewWithTag:1];
    UILabel *userLabel = (UILabel *) [commentView viewWithTag:2];
    UIImageView *serviceIcon = (UIImageView *) [commentView viewWithTag:3];
    UILabel *timeLabel = (UILabel *) [commentView viewWithTag:4];
    UILabel *commentLabel = (UILabel *) [commentView viewWithTag:5];
    
    userImageView.image = userImage;
    userLabel.text = user;
    commentLabel.text = comment;
    
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
    
    // Release the loaded view
    self.commentView = nil;
}

- (void)removeAllComments
{
    for (UIView *view in commentViews) {
        [view removeFromSuperview];
    }
    [commentViews removeAllObjects];
}

@end
