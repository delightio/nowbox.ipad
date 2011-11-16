//
//  SearchDebugViewController.m
//  ipad
//
//  Created by Bill So on 18/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "FeatureDebugViewController.h"
#import "VideoPlaybackViewController.h"

@implementation FeatureDebugViewController
@synthesize targetChannel, selectedChannel;
@synthesize playbackViewController;

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

- (void)dealloc {
	[selectedChannel release];
	[targetChannel release];
	[playbackViewController release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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
	// notification
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleWillLoadNotification:) name:NMWillSearchChannelsNotification object:nil];
	[nc addObserver:self selector:@selector(handleDidSearchNotification:) name:NMDidSearchChannelsNotification object:nil];
	
	[nc addObserver:self selector:@selector(handleWillLoadNotification:) name:NMWillSubscribeChannelNotification object:nil];
	[nc addObserver:self selector:@selector(handleWillLoadNotification:) name:NMWillUnsubscribeChannelNotification object:nil];
	[nc addObserver:self selector:@selector(handleSubscriptionNotification:) name:NMDidSubscribeChannelNotification object:nil];
	[nc addObserver:self selector:@selector(handleSubscriptionNotification:) name:NMDidUnsubscribeChannelNotification object:nil];
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
	return YES;
}

#pragma mark Notification handlers

- (void)handleWillLoadNotification:(NSNotification *)aNotification {
	NSLog(@"notification: %@", [aNotification name]);
}

- (void)handleDidSearchNotification:(NSNotification *)aNotification {
	NSLog(@"notification: %@", [aNotification name]);
	// test out search predicate
	NSFetchRequest * request = [[NSFetchRequest alloc] init];
	NMDataController * dataCtrl = [NMTaskQueueController sharedTaskQueueController].dataController;
	[request setEntity:[NSEntityDescription entityForName:NMChannelEntityName inManagedObjectContext:dataCtrl.managedObjectContext]];
	[request setPredicate:dataCtrl.searchResultsPredicate];
	NSArray * result = [dataCtrl.managedObjectContext executeFetchRequest:request error:nil];
	NSLog(@"search result %@", result);
	[request release];
}

- (void)handleSubscriptionNotification:(NSNotification *)aNotification {
	NSString * notName = [aNotification name];
	NSDictionary * userInfo = [aNotification userInfo];
	if ( [notName isEqualToString:NMDidUnsubscribeChannelNotification] ) {
		self.targetChannel = [userInfo objectForKey:@"channel"];
		NSLog(@"unsubscribed channel: %@", targetChannel.title);
	} else if ( [notName isEqualToString:NMDidSubscribeChannelNotification] ) {
		self.targetChannel = [userInfo objectForKey:@"channel"];
		NSLog(@"subscribed channel: %@", targetChannel.title);
		self.targetChannel = nil;
	}
}

- (void)handleGetChannelNotification:(NSNotification *)aNotification {
	NSString * notName = [aNotification name];
	if ( [notName isEqualToString:NMDidGetChannelsNotification] ) {
		// check if we have deleted any channel
		NSDictionary * info = [aNotification userInfo];
		NSLog(@"channel update status: %@", info);
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self name:notName object:nil];
}

- (void)handleCheckUpdateNotification:(NSNotification *)aNotification {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NMDidCheckUpdateNotification object:nil];
	NSLog(@"version dict: %@", [aNotification userInfo]);
}

- (void)handleDidGetFeaturedChannels:(NSNotification *)aNotification {
	NSArray * ay = [[aNotification userInfo] objectForKey:@"channels"];
	[[NMTaskQueueController sharedTaskQueueController] issueSubscribeChannels:ay];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NMDidGetFeaturedChannelsForCategories object:nil];
}

- (void)handleChannelCompareNotification:(NSNotification *)aNotification {
	NSSet * chns = [NMTaskQueueController sharedTaskQueueController].dataController.internalYouTubeCategory.channels;
	for (NMChannel * chnObj in chns) {
		NSLog(@"%@", chnObj);
	}
}

#pragma mark Target action methods

- (IBAction)resetTooltip:(id)sender {
	[[ToolTipController sharedToolTipController] resetTooltips];
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Tooltips have been reset." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
}

- (IBAction)getDebugChannel:(id)sender {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGetChannelNotification:) name:NMDidGetChannelWithIDNotification object:nil];
	// get debug channel
	[[NMTaskQueueController sharedTaskQueueController] issueGetChannelWithID:2513];
}

- (IBAction)checkUpdate:(id)sender {
	[[NMTaskQueueController sharedTaskQueueController] issueCheckUpdateForDevice:@"ipad"];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCheckUpdateNotification:) name:NMDidCheckUpdateNotification object:nil];
}

- (IBAction)bulkSubscibe:(id)sender {
	NMTaskQueueController * tqc = [NMTaskQueueController sharedTaskQueueController];
	NSArray * cat = tqc.dataController.categories;
	// subscribe to a few channels
	[tqc issueGetFeaturedChannelsForCategories:[NSArray arrayWithObjects:[cat objectAtIndex:8], [cat objectAtIndex:9], nil]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidGetFeaturedChannels:) name:NMDidGetFeaturedChannelsForCategories object:nil];
}

- (IBAction)renewToken:(id)sender {
	NMTaskQueueController * tqc = [NMTaskQueueController sharedTaskQueueController];
	[tqc issueRenewToken];
}

- (IBAction)checkTokenExpiryAndRenew:(id)sender {
	NMTaskQueueController * tqc = [NMTaskQueueController sharedTaskQueueController];
	[tqc issueTokenTest];
}

- (IBAction)pollUserYouTube:(id)sender {
	NMTaskQueueController * tqc = [NMTaskQueueController sharedTaskQueueController];
	[tqc pollServerForYouTubeSyncSignal];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleChannelCompareNotification:) name:NMDidCompareSubscribedChannelsNotification object:nil];
}

- (IBAction)getSubscribedChannels:(id)sender {
	[[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGetChannelNotification:) name:NMDidGetChannelsNotification object:nil];
}

@end
