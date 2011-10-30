//
//  ChannelPreviewView.m
//  ipad
//
//  Created by Tim Chen on 8/9/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "ChannelPreviewView.h"
#import "NMStyleUtility.h"
#import "NMPreviewThumbnail.h"

@implementation ChannelPreviewView

@synthesize civ;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    UIImageView *videoShadowImageView = [[UIImageView alloc]initWithFrame:CGRectMake( -3, -2, frame.size.width+8, frame.size.height+8)];
    [videoShadowImageView setImage:[[UIImage imageNamed:@"channel-detail-video-shadow"] stretchableImageWithLeftCapWidth:3 topCapHeight:2]];
    [self addSubview:videoShadowImageView];
    
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activityIndicatorView.center = videoShadowImageView.center;
    [activityIndicatorView startAnimating];
    [self addSubview:activityIndicatorView];
    
    [activityIndicatorView release];
    [videoShadowImageView release];
    
    NMStyleUtility * style = [NMStyleUtility sharedStyleUtility];
    
    civ = [[NMCachedImageView alloc] initWithFrame:CGRectMake( 0, 0, 370.0f, 200.0f)];
    civ.contentMode = UIViewContentModeScaleAspectFill;
    civ.backgroundColor = style.blackColor;
    civ.clipsToBounds = YES;
    civ.hidden = YES;
    [self addSubview:civ];
    
    UIView *overlayView = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height-75, frame.size.width, 75)];
    [overlayView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.66f]];
    [civ addSubview:overlayView];
    [overlayView release];
    
    titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, frame.size.height-65, frame.size.width-20, 40)];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = style.videoTitleFont;
    titleLabel.numberOfLines = 0;
    titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
    titleLabel.backgroundColor = style.clearColor;
    [civ addSubview:titleLabel];
    
	durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width/2, frame.size.height-45, frame.size.width/2-10, 22)];
    [durationLabel setTextAlignment:UITextAlignmentRight];
    durationLabel.textColor = [UIColor colorWithRed:139/255.0f green:139/255.0f blue:139/255.0f alpha:1];
    durationLabel.font = style.videoDetailFont;
    durationLabel.numberOfLines = 0;
    durationLabel.lineBreakMode = UILineBreakModeTailTruncation;
    durationLabel.backgroundColor = style.clearColor;
    [civ addSubview:durationLabel];
    
	viewCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width/2, frame.size.height-27, frame.size.width/2-10, 22)];
    [viewCountLabel setTextAlignment:UITextAlignmentRight];
    viewCountLabel.textColor = [UIColor colorWithRed:139/255.0f green:139/255.0f blue:139/255.0f alpha:1];
    viewCountLabel.font = style.videoDetailFont;
    viewCountLabel.numberOfLines = 0;
    viewCountLabel.lineBreakMode = UILineBreakModeTailTruncation;
    viewCountLabel.backgroundColor = style.clearColor;
    [civ addSubview:viewCountLabel];
    
	dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, frame.size.height-27, frame.size.width/2-10, 22)];
    dateLabel.textColor = [UIColor colorWithRed:139/255.0f green:139/255.0f blue:139/255.0f alpha:1];
    dateLabel.font = style.videoDetailFont;
    dateLabel.numberOfLines = 0;
    dateLabel.lineBreakMode = UILineBreakModeTailTruncation;
    dateLabel.backgroundColor = style.clearColor;
    [civ addSubview:dateLabel];
    
	[self setClipsToBounds:NO];
    
    return self;
}

-(void)clearPreviewImage {
    civ.hidden = YES;
    civ.image = nil;
    [titleLabel setText:@""];
    [durationLabel setText:@""];
}

-(void)setPreviewImage:(NMPreviewThumbnail *)thePreview {
    [civ setImageForPreviewThumbnail:thePreview];
    
    CGSize maximumSize = CGSizeMake(350, 9999);
    CGSize stringSize = [thePreview.title sizeWithFont:titleLabel.font 
                                   constrainedToSize:maximumSize 
                                       lineBreakMode:titleLabel.lineBreakMode];
    CGRect newframe = titleLabel.frame;
    newframe.size.height = stringSize.height;
    titleLabel.frame = newframe;
    [titleLabel setText:thePreview.title];
    
    NSInteger dur = [thePreview.duration integerValue];
	durationLabel.text = [NSString stringWithFormat:@"%02d:%02d", dur / 60, dur % 60];
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];  
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    NSString *formattedOutput = [formatter stringFromNumber:thePreview.view_count];
    [formatter release];
    viewCountLabel.text = [NSString stringWithFormat:@"%@ views",formattedOutput];

    dateLabel.text = [[NMStyleUtility sharedStyleUtility].videoDateFormatter stringFromDate:thePreview.published_at];

    [civ setHidden:NO];
}

-(void)dealloc {
    [civ release];
    [titleLabel release];
    [durationLabel release];
    [dateLabel release];
    [viewCountLabel release];
    [super dealloc];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
