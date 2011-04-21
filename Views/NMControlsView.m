//
//  NMControlsView.m
//  Nowmov
//
//  Created by Bill So on 11/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMControlsView.h"
#import "NMMovieView.h"

#define NM_PLAYER_STATUS_CONTEXT		100
#define NM_PLAYER_CURRENT_ITEM_CONTEXT	101
#define NM_PLAYER_PROGRESS_BAR_WIDTH	330


@implementation NMControlsView

@synthesize title, duration, timeElapsed, authorProfileURLString;
@synthesize channelViewButton, shareButton, playPauseButton;
@synthesize nextVideoButton, controlsHidden, timeRangeBuffered;
@synthesize voteUpButton, voteDownButton;

- (void)awakeFromNib {
	// load the progress bar image
	UIImage * img = [UIImage imageNamed:@"playback_progress_background"];
	progressView.image = [img stretchableImageWithLeftCapWidth:6 topCapHeight:0];
	progressBarLayer = [[CALayer layer] retain];
	img = [UIImage imageNamed:@"progress_bar"];
	progressBarLayer.contents = (id)img.CGImage;
	progressBarLayer.contentsCenter = CGRectMake(0.4, 0.0, 0.2, 1.0);
	progressBarWidth = NM_PLAYER_PROGRESS_BAR_WIDTH - 18;
	progressBarLayer.bounds = CGRectMake(0.0, 0.0, 18.0, img.size.height);
	progressBarLayer.position = CGPointMake(0.0, 9.0);
	progressBarLayer.anchorPoint = CGPointMake(0.0f, 0.5f);
	progressBarLayer.shadowOpacity = 1.0;
	progressBarLayer.shadowOffset = CGSizeZero;
	[progressView.layer addSublayer:progressBarLayer];
	
	nubLayer = [[CALayer layer] retain];
	img = [UIImage imageNamed:@"progress_bar_nub"];
	nubLayer.contents = (id)img.CGImage;
	nubLayer.bounds = CGRectMake(0.0, 0.0, img.size.width, img.size.height);
	nubLayer.position = CGPointMake(floorf(img.size.width / 2.0), floorf(img.size.height / 2.0));
	
	[progressView.layer addSublayer:nubLayer];
}

//- (id)initWithFrame:(CGRect)frame {
//    
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code.
//    }
//    return self;
//}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

- (void)dealloc {
	[authorProfileURLString release];
	[progressBarLayer release];
	[nubLayer release];
    [super dealloc];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch * atouch = [touches anyObject];
	if ( atouch.tapCount == 1 ) {
		[target performSelector:action withObject:self];
	}
}

- (void)addTarget:(id)atarget action:(SEL)anAction {
	target = atarget;
	action = anAction;
}

- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated {
	if ( animated ) {
		[UIView beginAnimations:nil context:nil];
	}
	if ( hidden ) {
		self.alpha = 0.0;
//		prevVideoButton.alpha = 0.0;
//		nextVideoButton.alpha = 0.0;
//		progressView.alpha = 0.0;
//		durationLabel.alpha = 0.0;
//		currentTimeLabel.alpha = 0.0;
	} else {
		self.alpha = 1.0;
//		prevVideoButton.alpha = 1.0;
//		nextVideoButton.alpha = 1.0;
//		progressView.alpha = 1.0;
//		durationLabel.alpha = 1.0;
//		currentTimeLabel.alpha = 1.0;
	}
	if ( animated ) {
		[UIView commitAnimations];
	}
}

- (BOOL)controlsHidden {
	return progressView.alpha == 0.0f || self.alpha == 0.0f || self.hidden;
}

#pragma mark KVO

