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

@interface PhoneMovieDetailView (PrivateMethods)
+ (UIImage *)serviceIconForChannelType:(NMChannelType)channelType;
+ (NSString *)relativeTimeStringForTime:(NSTimeInterval)time;
- (void)setChannelTitle:(NSString *)channelTitle;
- (void)setVideoTitle:(NSString *)videoTitle;
- (void)setDate:(NSDate *)date;
- (void)setDescriptionText:(NSString *)descriptionText;
- (void)setAuthor:(NMAuthor *)author;
- (void)setMoreCount:(NSUInteger)moreCount;
- (void)setTopActionButtonIndex:(NSUInteger)actionButtonIndex;
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

+ (UIImage *)serviceIconForChannelType:(NMChannelType)channelType
{
    switch (channelType) {
        case NMChannelUserFacebookType:
            return [UIImage imageNamed:@"phone_video_buzz_icon_facebook.png"];                    
        case NMChannelUserTwitterType:
            return [UIImage imageNamed:@"phone_video_buzz_icon_twitter.png"];                    
        default:
            return nil;
    }    
}

+ (NSString *)relativeTimeStringForTime:(NSTimeInterval)time
{
    NSTimeInterval ageInSeconds = [[NSDate date] timeIntervalSince1970] - time;
    
    if (ageInSeconds < 60) {
        return [NSString stringWithFormat:@"%i sec ago", (NSInteger)ageInSeconds];
    } else if (ageInSeconds < 60*60) {
        return [NSString stringWithFormat:@"%i min ago", (NSInteger)(ageInSeconds / 60)];
    } else if (ageInSeconds < 60*60*24) {
        NSInteger hours = (NSInteger)(ageInSeconds / (60*60));
        return [NSString stringWithFormat:@"%i %@ ago", hours, (hours == 1 ? @"hour" : @"hours")];
    } else if (ageInSeconds < 60*60*24*30) {
        NSInteger days = (NSInteger)(ageInSeconds / (60*60*24));
        if (days == 1) return @"Yesterday";
        return [NSString stringWithFormat:@"%i days ago", days];
    } else if (ageInSeconds < 60*60*24*365) {
        NSInteger months = (NSInteger)(ageInSeconds / (60*60*24*30));
        return [NSString stringWithFormat:@"%i %@ ago", months, (months == 1 ? @"month": @"months")];
    } else {
        NSInteger years = (NSInteger)(ageInSeconds / (60*60*24*365));
        return [NSString stringWithFormat:@"%i %@ ago", years, (years == 1 ? @"year" : @"years")];
    }
}

- (void)awakeFromNib
{
    [super awakeFromNib];
            
    [self addSubview:portraitView];
    currentOrientedView = portraitView;
    
    [[NSBundle mainBundle] loadNibNamed:@"VideoControlView" owner:self options:nil];
    [self updateControlsViewForCurrentOrientation];
    [currentOrientedView addSubview:controlsView];
    
    mentionsArray = [[NSMutableArray alloc] init];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(handleSocialMentionUpdate:) name:NMDidPostFacebookCommentNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(handleSocialMentionUpdate:) name:NMDidReplyTweetNotificaiton object:nil];
    [notificationCenter addObserver:self selector:@selector(handleSocialMentionUpdate:) name:NMDidPostRetweetNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(handleSocialMentionUpdate:) name:NMDidShareVideoNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(handleSocialMentionUpdate:) name:NMDidPostTweetNotification object:nil];    
    [notificationCenter addObserver:self selector:@selector(handleSocialMentionUpdate:) name:@"NMDidPostFacebookLikeNotificaiton" object:nil];    
    [notificationCenter addObserver:self selector:@selector(handleSocialMentionUpdate:) name:@"NMDidDeleteFacebookLikeNotification" object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [portraitView release];
    [landscapeView release];
    [controlsView release];
    [mentionsArray release];
    
    [super dealloc];
}

