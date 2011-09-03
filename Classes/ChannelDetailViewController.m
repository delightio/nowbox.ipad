//
//  ChannelDetailViewController.m
//  ipad
//
//  Created by Bill So on 1/9/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "ChannelDetailViewController.h"
#import "NMStyleUtility.h"
#import <QuartzCore/QuartzCore.h>

#define NM_THUMBNAIL_PADDING		20.0f

@implementation ChannelDetailViewController
@synthesize channel;

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
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
	
	// set background color
	UIColor * bgColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"playback_background_pattern"]];
	self.view.backgroundColor = bgColor;
	// button
	[subscribeButton setBackgroundImage:[[UIImage imageNamed:@"button-gray-background"] stretchableImageWithLeftCapWidth:7 topCapHeight:0] forState:UIControlStateNormal];
	[subscribeAndWatchButton setBackgroundImage:[[UIImage imageNamed:@"button-yellow-background"] stretchableImageWithLeftCapWidth:7 topCapHeight:0] forState:UIControlStateNormal];
	[unsubscribeButton setBackgroundImage:[[UIImage imageNamed:@"button-gray-background"] stretchableImageWithLeftCapWidth:7 topCapHeight:0] forState:UIControlStateNormal];
	// listen to notification
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleDidGetDetailNotification:) name:NMDidGetChannelDetailNotification object:nil];
	[nc addObserver:self selector:@selector(handleDidFailNotification:) name:NMDidFailGetChannelDetailNotification object:nil];
	
	descriptionDefaultFrame = descriptionLabel.frame;
	
	// create the preview view
	NMCachedImageView * civ;
	CALayer * theLayer = nil;
	videoThumbnailArray = [[NSMutableArray alloc] initWithCapacity:5];
	CGFloat idxf = 0.0f;
	NMStyleUtility * style = [NMStyleUtility sharedStyleUtility];
	for (NSUInteger i = 0; i < 5; i++) {
		civ = [[NMCachedImageView alloc] initWithFrame:CGRectMake( idxf * (NM_THUMBNAIL_PADDING + 370.0f) + NM_THUMBNAIL_PADDING/2, 25.0f, 370.0f, 200.0f)];
		civ.contentMode = UIViewContentModeScaleAspectFill;
		civ.backgroundColor = style.blackColor;
		civ.clipsToBounds = YES;
		theLayer = civ.layer;
		theLayer.shadowOffset = CGSizeMake(0.0f, 0.0f);
		theLayer.shadowOpacity = 1.0f;
		theLayer.shadowRadius = 5.0f;
		theLayer.shouldRasterize = YES;
		civ.hidden = YES;
		[videoThumbnailArray addObject:civ];
		
		[thumbnailScrollView addSubview:civ];
		
		[civ release];
		idxf += 1.0f;
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    
	// setting channel attribute
    self.title = channel.title;
	titleLabel.text = channel.title;
	if ( channel.detail.nm_description ) {
		[self setDescriptionLabelText];
	} else {
		descriptionLabel.text = @"";
	}
	metricLabel.text = @"Subscribers xx,xxx,xxx";

    unsubscribeButton.enabled = YES;
    subscribeButton.enabled = YES;
    subscribeAndWatchButton.enabled = YES;
    if ([channel.nm_subscribed intValue] > 0) {
        subscribeView.alpha = 0;
        unsubscribeView.alpha = 1;
    } else {
        subscribeView.alpha = 1;
        unsubscribeView.alpha = 0;
    }
    shouldDismiss = NO;
    
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(handleWillLoadNotification:) name:NMWillSubscribeChannelNotification object:nil];
	[nc addObserver:self selector:@selector(handleWillLoadNotification:) name:NMWillUnsubscribeChannelNotification object:nil];
	[nc addObserver:self selector:@selector(handleSubscriptionNotification:) name:NMDidSubscribeChannelNotification object:nil];
	[nc addObserver:self selector:@selector(handleSubscriptionNotification:) name:NMDidUnsubscribeChannelNotification object:nil];

    
	// set preview images