//- (void)observeMovieView:(NMMovieView *)mvView {
//	firstShowControlView = YES;
//	[mvView.player addObserver:self forKeyPath:@"status" options:0 context:(void *)NM_PLAYER_STATUS_CONTEXT];
//	[mvView.player addObserver:self forKeyPath:@"currentItem" options:0 context:(void *)NM_PLAYER_CURRENT_ITEM_CONTEXT];
//	[mvView.player addPeriodicTimeObserverForInterval:CMTimeMake(2, 2) queue:NULL usingBlock:^(CMTime aTime){
//		// print the time
//		CMTime t = [mvView.player currentTime];
//		self.timeElapsed = t.value / t.timescale;
//	}];
//}
//
//- (void)stopObservingMovieView:(NMMovieView *)mvView {
//	[mvView.player removeObserver:self forKeyPath:@"status"];
//	[mvView.player removeObserver:self forKeyPath:@"currentItem"];
//	[mvView.player removeTimeObserver:self];
//}
//
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	NSInteger c = (NSInteger)context;
	if ( c == 11111 ) {
		AVPlayer * player = object;
		if ( player.rate > 0.0 ) {
			// set button to play
			playPauseButton.selected = NO;
		} else {
			// set button to pause 
			playPauseButton.selected = YES;
		}
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark properties
- (void)resetView {
	channelNameLabel.text = @"";
	videoTitleLabel.text = @"";
	[authorButton setTitle:@"" forState:UIControlStateNormal];
	durationLabel.text = @"--:--";
	currentTimeLabel.text = @"--:--";
	// reset progress bar
	CGRect theFrame = progressBarLayer.bounds;
	theFrame.size.width = 18.0;
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	progressBarLayer.bounds = theFrame;
	progressBarLayer.position = CGPointMake(0.0, 9.0);
	nubLayer.position = CGPointMake(9.0, 9.0);
	[CATransaction commit];
	
	self.alpha = 1.0;
	self.hidden = NO;
	[self setControlsHidden:YES animated:NO];
}

- (void)setChannel:(NSString *)cname author:(NSString *)authName {
	[authorButton setTitle:authName forState:UIControlStateNormal];
	channelNameLabel.text = cname;
	// author label
	CGSize theSize = [authName sizeWithFont:authorButton.titleLabel.font];
	CGRect theFrame = authorButton.frame;
	theFrame.size.width = theSize.width;
	authorButton.frame = theFrame;
	// set the inbeetween "on" label position
	CGRect otherFrame = onLabel.frame;
	otherFrame.origin.x = theFrame.size.width + theFrame.origin.x;
	onLabel.frame = otherFrame;
	// set channel title
	theFrame = channelNameLabel.frame;
	theFrame.origin.x = otherFrame.origin.x + otherFrame.size.width;
	channelNameLabel.frame = theFrame;
}

- (IBAction)goToAuthorProfilePage:(id)sender {
	if ( authorProfileURLString ) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:authorProfileURLString]];
	}
}

- (void)setTitle:(NSString *)aTitle {
	videoTitleLabel.text = [aTitle uppercaseString];
}

- (void)setDuration:(NSInteger)aDur {
	duration = aDur;
	pxWidthPerSecond = progressBarWidth / aDur;
	durationLabel.text = [NSString stringWithFormat:@"%02d:%02d", aDur / 60, aDur % 60];
}

- (void)setTimeElapsed:(NSInteger)aTime {
	timeElapsed = aTime;
	CGFloat barWidth = floorf(pxWidthPerSecond * aTime) + 9.0; // 9.0 is the offset of the nub radius
	CGRect theFrame = progressBarLayer.frame;
	if ( barWidth > theFrame.size.width ) {
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
		theFrame.size.width = barWidth;
		progressBarLayer.frame = theFrame;
		nubLayer.position = CGPointMake(barWidth - 9.0, 9.0);
		[CATransaction commit];
	}
	currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", aTime / 60, aTime % 60];
	
}

- (void)setTimeRangeBuffered:(CMTimeRange)aRange {
	NSLog(@"%lld %lld", aRange.start.value / aRange.start.timescale, aRange.duration.value / aRange.duration.timescale);
}

@end
