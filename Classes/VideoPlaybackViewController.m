//
//  VideoPlaybackViewController.m
//  Nowmov
//
//  Created by Bill So on 03/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "VideoPlaybackViewController.h"
#import "NMLibrary.h"
#import "NMVideo.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>


#define NM_PLAYER_STATUS_CONTEXT		100

@implementation VideoPlaybackViewController
@synthesize currentChannel, currentVideo;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	[[UIApplication sharedApplication] setStatusBarHidden:YES];
	self.wantsFullScreenLayout = YES;
	[[NMTaskQueueController sharedTaskQueueController] issueGetDirectURLForVideo:currentVideo];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidGetDirectURLNotification:) name:NMDidGetYouTubeDirectURLNotification object:nil];
	
	// progress view
	UIImage * img = [UIImage imageNamed:@"playback_progress_background"];
	progressView = [[UIImageView alloc] initWithImage:[img stretchableImageWithLeftCapWidth:98 topCapHeight:0]];
	CGRect theFrame = CGRectMake(0.0, 0.0, 732.0, 50.0);
	theFrame.origin.x = (1024.0 - theFrame.size.width) / 2.0;
	theFrame.origin.y = 612.0;
	progressView.frame = theFrame;
	[controlsContainerView addSubview:progressView];
	// label
	currentTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, 70.0, 50.0)];
	currentTimeLabel.backgroundColor = [UIColor clearColor];
	currentTimeLabel.font = [UIFont fontWithName:@"Futura-MediumItalic" size:20.0];
	currentTimeLabel.textAlignment = UITextAlignmentRight;
	currentTimeLabel.textColor = [UIColor grayColor];
	currentTimeLabel.shadowOffset = CGSizeMake(0.0, -1.0);
	[progressView addSubview:currentTimeLabel];
	totalDurationLabel = [[UILabel alloc] initWithFrame:CGRectMake(progressView.frame.size.width - 70.0, 0.0, 70.0, 50.0)];
	totalDurationLabel.backgroundColor = [UIColor clearColor];
	totalDurationLabel.font = [UIFont fontWithName:@"Futura-MediumItalic" size:20.0];
	totalDurationLabel.textColor = [UIColor whiteColor];
	totalDurationLabel.shadowOffset = CGSizeMake(0.0, -1.0);
	[progressView addSubview:totalDurationLabel];
	
	channelNameLabel.text = [currentChannel.channel_name capitalizedString];
	videoTitleLabel.text = [currentVideo.title uppercaseString];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[UIApplication sharedApplication] setStatusBarHidden:NO];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[infoPanelImageView release];
	[volumePanelImageView release];
	
	[progressView release];
	[player release];
	[currentVideo release];
	[currentChannel release];
    [super dealloc];
}

- (void)preparePlayer {
	
	player = [[AVQueuePlayer alloc] initWithItems:[NSArray arrayWithObject:[AVPlayerItem playerItemWithURL:[NSURL URLWithString:currentVideo.nm_direct_url]]]];
	// observe status change in player
	[player addObserver:self forKeyPath:@"status" options:0 context:(void *)NM_PLAYER_STATUS_CONTEXT];
	[player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime aTime){
		// print the time
		CMTime t = [player currentTime];
		[self setCurrentTime:t.value / t.timescale];
	}];
	AVPlayerLayer * pLayer = [AVPlayerLayer playerLayerWithPlayer:player];
	pLayer.frame = self.view.layer.bounds;
	[movieView.layer addSublayer:pLayer];
	[player play];
}

- (void)handleDidGetDirectURLNotification:(NSNotification *)aNotification {
	[self preparePlayer];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	NSInteger c = (NSInteger)context;
	if ( c == NM_PLAYER_STATUS_CONTEXT ) {
		switch (player.status) {
			case AVPlayerStatusReadyToPlay:
			{
				// the instance is ready to play. yeah!
				CMTime t = player.currentItem.asset.duration;
				[self setTotalLength:t.value / t.timescale];
				break;
			}
			default:
				break;
		}
	}
}

#pragma mark Playback progress indicator
- (void)setCurrentTime:(NSInteger)sec {
	currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", sec / 60, sec % 60];
}

- (void)setTotalLength:(NSInteger)sec {
	totalDurationLabel.text = [NSString stringWithFormat:@"%02d:%02d", sec / 60, sec % 60];
}

#pragma mark Target-action methods

- (IBAction)showTweetView:(id)sender {
	if ( infoPanelImageView == nil ) {
		UIButton * btn = (UIButton *)sender;
		UIImage * img = [UIImage imageNamed:@"info_panel"];
		CGRect theFrame;
		theFrame.size = img.size;
		theFrame.origin.y = 768.0 - img.size.height - 96.0 + 35.0;
		theFrame.origin.x = floorf(btn.frame.origin.x - ( img.size.width - btn.frame.size.width ) / 2.0);
		infoPanelImageView = [[UIImageView alloc] initWithImage:img];
		infoPanelImageView.frame = theFrame;
		[controlsContainerView addSubview:infoPanelImageView];
	} else {
		[infoPanelImageView removeFromSuperview];
		[infoPanelImageView release];
		infoPanelImageView = nil;
	}
}

- (IBAction)showVolumeControlView:(id)sender {
	if ( volumePanelImageView == nil ) {
		UIButton * btn = (UIButton *)sender;
		UIImage * img = [UIImage imageNamed:@"volume_panel"];
		CGRect theFrame;
		theFrame.size = img.size;
		theFrame.origin.y = 768.0 - img.size.height - 96.0 + 35.0;
		theFrame.origin.x = floorf(btn.frame.origin.x - ( img.size.width - btn.frame.size.width ) / 2.0);
		volumePanelImageView = [[UIImageView alloc] initWithImage:img];
		volumePanelImageView.frame = theFrame;
		[controlsContainerView addSubview:volumePanelImageView];
	} else {
		[volumePanelImageView removeFromSuperview];
		[volumePanelImageView release];
		volumePanelImageView = nil;
	}
}

- (IBAction)showShareActionView:(id)sender {
	if ( shareVideoPanelImageView == nil ) {
		UIImage * img = [UIImage imageNamed:@"twitter_share_popup"];
		CGRect theFrame;
		theFrame.size = img.size;
		theFrame.origin.x = floorf( (1024.0 - img.size.width) / 2.0 );
		theFrame.origin.y = floorf( ( 768.0 - img.size.height ) / 2.0 );
		shareVideoPanelImageView = [[UIImageView alloc] initWithImage:img];
		shareVideoPanelImageView.frame = theFrame;
		[controlsContainerView addSubview:shareVideoPanelImageView];
	} else {
		[shareVideoPanelImageView removeFromSuperview];
		[shareVideoPanelImageView release];
		shareVideoPanelImageView = nil;
	}
}

- (IBAction)backToChannelView:(id)sender {
	[player pause];
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)playStopVideo:(id)sender {
	if ( player.rate == 0.0 ) {
		[player play];
	} else {
		[player pause];
	}
}

- (IBAction)setLikeVideo:(id)sender {
	
}

- (IBAction)skipCurrentVideo:(id)sender {
	
}

@end
