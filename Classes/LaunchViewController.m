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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

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

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

- (void)showVideoView {
	ipadAppDelegate * appDelegate = (ipadAppDelegate *)[[UIApplication sharedApplication] delegate];
	[self presentModalViewController:appDelegate.viewController animated:NO];
	// always default to LIVE channel
	appDelegate.viewController.currentChannel = [NMTaskQueueController sharedTaskQueueController].dataController.liveChannel;
}

- (void)checkUpdateChannels {
	NSDate * lastDate = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:NM_CHANNEL_LAST_UPDATE];
	NMDataController * dataController = [NMTaskQueueController sharedTaskQueueController].dataController;
	if ( [lastDate timeIntervalSinceNow] < GP_CHANNEL_UPDATE_INTERVAL || // 12 hours
		[dataController emptyChannel]
		) { 
		// get channel
		[[NMTaskQueueController sharedTaskQueueController] issueGetChannels];
	}
}

- (IBAction)showPlaybackController:(id)sender {
	[self showVideoView];
}
@end
