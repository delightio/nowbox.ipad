//
//  LaunchViewController.m
//  ipad
//
//  Created by Bill So on 6/13/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "LaunchViewController.h"
#import "NMLibrary.h"
#import "ipadAppDelegate.h"
#import "VideoPlaybackViewController.h"


#define GP_CHANNEL_UPDATE_INTERVAL	-12.0 * 3600.0

@implementation LaunchViewController

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleDidGetChannelNotification:) name:NMDidGetChannelsNotification object:nil];
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NM_USER_ACCOUNT_ID = [userDefaults integerForKey:NM_USER_ACCOUNT_ID_KEY];
	NM_USE_HIGH_QUALITY_VIDEO = [userDefaults boolForKey:NM_USE_HIGH_QUALITY_VIDEO_KEY];
	appFirstLaunch = [userDefaults boolForKey:NM_FIRST_LAUNCH_KEY];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if ( appFirstLaunch ) {
		debugLabel.text = @"Setting up new user...";
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidCreateUserNotification:) name:NMDidCreateUserNotification object:nil];
		// create new user
		[[NMTaskQueueController sharedTaskQueueController] issueCreateUser];
	} else {
		[self checkUpdateChannels];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

//- (void)showVideoView {
//	ipadAppDelegate * appDelegate = (ipadAppDelegate *)[[UIApplication sharedApplication] delegate];
//	[self presentModalViewController:appDelegate.viewController animated:NO];
//	// always default to LIVE channel
//	appDelegate.viewController.currentChannel = [NMTaskQueueController sharedTaskQueueController].dataController.trendingChannel;
//}

- (void)showVideoViewAnimated {
	ipadAppDelegate * appDelegate = (ipadAppDelegate *)[[UIApplication sharedApplication] delegate];
	appDelegate.viewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	[self presentModalViewController:appDelegate.viewController animated:YES];
	// continue channel of the last session
	// If last session is not available, data controller will return the first channel user subscribed. VideoPlaybackModelController will decide to load video of the last session of the selected channel
	appDelegate.viewController.currentChannel = [NMTaskQueueController sharedTaskQueueController].dataController.lastSessionChannel;
	
	// set first launch to NO
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:NM_FIRST_LAUNCH_KEY];
}

- (void)checkUpdateChannels {
	NSUserDefaults * df = [NSUserDefaults standardUserDefaults];

	NSDate * lastDate = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:NM_CHANNEL_LAST_UPDATE];
	if ( appFirstLaunch || 
		[lastDate timeIntervalSinceNow] < GP_CHANNEL_UPDATE_INTERVAL // 12 hours
		) { 
		// get channel
		[[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
		debugLabel.text = @"Fetching channels...";
	} else {
		[self performSelector:@selector(showVideoViewAnimated) withObject:nil afterDelay:0.5];
		NSInteger sid = [df integerForKey:NM_SESSION_ID_KEY] + 1;
		[[NMTaskQueueController sharedTaskQueueController] beginNewSession:sid];
		[df setInteger:sid forKey:NM_SESSION_ID_KEY];
	}
}

#pragma mark Notification
- (void)handleDidCreateUserNotification:(NSNotification *)aNotification {
	[[NSUserDefaults standardUserDefaults] setInteger:NM_USER_ACCOUNT_ID forKey:NM_USER_ACCOUNT_ID_KEY];
	NSLog(@"Created new user: %d", NM_USER_ACCOUNT_ID);
	// new user created, get channel
	[self checkUpdateChannels];
}

- (void)handleDidGetChannelNotification:(NSNotification *)aNotification {
	debugLabel.text = @"Ready to go...";
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:NM_CHANNEL_LAST_UPDATE];
	[self performSelector:@selector(showVideoViewAnimated) withObject:nil afterDelay:0.5];
	// begin new session
	NSUserDefaults * df = [NSUserDefaults standardUserDefaults];
	NSInteger sid = [df integerForKey:NM_SESSION_ID_KEY] + 1;
	[[NMTaskQueueController sharedTaskQueueController] beginNewSession:sid];
	[df setInteger:sid forKey:NM_SESSION_ID_KEY];
}

@end
