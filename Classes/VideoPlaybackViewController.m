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
	AVPlayerLayer * pLayer = [AVPlayerLayer playerLayerWithPlayer:player];
	pLayer.frame = self.view.layer.bounds;
	[movieView.layer addSublayer:pLayer];
	[player play];
}

- (void)handleDidGetDirectURLNotification:(NSNotification *)aNotification {
	[self preparePlayer];
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
	
}

- (IBAction)backToChannelView:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)playStopVideo:(id)sender {
	
}

- (IBAction)setLikeVideo:(id)sender {
	
}

- (IBAction)skipCurrentVideo:(id)sender {
	
}

@end
