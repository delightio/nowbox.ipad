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

#pragma mark Target action methods

- (IBAction)submitSearch:(id)sender {
	NMTaskQueueController * ctrl = [NMTaskQueueController sharedTaskQueueController];
	[ctrl.dataController clearSearchResultCache];
	[ctrl issueChannelSearchForKeyword:@"comedy"];
}

- (IBAction)submitSubscribeChannel:(id)sender {
	if ( targetChannel ) {
		[[NMTaskQueueController sharedTaskQueueController] issueSubscribe:YES channel:targetChannel];
	}
}

- (IBAction)submitUnsubscribeChannel:(id)sender {
	// unsubscribe a channel
	NMTaskQueueController * queueCtrl = [NMTaskQueueController sharedTaskQueueController];
	NSArray * results = queueCtrl.dataController.subscribedChannels;
	if ( [results count] ) {
		NMChannel * chnObj = [results objectAtIndex:0];
		[queueCtrl issueSubscribe:NO channel:chnObj];
	}
}

- (IBAction)getCurrentSubscription:(id)sender {
	NMTaskQueueController * queueCtrl = [NMTaskQueueController sharedTaskQueueController];
	NSArray * results = queueCtrl.dataController.subscribedChannels;
	NSLog(@"Subscription List:");
	for (NMChannel * chnObj in results) {
		NSLog(@"%@", chnObj.title);
	}
}

- (IBAction)fetchMoreVideoForCurrentChannel:(id)sender {
	[[NMTaskQueueController sharedTaskQueueController] issueGetMoreVideoForChannel:selectedChannel];
}

- (IBAction)debugPlaybackQueue:(id)sender {
	NMAVQueuePlayer * qPlayer = [playbackViewController getQueuePlayer];
	NSArray * itemsAy = qPlayer.items;
	NSLog(@"num video in queue: %d", [itemsAy count]);
	for (NMAVPlayerItem * item in itemsAy) {
		NSLog(@"\t%@", item.nmVideo.title);
	}
}

@end
