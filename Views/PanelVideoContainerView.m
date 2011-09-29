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
#import "PanelVideoCellView.h"

#define NM_VIDEO_CELL_PADDING	10.0f

@implementation PanelVideoContainerView
@synthesize titleLabel, datePostedLabel, backgroundColorView;
//@synthesize highlightedBackgroundImage;
@synthesize durationLabel;
//@synthesize viewsLabel;
@synthesize indexInTable;
@synthesize tableView;
@synthesize videoRowDelegate;
@synthesize videoStatusImageView;
@synthesize videoNewSession;
@synthesize isFirstCell;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
	NMStyleUtility * styleUtility = [NMStyleUtility sharedStyleUtility];
    if (self) {
        
        [self setClipsToBounds:YES];
        initialFrame = frame;

//        CGFloat angle = M_PI/2.0;
//        CGRect frame = self.frame;
//        frame.origin = CGPointMake(abs(frame.size.width - frame.size.height) / 2.0, 
//                                   (frame.size.height - frame.size.width) / 2.0);
//        super.frame = frame;
//        self.transform = CGAffineTransformMakeRotation(angle);
        
        
		self.backgroundColor = styleUtility.channelPanelBackgroundColor;
        
        backgroundColorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, initialFrame.size.width, initialFrame.size.height+NM_VIDEO_CELL_PADDING)];
//        [backgroundColorView setBackgroundColor:normalColor];
        [backgroundColorView setClipsToBounds:YES];
//        [self addSubview:backgroundColorView];
        
//        highlightedBackgroundImage = [[UIImageView alloc] initWithImage:styleUtility.videoHighlightedBackgroundImage];
//        [highlightedBackgroundImage setFrame:CGRectMake(initialFrame.size.width-104, -1, 104, 90)];
//        [highlightedBackgroundImage setHidden:YES];
//        [highlightedBackgroundImage setClipsToBounds:YES];
//        [self addSubview:highlightedBackgroundImage];

        titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(NM_VIDEO_CELL_PADDING, NM_VIDEO_CELL_PADDING, initialFrame.size.width - NM_VIDEO_CELL_PADDING * 2.0f, initialFrame.size.height - 12 - NM_VIDEO_CELL_PADDING * 2.0f)];
		titleMaxSize = titleLabel.bounds.size;
//		titleLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		titleLabel.textColor = styleUtility.videoTitleFontColor;
		titleLabel.font = styleUtility.videoTitleFont;
		titleLabel.numberOfLines = 0;
		titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
		titleLabel.backgroundColor = styleUtility.clearColor;
		titleLabel.highlightedTextColor = styleUtility.videoTitleHighlightedFontColor;
//		[self addSubview:titleLabel];
        
        datePostedLabel = [[UILabel alloc] initWithFrame:CGRectMake(NM_VIDEO_CELL_PADDING, NM_VIDEO_CELL_HEIGHT - 24.0f, frame.size.width - NM_VIDEO_CELL_PADDING * 2.0f, 13.0f)];
		datePostedLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		datePostedLabel.textColor = styleUtility.videoDetailFontColor;
		datePostedLabel.backgroundColor = styleUtility.clearColor;
		datePostedLabel.font = styleUtility.videoDetailFont;
		datePostedLabel.highlightedTextColor = styleUtility.videoDetailHighlightedFontColor;
//		[self addSubview:datePostedLabel];

//        viewsLabel = [[UILabel alloc] initWithFrame:CGRectMake(NM_VIDEO_CELL_PADDING, NM_VIDEO_CELL_HEIGHT - 20.0f, frame.size.width - NM_VIDEO_CELL_PADDING * 2.0f, 12.0f)];
//		viewsLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//		viewsLabel.textAlignment = UITextAlignmentRight;
//		viewsLabel.textColor = styleUtility.videoDetailFontColor;
//		viewsLabel.backgroundColor = styleUtility.clearColor;
//		viewsLabel.font = styleUtility.videoDetailFont;
//		viewsLabel.highlightedTextColor = styleUtility.videoDetailHighlightedFontColor;
        
//		[self addSubview:viewsLabel];
		
        durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(NM_VIDEO_CELL_PADDING, NM_VIDEO_CELL_HEIGHT - 24.0f, frame.size.width - NM_VIDEO_CELL_PADDING * 2.0f, 13.0f)];
		durationLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		durationLabel.textAlignment = UITextAlignmentRight;
		durationLabel.textColor = styleUtility.videoDetailFontColor;
		durationLabel.backgroundColor = styleUtility.clearColor;
		durationLabel.font = styleUtility.videoDetailFont;
		durationLabel.highlightedTextColor = styleUtility.videoDetailHighlightedFontColor;
        
//		[self addSubview:durationLabel];
        
        UITapGestureRecognizer *singleFingerDTap = [[UITapGestureRecognizer alloc]
                                                    initWithTarget:self action:@selector(handleSingleDoubleTap:)];
        singleFingerDTap.numberOfTapsRequired = 1;
        [self addGestureRecognizer:singleFingerDTap];
        [singleFingerDTap release];
        
        cellView = [[PanelVideoCellView alloc]initWithFrame:frame];
        [self.contentView addSubview:cellView];
        
        highlightedCellView = [[PanelVideoCellView alloc]initWithFrame:frame];
        [self.contentView addSubview:highlightedCellView];
        
        videoStatusImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        
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
//    [highlightedBackgroundImage setFrame:CGRectMake(initialFrame.size.height-104, -1, 104, 90)];
}

- (void)dealloc
{
    [backgroundColorView release];
	[titleLabel release];
	[datePostedLabel release];
	[durationLabel release];
//    [viewsLabel release];
//    [highlightedBackgroundImage release];
    [cellView release];
    [highlightedCellView release];
    [videoStatusImageView release];
    [super dealloc];
}