//	[self setPreviewImages];
	// set channel thumbnail
	[channelThumbnailView setImageForChannel:channel];
	// load channel detail
	[[NMTaskQueueController sharedTaskQueueController] issueGetDetailForChannel:channel];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];

	// unset the view widgets
	titleLabel.text = @"";
	descriptionLabel.text = @"";
	channelThumbnailView.image = nil;
	metricLabel.text = @"";
	for (NMCachedImageView * iv in videoThumbnailArray) {
		iv.hidden = YES;
		iv.image = nil;
	}
	self.channel = nil;
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
- (void)handleDidGetDetailNotification:(NSNotification *)aNotification {
	NMChannel * targetChn = [[aNotification userInfo] objectForKey:@"channel"];
	// do not proceed if not the same channel object as the current one.
	if ( targetChn != channel ) return;
	
	[self setPreviewImages];
	if ( [descriptionLabel.text isEqualToString:@""] ) {
		[self setDescriptionLabelText];
	}
}

- (void)handleDidFailNotification:(NSNotification *)aNotification {
	
}

#pragma mark Others
- (void)setDescriptionLabelText {
	CGRect theFrame = descriptionDefaultFrame;
	theFrame.size = [channel.detail.nm_description sizeWithFont:descriptionLabel.font constrainedToSize:theFrame.size];
	descriptionLabel.frame = theFrame;
	descriptionLabel.text = channel.detail.nm_description;
}

- (void)setPreviewImages {
	NMCachedImageView * civ;
	NSUInteger i = 0;
	// load the video preview thumbnail
	NSSet * vdoThumbnails = channel.previewThumbnails;
	// order NMPreviewThumbnail objects is not important. No need to get sorted array of the items
	for (NMPreviewThumbnail * thePreview in vdoThumbnails) {
		// issue request to get preview thumbnail
		civ = [videoThumbnailArray objectAtIndex:i++];
		[civ setImageForPreviewThumbnail:thePreview];
		civ.hidden = NO;
		if ( i == 5 ) break;
	}
	for (NSUInteger j = i; j < 5; j++) {
		civ = [videoThumbnailArray objectAtIndex:j];
		// hide the rest of the image view
		civ.hidden = YES;
	}
	// configure scroll view
	if ( civ == nil ) {
		thumbnailScrollView.contentSize = CGSizeZero;
	} else {
		thumbnailScrollView.contentSize = CGSizeMake((NM_THUMBNAIL_PADDING + civ.bounds.size.width) * (CGFloat)i, thumbnailScrollView.bounds.size.height);
	}
}

-(IBAction)subscribeChannel:(id)sender {
    [UIView animateWithDuration:0.3
                     animations:^{
                         subscribeButton.enabled = NO;
                         subscribeAndWatchButton.enabled = NO;
                     }
                     completion:^(BOOL finished) {
                     }];
    [[NMTaskQueueController sharedTaskQueueController] issueSubscribe:YES channel:channel];
}

-(IBAction)subscribeAndWatchChannel:(id)sender {
    [UIView animateWithDuration:0.3
                     animations:^{
                         subscribeButton.enabled = NO;
                         subscribeAndWatchButton.enabled = NO;
                     }
                     completion:^(BOOL finished) {
                     }];
    [[NMTaskQueueController sharedTaskQueueController] issueSubscribe:YES channel:channel];
    shouldDismiss = YES;
}

-(IBAction)unsubscribeChannel:(id)sender {
    [UIView animateWithDuration:0.3
                     animations:^{
                         unsubscribeButton.enabled = NO;
                     }
                     completion:^(BOOL finished) {
                     }];
    [[NMTaskQueueController sharedTaskQueueController] issueSubscribe:NO channel:channel];
}

#pragma mark Notification handlers


- (void)handleWillLoadNotification:(NSNotification *)aNotification {
    //	NSLog(@"notification: %@", [aNotification name]);
}

- (void)handleSubscriptionNotification:(NSNotification *)aNotification {
	NSDictionary * userInfo = [aNotification userInfo];
    if (channel == [userInfo objectForKey:@"channel"]) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             if ([channel.nm_subscribed intValue] > 0) {
                                 unsubscribeButton.enabled = YES;
                                 subscribeView.alpha = 0;
                                 unsubscribeView.alpha = 1;
                             } else {
                                 shouldDismiss = NO;
                                 subscribeButton.enabled = YES;
                                 subscribeAndWatchButton.enabled = YES;
                                 subscribeView.alpha = 1;
                                 unsubscribeView.alpha = 0;
                             }
                         }
                         completion:^(BOOL finished) {
                             if (shouldDismiss) {
                                 // TODO: play the first video of the channel here
                                 [self dismissModalViewControllerAnimated:YES];
                             }
                         }];
    }
}


@end
