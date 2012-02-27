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

@interface PhoneMovieDetailView (PrivatMethods)
- (void)updateControlsViewForCurrentOrientation;
@end

@implementation PhoneMovieDetailView

@synthesize portraitView;
@synthesize landscapeView;
@synthesize controlsView;
@synthesize infoPanelExpanded;
@synthesize buzzPanelExpanded;
@synthesize videoOverlayHidden;
@synthesize delegate;

- (void)awakeFromNib
{
    [super awakeFromNib];
            
    [self addSubview:portraitView];
    currentOrientedView = portraitView;
    
    [[NSBundle mainBundle] loadNibNamed:@"VideoControlView" owner:self options:nil];
    [self updateControlsViewForCurrentOrientation];
    [currentOrientedView addSubview:controlsView];
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
    
    // Add buzz
    [portraitView.buzzView removeAllComments];
    for (NMSocialInfo *facebookInfo in video.video.socialMentions) {
        NSArray *sortedComments = [facebookInfo.comments sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"created_time" ascending:YES]]];
        for (NMSocialComment *comment in sortedComments) {
            [portraitView.buzzView addComment:comment.message fromUser:comment.fromPerson.name withImage:nil atTime:[comment relativeTimeString]];
        }
    }
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

- (void)setMoreCount:(NSUInteger)moreCount
{
    NSString *moreString = [NSString stringWithFormat:@"%i more", moreCount];
    [portraitView.moreVideosButton setTitle:moreString forState:UIControlStateNormal];
    [landscapeView.moreVideosButton setTitle:moreString forState:UIControlStateNormal];
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

- (void)setBuzzPanelExpanded:(BOOL)expanded
{
    [self setBuzzPanelExpanded:expanded animated:NO];
}

- (void)setBuzzPanelExpanded:(BOOL)expanded animated:(BOOL)animated
{
    buzzPanelExpanded = expanded;
    [portraitView setBuzzPanelExpanded:expanded animated:animated];
}

- (void)setVideoOverlayHidden:(BOOL)isVideoOverlayHidden
{
    [self setVideoOverlayHidden:isVideoOverlayHidden animated:NO];
}

- (void)setVideoOverlayHidden:(BOOL)hidden animated:(BOOL)animated
{
    videoOverlayHidden = hidden;
    
    void (^toggleVideoOverlay)(void) = ^{
        landscapeView.topView.alpha = (hidden ? 0.0f : 1.0f);
        landscapeView.bottomView.alpha = (hidden ? 0.0f : 1.0f);
        controlsView.alpha = (hidden ? 0.0f : 1.0f);
    };
    
    if (animated) {
        [UIView animateWithDuration:0.3f
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut
                         animations:toggleVideoOverlay
                         completion:^(BOOL finished){ 
                         }];
    } else {
        toggleVideoOverlay();
    }
}

- (void)updateControlsViewForCurrentOrientation
{
    if (currentOrientedView == portraitView) {
        controlsView.frame = CGRectMake(-8,
                                        portraitView.bottomView.frame.origin.y - controlsView.frame.size.height,
                                        portraitView.frame.size.width + 8,
                                        controlsView.frame.size.height);
        controlsView.backgroundView.hidden = NO;
    } else {
        controlsView.frame = CGRectMake(landscapeView.descriptionLabelContainer.frame.origin.x - 13, 
                                        landscapeView.frame.size.height - controlsView.frame.size.height - 3, 
                                        landscapeView.descriptionLabelContainer.frame.size.width + 26, 
                                        controlsView.frame.size.height);
        controlsView.backgroundView.hidden = YES;        
    }
}

- (void)updateViewForInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    [currentOrientedView removeFromSuperview];
    [controlsView removeFromSuperview];
    
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        currentOrientedView = portraitView;
    } else {
        currentOrientedView = landscapeView;
    }

    [self updateControlsViewForCurrentOrientation];
    [currentOrientedView addSubview:controlsView];
    currentOrientedView.frame = self.bounds;
    [self addSubview:currentOrientedView];
    [currentOrientedView positionLabels];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{    
    if (thumbnailContainerView.alpha == 1.0f) {
        return [super pointInside:point withEvent:event];
    }
    
    if (videoOverlayHidden && currentOrientedView == landscapeView) {
        return NO;
    }
        
    return ((!currentOrientedView.topView.hidden && CGRectContainsPoint(currentOrientedView.topView.frame, point)) ||
            (!currentOrientedView.bottomView.hidden && CGRectContainsPoint(currentOrientedView.bottomView.frame, point)) ||
            (!videoOverlayHidden && CGRectContainsPoint(controlsView.frame, point)));
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

- (IBAction)thumbnailPressed:(id)sender
{
    if ([delegate respondsToSelector:@selector(videoInfoViewDidTapThumbnail:)]) {
        [delegate videoInfoViewDidTapThumbnail:self];
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

- (IBAction)toggleBuzzPanel:(id)sender
{
    [self setBuzzPanelExpanded:!buzzPanelExpanded animated:YES];
    if ([delegate respondsToSelector:@selector(videoInfoView:didToggleBuzzPanelExpanded:)]) {
        [delegate videoInfoView:self didToggleBuzzPanelExpanded:buzzPanelExpanded];
    }    
}

#pragma mark - PhoneVideoInfoOrientedViewDelegate

- (void)phoneVideoInfoOrientedView:(PhoneVideoInfoOrientedView *)view willBeginDraggingWithScrollView:(UIScrollView *)scrollView
{
    if ([delegate respondsToSelector:@selector(videoInfoView:willBeginDraggingScrollView:)]) {
        [delegate videoInfoView:self willBeginDraggingScrollView:scrollView];
    }
}

- (void)phoneVideoInfoOrientedView:(PhoneVideoInfoOrientedView *)view didEndDraggingWithScrollView:(UIScrollView *)scrollView
{
    if ([delegate respondsToSelector:@selector(videoInfoView:didEndDraggingScrollView:)]) {
        [delegate videoInfoView:self didEndDraggingScrollView:scrollView];
    }    
}

#pragma mark - BuzzViewDelegate

- (void)buzzViewDidTap:(BuzzView *)buzzView
{
    [self toggleBuzzPanel:buzzView];
}

@end