- (void)setIsLoadingCell { 
    
    videoStatusImageView.image = nil;
    
    datePostedLabel.text = @"Loading Videos...";
    datePostedLabel.textColor = [NMStyleUtility sharedStyleUtility].videoDetailPlayedFontColor;
    [cellView configureCellWithPanelVideoContainerView:self highlighted:NO videoPlayed:NO];

}

- (void)setVideoInfo:(NMVideo *)aVideo {
    NMDataController * dataCtrl = [NMTaskQueueController sharedTaskQueueController].dataController;

    isVideoPlayable = ([[aVideo nm_error] intValue] == 0) && (aVideo.nm_playback_status >= 0);
    BOOL isVideoFavorited = (([[aVideo nm_favorite] intValue] == 1) && ([aVideo channel] != [dataCtrl favoriteVideoChannel]));
    BOOL isVideoQueued = (([[aVideo nm_watch_later] intValue] == 1) && ([aVideo channel] != [dataCtrl myQueueChannel]));
    
    CGSize labelSize = CGSizeMake(initialFrame.size.width - NM_VIDEO_CELL_PADDING * 2.0f, initialFrame.size.height - 12 - NM_VIDEO_CELL_PADDING * 2.0f);
    CGSize theStringSize = [aVideo.title  sizeWithFont:titleLabel.font constrainedToSize:labelSize lineBreakMode:titleLabel.lineBreakMode];
    titleLabel.frame = CGRectMake(NM_VIDEO_CELL_PADDING, NM_VIDEO_CELL_PADDING, theStringSize.width, theStringSize.height);
    titleLabel.text = aVideo.title;
    if (!isVideoPlayable) {
        videoStatusImageView.image = [NMStyleUtility sharedStyleUtility].videoStatusBadImage;
    }
    else if (isVideoFavorited) {
        videoStatusImageView.image = [NMStyleUtility sharedStyleUtility].videoStatusFavImage;
    }
    else if (isVideoQueued) {
        videoStatusImageView.image = [NMStyleUtility sharedStyleUtility].videoStatusQueuedImage;
    }
    else {
        videoStatusImageView.image = nil;
    }
    
    // should add new session separator here
    
	datePostedLabel.text = [[NMStyleUtility sharedStyleUtility].videoDateFormatter stringFromDate:aVideo.published_at];
	NSInteger dur = [aVideo.duration integerValue];
	durationLabel.text = [NSString stringWithFormat:@"%02d:%02d", dur / 60, dur % 60];
    
//    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];  
//    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
//    NSString *formattedOutput = [formatter stringFromNumber:[aVideo view_count]];
//    [formatter release];
    
//    viewsLabel.text = [NSString stringWithFormat:@"%@ views",formattedOutput];
//    [viewsLabel setFrame:CGRectMake(NM_VIDEO_CELL_PADDING, NM_VIDEO_CELL_HEIGHT - 20.0f, self.frame.size.width - NM_VIDEO_CELL_PADDING * 2.0f, 12.0f)];
    [durationLabel setFrame:CGRectMake(NM_VIDEO_CELL_PADDING, NM_VIDEO_CELL_HEIGHT - 24.0f, self.frame.size.width - NM_VIDEO_CELL_PADDING * 2.0f, 12.0f)];
    
    if ([aVideo.nm_did_play boolValue] || !isVideoPlayable) {
        titleLabel.textColor = [NMStyleUtility sharedStyleUtility].videoTitlePlayedFontColor;
        datePostedLabel.textColor = [NMStyleUtility sharedStyleUtility].videoDetailPlayedFontColor;
        durationLabel.textColor = [NMStyleUtility sharedStyleUtility].videoDetailPlayedFontColor;
//        viewsLabel.textColor = [NMStyleUtility sharedStyleUtility].videoDetailPlayedFontColor;
    }
    else {
        titleLabel.textColor = [NMStyleUtility sharedStyleUtility].videoTitleFontColor;
        datePostedLabel.textColor = [NMStyleUtility sharedStyleUtility].videoDetailFontColor;
        durationLabel.textColor = [NMStyleUtility sharedStyleUtility].videoDetailFontColor;
//        viewsLabel.textColor = [NMStyleUtility sharedStyleUtility].videoDetailFontColor;
    }
    
    [highlightedCellView configureCellWithPanelVideoContainerView:self highlighted:YES videoPlayed:NO];
    
    [cellView configureCellWithPanelVideoContainerView:self highlighted:NO videoPlayed:[aVideo.nm_did_play boolValue]];
    
}

- (void)setIsPlayingVideo:(BOOL)abool {
    currentVideoIsPlaying = abool;
    [self changeViewToHighlighted:abool];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated; {
    // don't do anything, we'll deal with highlighted states ourselves
}

- (void)changeViewToHighlighted:(BOOL)isHighlighted {
    // this doesn't actually update the highlighted state
    [cellView setHidden:isHighlighted];
    [highlightedCellView setHidden:!isHighlighted];
}

#pragma mark UIResponder
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	// highlight
    [self changeViewToHighlighted:YES];
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	// check if touch up inside the view itself
    [self changeViewToHighlighted:currentVideoIsPlaying];
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	// remove highlight
    // only if it wasn't highlighted previously
    [self changeViewToHighlighted:currentVideoIsPlaying];
    [super touchesCancelled:touches withEvent:event];
}

-(void)handleSingleDoubleTap:(UIGestureRecognizer *)sender {
    if (isVideoPlayable) {
        if ( videoRowDelegate ) {
            [self changeViewToHighlighted:YES];
            [videoRowDelegate playVideoForIndexPath:[NSIndexPath indexPathForRow:indexInTable inSection:0]];
        }
    }
}

@end
