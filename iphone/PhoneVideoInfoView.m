//
//  PhoneVideoInfoView.m
//  ipad
//
//  Created by Chris Haugli on 2/13/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "PhoneVideoInfoView.h"

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

#pragma mark -

@implementation PhoneVideoInfoOrientedView

@synthesize topView;
@synthesize bottomView;
@synthesize infoView;
@synthesize channelTitleLabel;
@synthesize videoTitleLabel;
@synthesize descriptionLabel;
@synthesize channelThumbnail;

- (void)dealloc
{
    [topView release];
    [bottomView release];
    [infoView release];
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
    } else {
        frame.size.height = 116;
    }
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         infoView.frame = frame;                         
                     }
                     completion:^(BOOL finished){
                     }];
}

@end
