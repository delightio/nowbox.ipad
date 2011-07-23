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


#define GP_CHANNEL_UPDATE_INTERVAL	-12.0f * 3600.0f

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
	
	if ( NM_USER_ACCOUNT_ID ) {
		userIDTextField.text = [NSString stringWithFormat:@"%d", NM_USER_ACCOUNT_ID];
	}
	NM_USE_HIGH_QUALITY_VIDEO = [userDefaults boolForKey:NM_USE_HIGH_QUALITY_VIDEO_KEY];
	hqSwitch.on = NM_USE_HIGH_QUALITY_VIDEO;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)showVideoView {
	ipadAppDelegate * appDelegate = (ipadAppDelegate *)[[UIApplication sharedApplication] delegate];
	[self presentModalViewController:appDelegate.viewController animated:NO];
	// always default to LIVE channel
	appDelegate.viewController.currentChannel = [NMTaskQueueController sharedTaskQueueController].dataController.trendingChannel;
}

- (void)showVideoViewAnimated {
	ipadAppDelegate * appDelegate = (ipadAppDelegate *)[[UIApplication sharedApplication] delegate];
	appDelegate.viewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	[self presentModalViewController:appDelegate.viewController animated:YES];
	// always default to LIVE channel
	appDelegate.viewController.currentChannel = [NMTaskQueueController sharedTaskQueueController].dataController.trendingChannel;
}

- (void)checkUpdateChannels {
	NSDate * lastDate = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:NM_CHANNEL_LAST_UPDATE];
	NMDataController * dataController = [NMTaskQueueController sharedTaskQueueController].dataController;
	if ( [lastDate timeIntervalSinceNow] < GP_CHANNEL_UPDATE_INTERVAL || // 12 hours
		[dataController emptyChannel] ) { 
		// get channel
		[[NMTaskQueueController sharedTaskQueueController] issueGetChannels];
		debugLabel.text = @"Fetching channels...";
	} else {
		[self performSelector:@selector(showVideoViewAnimated) withObject:nil afterDelay:0.5];
	}
}

#pragma mark Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	// start grabbing user's channel when the user has entered an ID
	NSInteger uid = [textField.text integerValue];
	if ( uid ) {
		// save the user id
		[[NSUserDefaults standardUserDefaults] setInteger:uid forKey:NM_USER_ACCOUNT_ID_KEY];
		[[NSUserDefaults standardUserDefaults] synchronize];
		NM_USER_ACCOUNT_ID = uid;
		// start fetching
		[self checkUpdateChannels];
	} else {
		UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil message:@"Wrong user ID" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
	[textField resignFirstResponder];
	return YES;
}

#pragma mark Notification
- (void)handleDidGetChannelNotification:(NSNotification *)aNotification {
//	NSDictionary * userInfo = [aNotification userInfo];
//	debugLabel.text = [debugLabel.text stringByAppendingFormat:@"\ntype %@", [userInfo objectForKey:@"type"]];
	debugLabel.text = @"Ready to go...";
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:NM_CHANNEL_LAST_UPDATE];
	[self performSelector:@selector(showVideoViewAnimated) withObject:nil afterDelay:0.5];
	// fetch other channels
	
}

#pragma mark Target action methods
- (IBAction)showPlaybackController:(id)sender {
	[self showVideoView];
}

- (IBAction)goToPlaybackView:(id)sender {
	[self textFieldShouldReturn:userIDTextField];
}

- (IBAction)setVideoQuality:(id)sender {
	[[NSUserDefaults standardUserDefaults] setBool:hqSwitch.on forKey:NM_USE_HIGH_QUALITY_VIDEO_KEY];
	NM_USE_HIGH_QUALITY_VIDEO = hqSwitch.on;
}

@end