- (void)setVideo:(NMVideo *)video {
    [super setVideo:video];
    
    [self setChannelTitle:video.channel.title];
    [self setAuthor:video.video.author];
    [self setVideoTitle:video.video.title];
    [self setDate:video.video.published_at];
    [self setDescriptionText:video.video.detail.nm_description];
    [self setWatchLater:[video.video.nm_watch_later boolValue]];
    [self setFavorite:[video.video.nm_favorite boolValue]];
    [self setTopActionButtonIndex:([video.video.nm_favorite boolValue] ? 2 : 0)];

    [self updateSocialMentions];
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

- (void)setDate:(NSDate *)date
{
    NSString *dateString = [NSDateFormatter localizedStringFromDate:date 
                                                          dateStyle:NSDateFormatterLongStyle 
                                                          timeStyle:NSDateFormatterNoStyle];
    
    NSString *labelText = [NSString stringWithFormat:@"Uploaded on %@", dateString];
    [portraitView.dateLabel setText:labelText];
    [landscapeView.dateLabel setText:labelText];
}

- (void)setDescriptionText:(NSString *)descriptionText
{
    [portraitView.descriptionLabel setText:descriptionText];
    [landscapeView.descriptionLabel setText:descriptionText];
}

- (void)setAuthor:(NMAuthor *)author
{
    [portraitView.authorLabel setText:author.username];
    [landscapeView.authorLabel setText:author.username];
    [portraitView.channelThumbnail setImageForAuthorThumbnail:author];
    [landscapeView.channelThumbnail setImageForAuthorThumbnail:author];
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

- (void)setWatchLater:(BOOL)watchLater
{
    [portraitView setWatchLater:watchLater];
    [landscapeView setWatchLater:watchLater];
}

- (void)setFavorite:(BOOL)favorite
{
    [portraitView setFavorite:favorite];
    [landscapeView setFavorite:favorite];
}

- (void)setTopActionButtonIndex:(NSUInteger)actionButtonIndex
{
    [portraitView setTopActionButtonIndex:actionButtonIndex];
    [landscapeView setTopActionButtonIndex:actionButtonIndex];
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

- (void)updateSocialMentions
{
    // Add buzz
    [mentionsArray removeAllObjects];
    [portraitView.buzzView removeAllMentions];
    
    for (NMSocialInfo *socialInfo in self.video.video.socialMentions) {
        BOOL mentionLikedByUser = [socialInfo.peopleLike containsObject:[[NMAccountManager sharedAccountManager] facebookProfile]];
        
        [mentionsArray addObject:socialInfo];
        [portraitView.buzzView addMentionLiked:mentionLikedByUser];
        
        // Show the original post as the first "comment"
        BuzzCommentView *postView = [portraitView.buzzView addCommentWithText:socialInfo.message username:socialInfo.poster.name];
        [postView.userImageView setImageForPersonProfile:socialInfo.poster];
        postView.timeLabel.text = [PhoneMovieDetailView relativeTimeStringForTime:[socialInfo.nm_date_last_updated floatValue]];
        postView.serviceIcon.image = [PhoneMovieDetailView serviceIconForChannelType:[socialInfo.nm_type integerValue]];
        postView.likesCountLabel.text = [NSString stringWithFormat:@"%i %@, %i comments", [socialInfo.likes_count integerValue], ([socialInfo.likes_count integerValue] == 1 ? @"like" : @"likes"), [socialInfo.comments_count integerValue]];
        
        // Show the actual comments in chronological order
        NSArray *sortedComments = [socialInfo.comments sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"created_time" ascending:YES]]];
        for (NMSocialComment *comment in sortedComments) {
            BuzzCommentView *commentView = [portraitView.buzzView addCommentWithText:comment.message username:comment.fromPerson.name];
            [commentView.userImageView setImageForPersonProfile:comment.fromPerson];
            commentView.timeLabel.text = [PhoneMovieDetailView relativeTimeStringForTime:[comment.created_time floatValue]];
            commentView.serviceIcon.image = [PhoneMovieDetailView serviceIconForChannelType:[socialInfo.nm_type integerValue]];
        }
    }
    [portraitView.buzzView doneAdding];
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

#pragma mark - Notifications

- (void)handleSocialMentionUpdate:(NSNotification *)notification
{
    [self updateSocialMentions];
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

- (void)buzzView:(BuzzView *)buzzView didPressLikeButton:(id)sender
{    
    if ([delegate respondsToSelector:@selector(videoInfoView:didLike:socialInfo:)]) {
        NSUInteger mentionIndex = [sender tag];
        NMSocialInfo *socialInfo = [mentionsArray objectAtIndex:mentionIndex];

        [delegate videoInfoView:self didLike:YES socialInfo:socialInfo];
    }
}

- (void)buzzView:(BuzzView *)buzzView didPressUnlikeButton:(id)sender
{
    if ([delegate respondsToSelector:@selector(videoInfoView:didLike:socialInfo:)]) {
        NSUInteger mentionIndex = [sender tag];
        NMSocialInfo *socialInfo = [mentionsArray objectAtIndex:mentionIndex];
        
        [delegate videoInfoView:self didLike:NO socialInfo:socialInfo];
    }
}

- (void)buzzView:(BuzzView *)buzzView didPressCommentButton:(id)sender
{
    if ([delegate respondsToSelector:@selector(videoInfoView:didTapCommentButton:socialInfo:)]) {
        NSUInteger mentionIndex = [sender tag];
        if (mentionIndex < [mentionsArray count]) {
            NMSocialInfo *socialInfo = [mentionsArray objectAtIndex:mentionIndex];    
            [delegate videoInfoView:self didTapCommentButton:sender socialInfo:socialInfo];
        }
    }
}

@end
