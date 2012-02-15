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

- (void)setAuthorText:(NSString *)authorText
{
    [portraitView.authorLabel setText:authorText];
    [landscapeView.authorLabel setText:authorText];
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

@end

#pragma mark -

@implementation PhoneVideoInfoOrientedView

@synthesize topView;
@synthesize bottomView;
@synthesize channelTitleLabel;
@synthesize videoTitleLabel;
@synthesize authorLabel;
@synthesize channelThumbnail;

- (void)dealloc
{
    [channelTitleLabel release];
    [videoTitleLabel release];
    [authorLabel release];
    [channelThumbnail release];
    
    [super dealloc];
}

- (void)positionLabels
{
    // Position the author label below the video title
    CGSize videoTitleSize = [videoTitleLabel.text sizeWithFont:videoTitleLabel.font 
                                             constrainedToSize:videoTitleLabel.frame.size
                                                 lineBreakMode:videoTitleLabel.lineBreakMode];
    CGRect frame = authorLabel.frame;
    frame.origin.y = videoTitleLabel.frame.origin.y + videoTitleSize.height;
    authorLabel.frame = frame;
}

@end