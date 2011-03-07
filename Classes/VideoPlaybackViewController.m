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
- (IBAction)closeView:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

@end
