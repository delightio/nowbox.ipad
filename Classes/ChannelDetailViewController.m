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
#import "ChannelPreviewView.h"
#import "Analytics.h"

#define NM_THUMBNAIL_PADDING		20.0f

@implementation ChannelDetailViewController
@synthesize channel, enableUnsubscribe;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        countFormatter = [[NSNumberFormatter alloc] init];
        [countFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
        [countFormatter setRoundingIncrement:[NSNumber numberWithInteger:1000]];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [previewViewsArray removeAllObjects];
    [previewViewsArray release];
    [countFormatter release];
	[super dealloc];
}

- (void)configureView {
    [self setPreviewImages];
	if ( [descriptionLabel.text isEqualToString:@""] ) {
		[self setDescriptionLabelText];
	}
    
    if ([channel.nm_subscribed intValue] <= 0) {
        // Not subscribed
        NSArray *vdoThumbnails = [[NMTaskQueueController sharedTaskQueueController].dataController previewsForChannel:channel];
        [UIView animateWithDuration:0.25f 
						 animations:^{
                             if ([channel.populated_at timeIntervalSince1970] <= 0 && [vdoThumbnails count] == 0) {
                                 // Not populated
                                 unpopulatedMessageView.alpha = 1;
                                 subscribeView.alpha = 0;
                                 unsubscribeView.alpha = 0;            
                             } else {
                                 // Populated
                                 unpopulatedMessageView.alpha = 0;
                                 subscribeView.alpha = 1;
                                 unsubscribeView.alpha = 0; 
                             }
                         }];
    }
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	
    containerView.layer.cornerRadius = 4;

	// set background color
	UIColor * bgColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"playback_background_pattern"]];
	containerView.backgroundColor = bgColor;
	// button
	[subscribeButton setBackgroundImage:[[UIImage imageNamed:@"button-gray-background"] stretchableImageWithLeftCapWidth:7 topCapHeight:0] forState:UIControlStateNormal];
	[subscribeUnpopulatedButton setBackgroundImage:[[UIImage imageNamed:@"button-yellow-background"] stretchableImageWithLeftCapWidth:7 topCapHeight:0] forState:UIControlStateNormal];
	[subscribeAndWatchButton setBackgroundImage:[[UIImage imageNamed:@"button-yellow-background"] stretchableImageWithLeftCapWidth:7 topCapHeight:0] forState:UIControlStateNormal];
	[unsubscribeButton setBackgroundImage:[[UIImage imageNamed:@"button-red-background"] stretchableImageWithLeftCapWidth:7 topCapHeight:0] forState:UIControlStateNormal];
	// listen to notification
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleDidGetDetailNotification:) name:NMDidGetChannelDetailNotification object:nil];
	[nc addObserver:self selector:@selector(handleDidFailNotification:) name:NMDidFailGetChannelDetailNotification object:nil];
	[nc addObserver:self selector:@selector(handleDidGetChannelVideoListNotification:) name:NMDidGetChannelVideoListNotification object:nil];
	
	descriptionDefaultFrame = descriptionLabel.frame;
	
	// create the preview view
	previewViewsArray = [[NSMutableArray alloc] initWithCapacity:5];
	CGFloat idxf = 0.0f;
	for (NSUInteger i = 0; i < 5; i++) {
        
        ChannelPreviewView *previewView = [[ChannelPreviewView alloc] initWithFrame:CGRectMake( idxf * (NM_THUMBNAIL_PADDING + 370.0f) + NM_THUMBNAIL_PADDING/2, 25.0f, 370.0f, 200.0f)];
        
		[previewViewsArray addObject:previewView];
        [thumbnailScrollView addSubview:previewView];

        [previewView release];
        
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

    // round the subscribers count to nearest thousand, don't if not subscribers
    NSInteger subCount = [channel.subscriber_count integerValue];
    if ( subCount > 1000 ) {
        metricLabel.text = [NSString stringWithFormat:@"%@ videos, %@ subscribers", channel.video_count, [countFormatter stringFromNumber:channel.subscriber_count]];
    } else if ( subCount == 0 ) {
        metricLabel.text = [NSString stringWithFormat:@"%@ videos", channel.video_count];
    } else {
        metricLabel.text = [NSString stringWithFormat:@"%@ videos, %@ subscribers", channel.video_count, channel.subscriber_count];
    }
    
    unsubscribeButton.enabled = YES;
    subscribeButton.enabled = YES;
    subscribeUnpopulatedButton.enabled = YES;
    subscribeAndWatchButton.enabled = YES;
    
    if ([channel.nm_subscribed intValue] > 0) {
        unpopulatedMessageView.alpha = 0;
        subscribeView.alpha = 0;
        unsubscribeView.alpha = 1;
    } else {
        // If unsubscribe, delay until handleDidGetDetailNotification where we'll know if it's populated or not
        unpopulatedMessageView.alpha = 0;
        subscribeView.alpha = 0;
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
    NMTaskQueueController *taskQueueController = [NMTaskQueueController sharedTaskQueueController];
    if ([channel.nm_id integerValue] == 0) {
        [self configureView];
    } else {
        [taskQueueController issueGetDetailForChannel:channel];
    }

    BOOL social = (channel == taskQueueController.dataController.userFacebookStreamChannel 
                   || channel == taskQueueController.dataController.userTwitterStreamChannel); 
    [[MixpanelAPI sharedAPI] track:AnalyticsEventShowChannelDetails properties:[NSDictionary dictionaryWithObjectsAndKeys:channel.title, AnalyticsPropertyChannelName, 
                                                                                [NSNumber numberWithBool:social], AnalyticsPropertySocialChannel, nil]];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [thumbnailScrollView setContentOffset:CGPointMake(0, 0)];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];

	// unset the view widgets
	titleLabel.text = @"";
	descriptionLabel.text = @"";
	channelThumbnailView.image = nil;
	metricLabel.text = @"";
	for (ChannelPreviewView * cpv in previewViewsArray) {
        [cpv clearPreviewImage];
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
    [self configureView];
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
//	NMCachedImageView * civ;
    ChannelPreviewView *cpv;
	NSUInteger i = 0;
	// load the video preview thumbnail
	NSArray * vdoThumbnails = [[NMTaskQueueController sharedTaskQueueController].dataController previewsForChannel:channel];
	// order NMPreviewThumbnail objects is not important. No need to get sorted array of the items
	for (NMPreviewThumbnail * thePreview in vdoThumbnails) {
		// issue request to get preview thumbnail
        cpv = (ChannelPreviewView *)[previewViewsArray objectAtIndex:i++];
        [cpv setPreviewImage:thePreview];
        [cpv setHidden:NO];
//		civ = [(ChannelPreviewView *)[previewViewsArray objectAtIndex:i++] civ];
//		[civ setImageForPreviewThumbnail:thePreview];
//		civ.hidden = NO;
		if ( i == 5 ) break;
	}
	for (NSUInteger j = i; j < 5; j++) {
        cpv = (ChannelPreviewView *)[previewViewsArray objectAtIndex:i++];
		// hide the rest of the image view
        [cpv setHidden:YES];
//		civ = [(ChannelPreviewView *)[previewViewsArray objectAtIndex:j] civ];
//		// hide the rest of the image view
//		civ.hidden = YES;
	}
	// configure scroll view
	if ( cpv == nil ) {
		thumbnailScrollView.contentSize = CGSizeZero;
	} else {
		thumbnailScrollView.contentSize = CGSizeMake((NM_THUMBNAIL_PADDING + cpv.bounds.size.width) * (CGFloat)i, thumbnailScrollView.bounds.size.height);
	}
}

-(IBAction)subscribeChannel:(id)sender {
    [UIView animateWithDuration:0.25f
                     animations:^{
                         subscribeButton.enabled = NO;
                         subscribeAndWatchButton.enabled = NO;
                         subscribeUnpopulatedButton.enabled = NO;
                     }
                     completion:^(BOOL finished) {
                     }];
    
    NMTaskQueueController *taskQueueController = [NMTaskQueueController sharedTaskQueueController];
    [taskQueueController issueSubscribe:YES channel:channel];
    
    BOOL social = (channel == taskQueueController.dataController.userFacebookStreamChannel 
                   || channel == taskQueueController.dataController.userTwitterStreamChannel); 
    [[MixpanelAPI sharedAPI] track:AnalyticsEventSubscribeChannel properties:[NSDictionary dictionaryWithObjectsAndKeys:channel.title, AnalyticsPropertyChannelName,
                                                                              @"channeldetails_subscribe", AnalyticsPropertySender, 
                                                                              [NSNumber numberWithBool:social], AnalyticsPropertySocialChannel, nil]];
}

-(IBAction)subscribeAndWatchChannel:(id)sender {
    [UIView animateWithDuration:0.25f
                     animations:^{
                         subscribeButton.enabled = NO;
                         subscribeAndWatchButton.enabled = NO;
                         subscribeUnpopulatedButton.enabled = NO;
                     }
                     completion:^(BOOL finished) {
                     }];
    
    NMTaskQueueController *taskQueueController = [NMTaskQueueController sharedTaskQueueController];
    [taskQueueController issueSubscribe:YES channel:channel];
    shouldDismiss = YES;
    
    BOOL social = (channel == taskQueueController.dataController.userFacebookStreamChannel 
                   || channel == taskQueueController.dataController.userTwitterStreamChannel); 
    [[MixpanelAPI sharedAPI] track:AnalyticsEventSubscribeChannel properties:[NSDictionary dictionaryWithObjectsAndKeys:channel.title, AnalyticsPropertyChannelName,
                                                                              @"channeldetails_watchnow", AnalyticsPropertySender, 
                                                                              [NSNumber numberWithBool:social], AnalyticsPropertySocialChannel, nil]];
}

-(IBAction)unsubscribeChannel:(id)sender {
	if ( !enableUnsubscribe ) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"NOWBOX requires channel subscription to function. We are keeping this channel subscribed for you." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alertView show];
		[alertView release];
		return;
	}
    [UIView animateWithDuration:0.25f
                     animations:^{
                         unsubscribeButton.enabled = NO;
                     }
                     completion:^(BOOL finished) {
                     }];
    
    NMTaskQueueController *taskQueueController = [NMTaskQueueController sharedTaskQueueController];
    [taskQueueController issueSubscribe:NO channel:channel];
    
    BOOL social = (channel == taskQueueController.dataController.userFacebookStreamChannel 
                || channel == taskQueueController.dataController.userTwitterStreamChannel); 
    [[MixpanelAPI sharedAPI] track:AnalyticsEventUnsubscribeChannel properties:[NSDictionary dictionaryWithObjectsAndKeys:channel.title, AnalyticsPropertyChannelName,
                                                                                @"channeldetails_unsubscribe", AnalyticsPropertySender, 
                                                                                [NSNumber numberWithBool:social], AnalyticsPropertySocialChannel, nil]];

}

