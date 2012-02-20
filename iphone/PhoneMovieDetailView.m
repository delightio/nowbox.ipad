//
//  PhoneMovieDetailView.m
//  ipad
//
//  Created by Chris Haugli on 2/13/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "PhoneMovieDetailView.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark - PhoneMovieDetailView

@implementation PhoneMovieDetailView

@synthesize portraitView;
@synthesize landscapeView;
@synthesize controlsView;
@synthesize infoPanelExpanded;
@synthesize delegate;

- (void)awakeFromNib
{
    [super awakeFromNib];
        
    [self addSubview:portraitView];
    currentOrientedView = portraitView;
    
    [[NSBundle mainBundle] loadNibNamed:@"VideoControlView" owner:self options:nil];
    controlsView.frame = CGRectMake(20, landscapeView.frame.size.height - controlsView.frame.size.height, controlsView.frame.size.width, controlsView.frame.size.height);
    [landscapeView addSubview:controlsView];
}

- (void)dealloc
{
    [portraitView release];
    [landscapeView release];
    [controlsView release];
    
    [super dealloc];
}

- (void)setVideo:(NMVideo *)video {
    [super setVideo:video];
    
    [self setChannelTitle:video.channel.title];
    [self setChannelThumbnailForChannel:video.channel];
    [self setVideoTitle:video.video.title];
    [self setDescriptionText:video.video.detail.nm_description];
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

- (void)setInfoPanelExpanded:(BOOL)expanded
{
    [self setInfoPanelExpanded:expanded animated:NO];
}

- (void)setInfoPanelExpanded:(BOOL)expanded animated:(BOOL)animated
{
    infoPanelExpanded = expanded;
    [portraitView setInfoPanelExpanded:expanded animated:animated];
    [landscapeView setInfoPanelExpanded:expanded animated:animated];
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
    [currentOrientedView positionLabels];
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

- (IBAction)playButtonPressed:(id)sender
{
    if ([delegate respondsToSelector:@selector(videoInfoViewDidTapPlayButton:)]) {
        [delegate videoInfoViewDidTapPlayButton:self];
    }
}

- (IBAction)seekBarValueChanged:(id)sender
{
    [controlsView updateSeekBubbleLocation];
    
    if ([delegate respondsToSelector:@selector(videoInfoView:didSeek:)]) {
        [delegate videoInfoView:self didSeek:sender];
    }
}

- (IBAction)seekBarTouchDown:(id)sender
{
	controlsView.isSeeking = YES;
	[controlsView updateSeekBubbleLocation];
    
    if ([delegate respondsToSelector:@selector(videoInfoView:didTouchDownSeekBar:)]) {
        [delegate videoInfoView:self didTouchDownSeekBar:sender];
    }
}

- (IBAction)seekBarTouchUp:(id)sender
{
    controlsView.isSeeking = NO;
    [UIView animateWithDuration:0.25 animations:^{
		controlsView.seekBubbleButton.alpha = 0.0f;
    }];
    
    if ([delegate respondsToSelector:@selector(videoInfoView:didTouchUpSeekBar:)]) {
        [delegate videoInfoView:self didTouchUpSeekBar:sender];
    }
}

- (IBAction)toggleInfoPanel:(id)sender
{
    [self setInfoPanelExpanded:!infoPanelExpanded animated:YES];
    if ([delegate respondsToSelector:@selector(videoInfoView:didToggleInfoPanelExpanded:)]) {
        [delegate videoInfoView:self didToggleInfoPanelExpanded:infoPanelExpanded];
    }
}

@end

#pragma mark - PhoneVideoInfoOrientedView

@implementation PhoneVideoInfoOrientedView

@synthesize topView;
@synthesize bottomView;
@synthesize infoView;
@synthesize channelThumbnail;
@synthesize infoButtonScrollView;
@synthesize channelTitleLabel;
@synthesize videoTitleLabel;
@synthesize descriptionLabel;
@synthesize infoPanelExpanded;

- (void)awakeFromNib
{
    UIView *viewToMask = infoButtonScrollView.superview;
    
    // Fade out info buttons
    CAGradientLayer *mask = [CAGradientLayer layer];
    mask.frame = CGRectMake(0, 0, viewToMask.bounds.size.width, viewToMask.bounds.size.height * 2);
    mask.colors = [NSArray arrayWithObjects:
                   (id)[UIColor whiteColor].CGColor,
                   (id)[UIColor whiteColor].CGColor,                       
                   (id)[UIColor clearColor].CGColor, nil];
    mask.startPoint = CGPointMake(0.5, 0);
    mask.endPoint = CGPointMake(0.5, 1);
    mask.locations = [NSArray arrayWithObjects:
                      [NSNumber numberWithFloat:0],
                      [NSNumber numberWithFloat:0.25],
                      [NSNumber numberWithFloat:0.375], nil];
    viewToMask.layer.mask = mask; 
    
    originalVideoTitleFrame = videoTitleLabel.frame;
}

- (void)dealloc
{
    [topView release];
    [bottomView release];
    [infoView release];
    [channelThumbnail release];
    [infoButtonScrollView release];
    [channelTitleLabel release];
    [videoTitleLabel release];
    [descriptionLabel release];
    
    [super dealloc];
}

- (void)positionLabels
{
    // Position the description label below the video title
    videoTitleLabel.frame = originalVideoTitleFrame;
    [videoTitleLabel sizeToFit];
    CGRect frame = videoTitleLabel.frame;
    frame.size.height = MIN(frame.size.height, originalVideoTitleFrame.size.height);
    videoTitleLabel.frame = frame;
    
    frame = descriptionLabel.frame;
    CGFloat distanceFromBottom = CGRectGetHeight(infoView.frame) - CGRectGetMaxY(frame);
    frame.origin.y = CGRectGetMaxY(videoTitleLabel.frame) + 5;
    frame.size.height = infoView.frame.size.height - frame.origin.y - distanceFromBottom;
    descriptionLabel.frame = frame;
    descriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)setInfoPanelExpanded:(BOOL)expanded
{
    [self setInfoPanelExpanded:expanded animated:NO];
}

- (void)setInfoPanelExpanded:(BOOL)expanded animated:(BOOL)animated
{    
    infoPanelExpanded = expanded;
    
    CGRect frame = infoView.frame;
    BOOL landscape = (infoView == bottomView);
    
    if (landscape) {
        // Landscape - resize view keeping the bottom position the same
        frame.size.height = (expanded ? 160 : 120);
        frame.origin.y = CGRectGetMaxY(infoView.frame) - frame.size.height;
    } else {
        // Portrait - resize view keeping the top position the same
        frame.size.height = (expanded ? 200 : 116);
    }
    
    if (expanded) {
        infoButtonScrollView.scrollEnabled = NO;
                
        // We don't want buttons flying down from the top, looks bad. Reposition buttons to avoid it.
        for (UIView *view in infoButtonScrollView.subviews) {
            if (view.center.y < infoButtonScrollView.contentOffset.y) {
                view.center = CGPointMake(view.center.x, view.center.y + [infoButtonScrollView.subviews count] * infoButtonScrollView.frame.size.height);
            }
        }
    } else {
        infoButtonScrollView.scrollEnabled = YES;
    }
    
    // We don't want the button alpha mask when the panel is expanded
    CAGradientLayer *mask = (CAGradientLayer *) infoButtonScrollView.superview.layer.mask;
    if (animated) {
        [CATransaction begin];
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [CATransaction setValue:[NSNumber numberWithDouble:0.3] forKey:kCATransactionAnimationDuration];
    }
    if (expanded) {
        mask.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0],
                          [NSNumber numberWithFloat:1.0],
                          [NSNumber numberWithFloat:1.0], nil];
    } else {
        mask.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0],
                          [NSNumber numberWithFloat:0.25],
                          [NSNumber numberWithFloat:0.375], nil];
    }
    if (animated) {
        [CATransaction commit];
    }
    
    // Resize the panel
    if (animated) {
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             infoView.frame = frame;
                         }
                         completion:^(BOOL finished){
                         }];
    } else {
        infoView.frame = frame;
    }
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
