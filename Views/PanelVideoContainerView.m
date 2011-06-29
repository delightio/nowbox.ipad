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
@synthesize highlightColor, durationLabel;
@synthesize normalColor, indexInTable;
@synthesize panelDelegate, tableView;
@synthesize highlighted;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
	NMStyleUtility * styleUtility = [NMStyleUtility sharedStyleUtility];
    if (self) {
        titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(NM_VIDEO_CELL_PADDING, NM_VIDEO_CELL_PADDING, frame.size.width - NM_VIDEO_CELL_PADDING * 2.0f, frame.size.height - NM_VIDEO_CELL_PADDING * 2.0f)];
		titleMaxSize = titleLabel.bounds.size;
		titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		titleLabel.textColor = styleUtility.channelPanelFontColor;
		titleLabel.font = styleUtility.videoTitleFont;
		titleLabel.numberOfLines = 0;
		titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
		titleLabel.backgroundColor = styleUtility.clearColor;
		[self addSubview:titleLabel];
		
        datePostedLabel = [[UILabel alloc] initWithFrame:CGRectMake(NM_VIDEO_CELL_PADDING, NM_VIDEO_CELL_HEIGHT - 20.0f, frame.size.width - NM_VIDEO_CELL_PADDING * 2.0f, 12.0f)];
		datePostedLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		datePostedLabel.textColor = styleUtility.channelPanelFontColor;
		datePostedLabel.backgroundColor = styleUtility.clearColor;
		datePostedLabel.font = styleUtility.videoDetailFont;
		[self addSubview:datePostedLabel];

        durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(NM_VIDEO_CELL_PADDING, NM_VIDEO_CELL_HEIGHT - 20.0f, frame.size.width - NM_VIDEO_CELL_PADDING * 2.0f, 12.0f)];
		durationLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		durationLabel.textAlignment = UITextAlignmentRight;
		durationLabel.textColor = styleUtility.channelPanelFontColor;
		durationLabel.backgroundColor = styleUtility.clearColor;
		durationLabel.font = styleUtility.videoDetailFont;
		[self addSubview:durationLabel];
		
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

- (void)dealloc
{
	[titleLabel release];
	[datePostedLabel release];
	[durationLabel release];
	[highlightColor release];
	[normalColor release];
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
	CGSize theSize = [aVideo.title sizeWithFont:titleLabel.font constrainedToSize:titleMaxSize];
	CGRect theFrame = titleLabel.frame;
	theFrame.size = theSize;
	titleLabel.frame = theFrame;
	titleLabel.text = aVideo.title;
	
	datePostedLabel.text = [[NMStyleUtility sharedStyleUtility].videoDateFormatter stringFromDate:aVideo.published_at];
	NSInteger dur = [aVideo.duration integerValue];
	durationLabel.text = [NSString stringWithFormat:@"%02d:%02d", dur / 60, dur % 60];
}

- (BOOL)highlighted {
	return highlighted_;
}

- (void)setHighlighted:(BOOL)abool {
	// set highlighted state for subviews as well
	titleLabel.highlighted = abool;
	datePostedLabel.highlighted = abool;
	durationLabel.highlighted = abool;
	highlighted_ = abool;
	if ( highlighted_ ) {
		self.backgroundColor = highlightColor;
	} else {
		self.backgroundColor = normalColor;
	}
}
#pragma mark UIResponder
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	// highlight
	self.backgroundColor = highlightColor;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	// check if touch up inside the view itself
	if ( panelDelegate ) {
		[panelDelegate tableView:tableView didSelectCellAtIndex:indexInTable];
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	// remove highlight
	self.backgroundColor = normalColor;
}

@end
