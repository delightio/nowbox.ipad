//
//  PhoneVideoInfoView.m
//  ipad
//
//  Created by Chris Haugli on 2/13/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "PhoneVideoInfoView.h"

#pragma mark - PhoneVideoInfoView

@implementation PhoneVideoInfoView

@synthesize portraitView;
@synthesize landscapeView;
@synthesize delegate;

- (void)setup
{
    self.backgroundColor = [UIColor clearColor];
    
    [[NSBundle mainBundle] loadNibNamed:@"PhoneVideoInfoView" owner:self options:nil];
    [self addSubview:portraitView];
    currentOrientedView = portraitView;
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
    [portraitView release];
    [landscapeView release];
    
    [super dealloc];
}

- (void)setChannelTitle:(NSString *)channelTitle
{
    [portraitView.channelTitleLabel setText:channelTitle];
    [landscapeView.channelTitleLabel setText:channelTitle];    
}

- (void)setVideoTitle:(NSString *)videoTitle
{
    [portraitView.videoTitleLabel setText:videoTitle];
    [landscapeView.videoTitleLabel setText:videoTitle];
    [portraitView positionLabels];
    [landscapeView positionLabels];
}

- (void)setDescriptionText:(NSString *)descriptionText
{
    [portraitView.descriptionLabel setText:descriptionText];
    [landscapeView.descriptionLabel setText:descriptionText];
}

- (void)setChannelThumbnailForChannel:(NMChannel *)channel
{
    [portraitView.channelThumbnail setImageForChannel:channel];
    [landscapeView.channelThumbnail setImageForChannel:channel];
}

- (void)updateViewForInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    [currentOrientedView removeFromSuperview];
    
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        currentOrientedView = portraitView;
    } else {
        currentOrientedView = landscapeView;
    }

    currentOrientedView.frame = self.bounds;
    [self addSubview:currentOrientedView];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{    
    return (CGRectContainsPoint(currentOrientedView.topView.frame, point) ||
            CGRectContainsPoint(currentOrientedView.bottomView.frame, point));
}

#pragma mark - IBActions

- (IBAction)gridButtonPressed:(id)sender
{
    if ([delegate respondsToSelector:@selector(videoInfoViewDidTapGridButton:)]) {
        [delegate videoInfoViewDidTapGridButton:self];
    }
}

- (IBAction)toggleInfoPanel:(id)sender
{
    [portraitView toggleInfoPanel];
    [landscapeView toggleInfoPanel];
}

@end

#pragma mark - PhoneVideoInfoOrientedView

@implementation PhoneVideoInfoOrientedView

@synthesize topView;
@synthesize bottomView;
@synthesize infoView;
@synthesize infoButtonScrollView;
@synthesize channelTitleLabel;
@synthesize videoTitleLabel;
@synthesize descriptionLabel;
@synthesize channelThumbnail;

- (void)dealloc
{
    [topView release];
    [bottomView release];
    [infoView release];
    [infoButtonScrollView release];
    [channelTitleLabel release];
    [videoTitleLabel release];
    [descriptionLabel release];
    [channelThumbnail release];
    
    [super dealloc];
}

- (void)positionLabels
{
    // Position the description label below the video title
    CGSize videoTitleSize = [videoTitleLabel.text sizeWithFont:videoTitleLabel.font 
                                             constrainedToSize:videoTitleLabel.frame.size
                                                 lineBreakMode:videoTitleLabel.lineBreakMode];
    CGRect frame = descriptionLabel.frame;
    CGFloat distanceFromBottom = CGRectGetHeight(infoView.frame) - CGRectGetMaxY(frame);
    frame.origin.y = videoTitleLabel.frame.origin.y + videoTitleSize.height;
    frame.size.height = infoView.frame.size.height - frame.origin.y - distanceFromBottom;
    descriptionLabel.frame = frame;
    descriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)toggleInfoPanel
{
    CGRect frame = infoView.frame;
    if (frame.size.height < 200) {
        frame.size.height = 200;
        infoButtonScrollView.scrollEnabled = NO;
                
        // We don't want buttons flying down from the top, looks bad. Reposition buttons to avoid it.
        NSInteger centerViewIndex = [infoButtonScrollView centerViewIndex];
        for (UIView *view in infoButtonScrollView.subviews) {
            if (view.tag < centerViewIndex && view.center.y - infoButtonScrollView.contentOffset.y > infoButtonScrollView.frame.size.height) {
                view.center = CGPointMake(view.center.x, view.center.y - [infoButtonScrollView.subviews count] * infoButtonScrollView.frame.size.height);
            } else if (view.tag > centerViewIndex && view.center.y - infoButtonScrollView.contentOffset.y < 0) {
                view.center = CGPointMake(view.center.x, view.center.y + [infoButtonScrollView.subviews count] * infoButtonScrollView.frame.size.height);
            }
        }
    } else {
        frame.size.height = 116;
        infoButtonScrollView.scrollEnabled = YES;
    }
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         infoView.frame = frame;
                         
                         if (!infoButtonScrollView.scrollEnabled) {
                             // Position the buttons in the scroll view, which is no longer scrollable
                             for (UIView *view in infoButtonScrollView.subviews) {
                                 CGRect buttonFrame = view.frame;
                                 buttonFrame.origin.y = infoButtonScrollView.contentOffset.y + view.tag * infoButtonScrollView.frame.size.height;
                                 view.frame = buttonFrame;
                             }
                         }
                     }
                     completion:^(BOOL finished){
                     }];
}

@end

#pragma mark - InfiniteScrollView

@implementation InfiniteScrollView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (self.superview) {
        CGPoint pointInSuperview = [self convertPoint:point toView:self.superview];
        return [self.superview pointInside:pointInSuperview withEvent:event];
    }
    
    return [super pointInside:point withEvent:event];
}

- (NSInteger)centerViewIndex
{
    for (UIView *view in self.subviews) {
        if (view.center.y > self.contentOffset.y &&
            view.center.y < self.contentOffset.y + self.frame.size.height) {
            return view.tag;
        }
    }
    return 0;
}

- (void)centerContentOffset
{
    // Which view is closest to the center?
    NSInteger centerViewIndex = [self centerViewIndex];
    
    // Make sure we don't get too close to the scroll limit
    self.contentOffset = CGPointMake(0, round((self.contentSize.height / 2) / self.frame.size.height) * self.frame.size.height);
    for (UIView *view in self.subviews) {
        CGRect frame = view.frame;
        frame.origin.y = self.contentOffset.y + (view.tag - centerViewIndex) * self.frame.size.height;
        view.frame = frame;
    }        
    
    [self scrollViewDidScroll:self];
}

- (void)awakeFromNib
{
    // "Infinite" scrolling
    self.delegate = self;
    self.contentSize = CGSizeMake(self.frame.size.width, 10000);
    [self centerContentOffset];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Do we need to loop any of the subviews to the top / bottom?
    for (UIView *view in scrollView.subviews) {
        CGFloat distance = view.center.y - (scrollView.contentOffset.y + scrollView.frame.size.height / 2);
        CGFloat newY = view.center.y + (distance > 0 ? -1.0f : 1.0f) * [scrollView.subviews count] * scrollView.frame.size.height;
        CGFloat newDistance = newY - (scrollView.contentOffset.y + scrollView.frame.size.height / 2);
        
        if (ABS(newDistance) < ABS(distance)) {
            view.center = CGPointMake(view.center.x, newY);
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self centerContentOffset];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self centerContentOffset];
    }
}

@end
