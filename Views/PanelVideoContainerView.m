//
//  PanelVideoContainerView.m
//  ipad
//
//  Created by Bill So on 20/06/2011.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "PanelVideoContainerView.h"
#import "NMStyleUtility.h"
#import "NMLibrary.h"

#define NM_VIDEO_CELL_PADDING	10.0f

@implementation PanelVideoContainerView
@synthesize titleLabel, datePostedLabel;
@synthesize highlightColor, durationLabel, viewsLabel;
@synthesize normalColor, indexInTable;
@synthesize tableView;
@synthesize videoRowDelegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
	NMStyleUtility * styleUtility = [NMStyleUtility sharedStyleUtility];
    if (self) {
        
        [self setClipsToBounds:YES];
        initialFrame = frame;

        CGFloat angle = M_PI/2.0;
        CGRect frame = self.frame;
        frame.origin = CGPointMake(abs(frame.size.width - frame.size.height) / 2.0, 
                                   (frame.size.height - frame.size.width) / 2.0);
        super.frame = frame;
        self.transform = CGAffineTransformMakeRotation(angle);
        
        highlightedBackgroundImage = [[UIImageView alloc] initWithImage:styleUtility.videoHighlightedBackgroundImage];
        [highlightedBackgroundImage setFrame:CGRectMake(initialFrame.size.width-104, -1, 104, 90)];
        [highlightedBackgroundImage setHidden:YES];
        [highlightedBackgroundImage setClipsToBounds:YES];
        [self addSubview:highlightedBackgroundImage];

        titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(NM_VIDEO_CELL_PADDING, NM_VIDEO_CELL_PADDING, initialFrame.size.width - NM_VIDEO_CELL_PADDING * 2.0f, initialFrame.size.height - 12 - NM_VIDEO_CELL_PADDING * 2.0f)];
		titleMaxSize = titleLabel.bounds.size;
//		titleLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		titleLabel.textColor = styleUtility.videoTitleFontColor;
		titleLabel.font = styleUtility.videoTitleFont;
		titleLabel.numberOfLines = 0;
		titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
		titleLabel.backgroundColor = styleUtility.clearColor;
		titleLabel.highlightedTextColor = styleUtility.videoTitleHighlightedFontColor;
		[self addSubview:titleLabel];
        
        datePostedLabel = [[UILabel alloc] initWithFrame:CGRectMake(NM_VIDEO_CELL_PADDING, NM_VIDEO_CELL_HEIGHT - 20.0f, frame.size.width - NM_VIDEO_CELL_PADDING * 2.0f, 12.0f)];
		datePostedLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		datePostedLabel.textColor = styleUtility.videoDetailFontColor;
		datePostedLabel.backgroundColor = styleUtility.clearColor;
		datePostedLabel.font = styleUtility.videoDetailFont;
		datePostedLabel.highlightedTextColor = styleUtility.videoDetailHighlightedFontColor;
		[self addSubview:datePostedLabel];

        viewsLabel = [[UILabel alloc] initWithFrame:CGRectMake(NM_VIDEO_CELL_PADDING, NM_VIDEO_CELL_HEIGHT - 20.0f, frame.size.width - NM_VIDEO_CELL_PADDING * 2.0f, 12.0f)];
		viewsLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		viewsLabel.textAlignment = UITextAlignmentRight;
		viewsLabel.textColor = styleUtility.videoDetailFontColor;
		viewsLabel.backgroundColor = styleUtility.clearColor;
		viewsLabel.font = styleUtility.videoDetailFont;
		viewsLabel.highlightedTextColor = styleUtility.videoDetailHighlightedFontColor;
        
		[self addSubview:viewsLabel];
		
        durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(NM_VIDEO_CELL_PADDING, NM_VIDEO_CELL_HEIGHT - 36.0f, frame.size.width - NM_VIDEO_CELL_PADDING * 2.0f, 12.0f)];
		durationLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		durationLabel.textAlignment = UITextAlignmentRight;
		durationLabel.textColor = styleUtility.videoDetailFontColor;
		durationLabel.backgroundColor = styleUtility.clearColor;
		durationLabel.font = styleUtility.videoDetailFont;
		durationLabel.highlightedTextColor = styleUtility.videoDetailHighlightedFontColor;
        
		[self addSubview:durationLabel];
        
        separatorView = [[UIView alloc]initWithFrame:CGRectMake(initialFrame.size.width-1, 0, 1, NM_VIDEO_CELL_HEIGHT)];
        separatorView.opaque = YES;
        separatorView.backgroundColor = styleUtility.channelBorderColor;
        
        [self addSubview:separatorView];
        
		self.backgroundColor = styleUtility.channelPanelBackgroundColor;
		self.normalColor = styleUtility.channelPanelBackgroundColor;
		self.highlightColor = styleUtility.channelPanelHighlightColor;
        
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void)setFrame:(CGRect)frame {
    initialFrame = frame;
    [super setFrame:frame];
    [separatorView setFrame:CGRectMake(initialFrame.size.height-1, 0, 1, NM_VIDEO_CELL_HEIGHT)];
    [highlightedBackgroundImage setFrame:CGRectMake(initialFrame.size.height-104, -1, 104, 90)];
}

