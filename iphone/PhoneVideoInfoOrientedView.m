//
//  PhoneVideoInfoOrientedView.m
//  ipad
//
//  Created by Chris Haugli on 2/21/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "PhoneVideoInfoOrientedView.h"
#import "UIFont+BackupFont.h"
#import <QuartzCore/QuartzCore.h>

#define kPortraitInfoPanelHeightDefault   112
#define kPortraitInfoPanelHeightExpanded  192
#define kLandscapeInfoPanelHeightDefault  98
#define kLandscapeInfoPanelHeightExpanded 156
#define kBuzzPanelHeightDefault           75
#define kBuzzPanelHeightExpanded          176

#pragma mark - PhoneVideoInfoOrientedView

@implementation PhoneVideoInfoOrientedView

@synthesize topView;
@synthesize bottomView;
@synthesize infoView;
@synthesize buzzView;
@synthesize authorThumbnailPlaceholder;
@synthesize infoScrollView;
@synthesize infoButtonScrollView;
@synthesize channelTitleLabel;
@synthesize videoTitleLabel;
@synthesize descriptionLabelContainer;
@synthesize authorLabel;
@synthesize dateLabel;
@synthesize descriptionLabel;
@synthesize moreVideosButton;
@synthesize watchLaterButton;
@synthesize shareButton;
@synthesize favoriteButton;
@synthesize toggleInfoPanelButton;
@synthesize infoPanelExpanded;
@synthesize buzzPanelExpanded;
@synthesize delegate;

- (void)awakeFromNib
{
    UIView *viewToMask = infoButtonScrollView.superview;
    
    // Gradient fade-out for info buttons
    CAGradientLayer *mask = [CAGradientLayer layer];
    mask.frame = CGRectMake(0, 0, viewToMask.bounds.size.width, viewToMask.bounds.size.height * 2);
    mask.colors = [NSArray arrayWithObjects:
                   (id)[UIColor clearColor].CGColor,
                   (id)[UIColor clearColor].CGColor,
                   (id)[UIColor whiteColor].CGColor,
                   (id)[UIColor whiteColor].CGColor,                       
                   (id)[UIColor clearColor].CGColor, nil];
    mask.startPoint = CGPointMake(0.5, 0);
    mask.endPoint = CGPointMake(0.5, 1);
    mask.locations = [NSArray arrayWithObjects:
                      [NSNumber numberWithFloat:0],
                      [NSNumber numberWithFloat:0.025],
                      [NSNumber numberWithFloat:0.06],                      
                      [NSNumber numberWithFloat:0.25],
                      [NSNumber numberWithFloat:0.425], nil];
    viewToMask.layer.mask = mask; 
    
    // Keep track of what our video title frame originally was - we will be resizing it later
    originalVideoTitleFrame = videoTitleLabel.frame;
    originalDescriptionFrame = descriptionLabel.frame;
    
    channelTitleLabel.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:19.0f backupFontName:@"Futura-Medium" size:16.0f];
    videoTitleLabel.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:30.0f backupFontName:@"Futura-Medium" size:26.0f];
    authorLabel.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:14.0f backupFontName:@"Futura-Medium" size:12.0f];
    dateLabel.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:14.0f backupFontName:@"Futura-Medium" size:12.0f];
    descriptionLabel.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:14.0f backupFontName:@"Futura-Medium" size:12.0f];
    moreVideosButton.titleLabel.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:16.0f backupFontName:@"Futura-Medium" size:16.0f];
    
    [channelTitleLabel setGradientStartColor:[UIColor colorWithRed:255.0/255.0f green:223.0/255.0f blue:93.0/255.0f alpha:1.0f]
                                    endColor:[UIColor colorWithRed:255.0/255.0f green:197.0/255.0f blue:61.0/255.0f alpha:1.0f]];
}

- (void)dealloc
{
    [topView release];
    [bottomView release];
    [infoView release];
    [buzzView release];
    [authorThumbnailPlaceholder release];
    [infoScrollView release];
    [infoButtonScrollView release];
    [channelTitleLabel release];
    [videoTitleLabel release];
    [descriptionLabelContainer release];
    [authorLabel release];
    [dateLabel release];
    [descriptionLabel release];
    [moreVideosButton release];
    [watchLaterButton release];
    [shareButton release];
    [favoriteButton release];
    [toggleInfoPanelButton release];
    
    [super dealloc];
}

