//
//  NMControlsView.m
//  Nowmov
//
//  Created by Bill So on 11/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMControlsView.h"


@implementation NMControlsView

@synthesize title, duration, timeElapsed, authorProfileURLString;

- (void)awakeFromNib {
	// load the progress bar image
	UIImage * img = [UIImage imageNamed:@"playback_progress_background"];
	progressView = [[UIImageView alloc] initWithImage:[img stretchableImageWithLeftCapWidth:98 topCapHeight:0]];
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
		prevVideoButton.alpha = 0.0;
		nextVideoButton.alpha = 0.0;
		progressView.alpha = 0.0;
		durationLabel.alpha = 0.0;
		currentTimeLabel.alpha = 0.0;
	} else {
		prevVideoButton.alpha = 1.0;
		nextVideoButton.alpha = 1.0;
		progressView.alpha = 1.0;
		durationLabel.alpha = 1.0;
		currentTimeLabel.alpha = 1.0;
	}
	if ( animated ) {
		[UIView commitAnimations];
	}
}

#pragma mark properties
- (void)resetProgressView {
	durationLabel.text = @"--:--";
	currentTimeLabel.text = @"--:--";
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
	videoTitleLabel.text = aTitle;
}

- (void)setDuration:(NSInteger)aDur {
	durationLabel.text = [NSString stringWithFormat:@"%02d:%02d", aDur / 60, aDur % 60];
}

- (void)setTimeElapsed:(NSInteger)aTime {
	currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", aTime / 60, aTime % 60];
}

@end