- (void)dealloc
{
	[titleLabel release];
	[datePostedLabel release];
	[durationLabel release];
    [viewsLabel release];
	[highlightColor release];
	[normalColor release];
    [separatorView release];
    [highlightedBackgroundImage release];
    [super dealloc];
}

- (void)setTestInfo {
	NSString * testTitle = @"My Test Title";
	CGSize theSize = [testTitle sizeWithFont:titleLabel.font constrainedToSize:titleMaxSize];
	CGRect theFrame = titleLabel.frame;
	theFrame.size = theSize;
	titleLabel.frame = theFrame;
	titleLabel.text = testTitle;
	
	datePostedLabel.text = [[NMStyleUtility sharedStyleUtility].videoDateFormatter stringFromDate:[NSDate date]];
	NSInteger dur = 94;
	durationLabel.text = [NSString stringWithFormat:@"%02d:%02d", dur / 60, dur % 60];
}

- (void)setVideoInfo:(NMVideo *)aVideo {
    CGSize labelSize = CGSizeMake(initialFrame.size.width - NM_VIDEO_CELL_PADDING * 2.0f, initialFrame.size.height - 12 - NM_VIDEO_CELL_PADDING * 2.0f);
    CGSize theStringSize = [aVideo.title  sizeWithFont:titleLabel.font constrainedToSize:labelSize lineBreakMode:titleLabel.lineBreakMode];
    titleLabel.frame = CGRectMake(NM_VIDEO_CELL_PADDING, NM_VIDEO_CELL_PADDING, theStringSize.width, theStringSize.height);
    titleLabel.text = aVideo.title;
    
	datePostedLabel.text = [[NMStyleUtility sharedStyleUtility].videoDateFormatter stringFromDate:aVideo.published_at];
	NSInteger dur = [aVideo.duration integerValue];
	durationLabel.text = [NSString stringWithFormat:@"%02d:%02d", dur / 60, dur % 60];
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];  
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    NSString *formattedOutput = [formatter stringFromNumber:[aVideo view_count]];
    [formatter release];
    
    viewsLabel.text = [NSString stringWithFormat:@"%@ views",formattedOutput];
}

- (BOOL)highlighted {
	return highlighted_;
}

- (void)setHighlighted:(BOOL)abool {
	// set highlighted state for subviews as well
	highlighted_ = abool;
    [self changeViewToHighlighted:highlighted_];
}

- (void)changeViewToHighlighted:(BOOL)isHighlighted {
    // this doesn't actually update the highlighted state
	if ( isHighlighted ) {
		self.backgroundColor = highlightColor;
        titleLabel.highlighted = isHighlighted;
        datePostedLabel.highlighted = isHighlighted;
        durationLabel.highlighted = isHighlighted;
        viewsLabel.highlighted = isHighlighted;
        [highlightedBackgroundImage setHidden:NO];
	} else {
		self.backgroundColor = normalColor;
        titleLabel.highlighted = isHighlighted;
        datePostedLabel.highlighted = isHighlighted;
        durationLabel.highlighted = isHighlighted;
        viewsLabel.highlighted = isHighlighted;
        [highlightedBackgroundImage setHidden:YES];
	}
}

#pragma mark UIResponder
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	// highlight
    [self changeViewToHighlighted:YES];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self setHighlighted:YES];
	// check if touch up inside the view itself
	if ( videoRowDelegate ) {
		[videoRowDelegate tableView:tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:indexInTable inSection:0]];
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	// remove highlight
    // only if it wasn't highlighted previously
    [self changeViewToHighlighted:highlighted_];
}

@end