- (void)positionLabels
{        
    if (descriptionLabelContainer) return;
    
    // Size the title label to fit
    videoTitleLabel.frame = originalVideoTitleFrame;
    [videoTitleLabel sizeToFit];
    
    if (infoPanelExpanded) {
        // Position the author label below the video title
        CGRect frame = authorLabel.frame;
        frame.origin.y = CGRectGetMaxY(videoTitleLabel.frame) + 2;
        authorLabel.frame = frame;
        
        // Position the upload date label below the author label
        frame = dateLabel.frame;
        frame.origin.y = CGRectGetMaxY(authorLabel.frame);
        dateLabel.frame = frame;

        // Position the description label below the upload date label
        frame = originalDescriptionFrame;
        frame.origin.y = CGRectGetMaxY(dateLabel.frame) + 6;
        frame.size.height = 10000;
        descriptionLabel.frame = frame;
        [descriptionLabel sizeToFit];
        
        infoScrollView.contentSize = CGSizeMake(infoScrollView.frame.size.width, CGRectGetMaxY(descriptionLabel.frame) + 6);
        toggleInfoPanelButton.frame = CGRectMake(0, 0, infoScrollView.contentSize.width, infoScrollView.contentSize.height);
    } else {   
        // Limit the height of the video title
        CGRect frame = videoTitleLabel.frame;
        frame.size.height = MIN(frame.size.height, originalVideoTitleFrame.size.height);
        videoTitleLabel.frame = frame;

        // Position the author label below the video title
        frame = authorLabel.frame;
        frame.origin.y = CGRectGetMaxY(videoTitleLabel.frame) + 2;
        authorLabel.frame = frame;
        
        // Position the upload date label just offscreen
        frame = dateLabel.frame;
        frame.origin.y = infoView.frame.size.height;
        dateLabel.frame = frame;
        
        // Position the description label below the upload date label
        frame = originalDescriptionFrame;
        frame.origin.y = CGRectGetMaxY(dateLabel.frame) + 6;
        frame.size.height = 10000;
        descriptionLabel.frame = frame;
        [descriptionLabel sizeToFit];

        infoScrollView.contentSize = infoScrollView.bounds.size;
        toggleInfoPanelButton.frame = infoScrollView.bounds;
    }
}

- (void)setTopActionButtonIndex:(NSUInteger)actionButtonIndex
{
    [infoButtonScrollView centerViewAtIndex:actionButtonIndex];
    mostRecentActionButton = nil;
}

- (void)setInfoPanelExpanded:(BOOL)expanded
{
    [self setInfoPanelExpanded:expanded animated:NO];
}

- (void)setInfoPanelExpanded:(BOOL)expanded animated:(BOOL)animated
{        
    infoPanelExpanded = expanded;
    
    BOOL landscape = (infoView == bottomView);

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
                          [NSNumber numberWithFloat:0],
                          [NSNumber numberWithFloat:0],
                          [NSNumber numberWithFloat:1.0],
                          [NSNumber numberWithFloat:1.0], nil];
    } else {
        mask.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0],
                          [NSNumber numberWithFloat:0.025],
                          [NSNumber numberWithFloat:0.06],
                          [NSNumber numberWithFloat:0.25],
                          [NSNumber numberWithFloat:0.425], nil];
    }
    if (animated) {
        [CATransaction commit];
    }

    void (^animations)(void) = ^{
        if (buzzPanelExpanded) {
            [self setBuzzPanelExpanded:NO];
        }
        
        CGRect frame = infoView.frame;
        
        if (landscape) {
            // Landscape - resize view keeping the bottom position the same
            frame.size.height = (expanded ? kLandscapeInfoPanelHeightExpanded : kLandscapeInfoPanelHeightDefault);
            frame.origin.y = CGRectGetMaxY(infoView.frame) - frame.size.height;
        } else {
            // Portrait - resize view keeping the top position the same
            frame.size.height = (expanded ? kPortraitInfoPanelHeightExpanded : kPortraitInfoPanelHeightDefault);
        }
        
        // Resize the panel and move the buzz view accordingly
        buzzView.frame = CGRectOffset(buzzView.frame, 0, frame.size.height - infoView.frame.size.height);
        infoView.frame = frame;
        
        [self positionLabels];
        
        // We want the most recent action item to be on top when we collapse
        if (!expanded && mostRecentActionButton) {
            NSInteger indexDelta = ABS(infoButtonScrollView.centerViewIndex - [mostRecentActionButton tag]) % 3;
            [infoButtonScrollView centerViewAtIndex:[mostRecentActionButton tag] avoidMovingViewsToAbove:(indexDelta < 2)];
        }
    };

    void (^completion)(BOOL) = ^(BOOL finished){
        if (!expanded) {
            [infoButtonScrollView setNeedsLayout];
        }
    };
    
    // Perform the animation
    if (animated) {
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                         animations:animations
                         completion:completion];
    } else {
        animations();
        completion(YES);
    }
}