#pragma mark Notification handlers


- (void)handleWillLoadNotification:(NSNotification *)aNotification {
    //	NSLog(@"notification: %@", [aNotification name]);
}

- (void)handleSubscriptionNotification:(NSNotification *)aNotification {
	NSDictionary * userInfo = [aNotification userInfo];
    
    if (channel == [userInfo objectForKey:@"channel"]) {
        NSArray *vdoThumbnails = [[NMTaskQueueController sharedTaskQueueController].dataController previewsForChannel:channel];
        [UIView animateWithDuration:0.25f 
						 animations:^{
							 if ([channel.nm_subscribed intValue] > 0) {
                                 unsubscribeButton.enabled = YES;
                                 subscribeView.alpha = 0;
                                 unsubscribeView.alpha = 1;
                                 unpopulatedMessageView.alpha = 0;  
                             } else {
                                 shouldDismiss = NO;
                                 subscribeButton.enabled = YES;
                                 subscribeAndWatchButton.enabled = YES;
                                 subscribeUnpopulatedButton.enabled = YES;
                                 
                                 if ([channel.populated_at timeIntervalSince1970] <= 0 && [vdoThumbnails count] == 0) {
                                     // Not populated
                                     unpopulatedMessageView.alpha = 1;
                                     subscribeView.alpha = 0;
                                     unsubscribeView.alpha = 0;            
                                 } else {
                                     // Populated
                                     unpopulatedMessageView.alpha = 0;
                                     subscribeView.alpha = 1;
                                     unsubscribeView.alpha = 0; 
                                 }                        
                             }
                         }
                         completion:^(BOOL finished) {
							 if ( [channel.type integerValue] == NMChannelUserTwitterType || [channel.type integerValue] == NMChannelUserFacebookType ) {
								 [self.navigationController popViewControllerAnimated:YES];
							 } else if ( shouldDismiss && [[NMTaskQueueController sharedTaskQueueController].dataController channelContainsVideo:channel] ) {
								 [[NSNotificationCenter defaultCenter] postNotificationName:NMShouldPlayNewlySubscribedChannelNotification object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:channel, @"channel", nil]];
								 [self dismissModalViewControllerAnimated:YES];
                             }
                         }];
    }
}

- (void)handleDidGetChannelVideoListNotification:(NSNotification *)aNotification {
    if (!shouldDismiss) {
        return;
    }
	NSDictionary * info = [aNotification userInfo];
    if ( [[info objectForKey:@"channel"] isEqual:channel] ) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NMShouldPlayNewlySubscribedChannelNotification object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:channel, @"channel", nil]];
        [self dismissModalViewControllerAnimated:YES];
    }
}



@end