- (void)setBuzzPanelExpanded:(BOOL)expanded
{
    [self setBuzzPanelExpanded:expanded animated:NO];
}

- (void)setBuzzPanelExpanded:(BOOL)expanded animated:(BOOL)animated
{
    buzzPanelExpanded = expanded;
    
    // Update the height but keep the distance from the bottom the same
    CGRect frame = buzzView.frame;
    frame.size.height = (expanded ? kBuzzPanelHeightExpanded : kBuzzPanelHeightDefault);
    CGFloat distanceFromBottom = buzzView.superview.frame.size.height - CGRectGetMaxY(buzzView.frame);
    frame.origin.y = buzzView.superview.frame.size.height - distanceFromBottom - frame.size.height;
    
    void (^animations)(void) = ^{
        // Resize the buzz view and move the info panel accordingly
        infoView.frame = CGRectOffset(infoView.frame, 0, buzzView.frame.size.height - frame.size.height);
        buzzView.frame = frame;
        [buzzView setShowsActionButtons:expanded];
    };
    
    // Perform the animation
    if (animated) {
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                         animations:animations
                         completion:^(BOOL finished){
                         }];
    } else {
        animations();
    }
}

- (void)setWatchLater:(BOOL)watchLater
{
    if (watchLater) {
        [watchLaterButton setImage:[UIImage imageNamed:@"phone_button_watch_later_active.png"] forState:UIControlStateNormal];
    } else {
        [watchLaterButton setImage:[UIImage imageNamed:@"phone_button_watch_later.png"] forState:UIControlStateNormal];        
    }
    [watchLaterButton setEnabled:YES];
}

- (void)setFavorite:(BOOL)favorite
{
    if (favorite) {
        [favoriteButton setImage:[UIImage imageNamed:@"phone_button_like_active.png"] forState:UIControlStateNormal];
    } else {
        [favoriteButton setImage:[UIImage imageNamed:@"phone_button_like.png"] forState:UIControlStateNormal];        
    }
    [favoriteButton setEnabled:YES];
}

- (IBAction)actionButtonPressed:(id)sender
{
    mostRecentActionButton = sender;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [infoButtonScrollView centerContentOffset];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [infoButtonScrollView centerContentOffset];
    }
    
    [delegate phoneVideoInfoOrientedView:self didEndDraggingWithScrollView:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [delegate phoneVideoInfoOrientedView:self willBeginDraggingWithScrollView:scrollView];
}

@end

#pragma mark - InfiniteScrollView

@implementation InfiniteScrollView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    // Since clipToBounds = NO, we want to allow swiping anywhere content is shown
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

- (void)loopViewsIfNeededAvoidLoopToTop:(BOOL)avoidLoopToTop
{
    // Do we need to loop any of the subviews to the top / bottom?
    if (self.scrollEnabled) {
        for (UIView *view in self.subviews) {
            CGFloat distance = view.center.y - (self.contentOffset.y + self.frame.size.height / 2);
            CGFloat newY = view.center.y + (distance > 0 ? -1.0f : 1.0f) * [self.subviews count] * self.frame.size.height;
            CGFloat newDistance = newY - (self.contentOffset.y + self.frame.size.height / 2);
            
            if (ABS(newDistance) < ABS(distance) && (!avoidLoopToTop || newY > self.contentOffset.y)) {
                view.center = CGPointMake(view.center.x, newY);
            }
        }
    }
}

- (void)centerViewAtIndex:(NSUInteger)index avoidMovingViewsToAbove:(BOOL)avoidMovingAbove
{
    NSUInteger pageCount = round((self.contentSize.height / 2) / self.frame.size.height);
    self.contentOffset = CGPointMake(0, (pageCount + index) * self.frame.size.height);    
    for (UIView *view in self.subviews) {
        CGRect frame = view.frame;
        frame.origin.y = (pageCount + view.tag) * self.frame.size.height;
        if (!avoidMovingAbove || frame.origin.y >= self.contentOffset.y) {
            view.frame = frame;
        }
    }
    
    [self loopViewsIfNeededAvoidLoopToTop:avoidMovingAbove];
}

- (void)centerViewAtIndex:(NSUInteger)index
{
    [self centerViewAtIndex:index avoidMovingViewsToAbove:NO];
}

- (void)centerContentOffset
{
    // Make sure we don't get too close to the scroll limit
    [self centerViewAtIndex:[self centerViewIndex]];
}

- (void)awakeFromNib
{
    // "Infinite" scrolling
    self.contentSize = CGSizeMake(self.frame.size.width, 10000);
    [self centerContentOffset];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self loopViewsIfNeededAvoidLoopToTop:NO];
}

@end