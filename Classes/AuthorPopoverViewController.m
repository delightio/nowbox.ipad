//
//  AuthorPopoverViewController.m
//  ipad
//
//  Created by Chris Haugli on 10/25/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "AuthorPopoverViewController.h"
#import "NMTaskQueueController.h"
#import "NMVideoDetail.h"
#import "NMTaskQueueController.h"
#import "NMDataController.h"

#define kPopoverButtonWidth 172
#define kPopoverButtonHeight 38
#define kPopoverButtonPadding 5

@implementation AuthorPopoverViewController

@synthesize subscribeButton;
@synthesize watchNowButton;
@synthesize video;

- (id)initWithVideo:(NMVideo *)aVideo;
{
    self = [super init];
    if (self) {
        self.video = aVideo;

        // Are we subscribed to this video's author?
        NSString *author = video.detail.author_username;
        NSArray *subscribedChannels = [NMTaskQueueController sharedTaskQueueController].dataController.subscribedChannels;
        subscribed = ([[subscribedChannels filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"title like %@", author]] count] > 0);
    }
    
    return self;
}

- (void)dealloc
{
    [subscribeButton release];
    [watchNowButton release];
    [video release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)loadView
{
    self.subscribeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.watchNowButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [subscribeButton setBackgroundImage:[UIImage imageNamed:@"popover-button.png"] forState:UIControlStateNormal];
    [watchNowButton setBackgroundImage:[UIImage imageNamed:@"popover-button.png"] forState:UIControlStateNormal];
    
    [subscribeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [subscribeButton setTitleColor:[UIColor colorWithWhite:0.3 alpha:1.0] forState:UIControlStateDisabled];
    [watchNowButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [subscribeButton.titleLabel setFont:[UIFont boldSystemFontOfSize:16]];
    [watchNowButton.titleLabel setFont:[UIFont boldSystemFontOfSize:16]];
    
    if (subscribed) {
        [subscribeButton setTitle:@"Subscribed" forState:UIControlStateNormal];
        [subscribeButton setEnabled:NO];
    } else {
        [subscribeButton setTitle:@"Subscribe" forState:UIControlStateNormal];
    }
    
    [watchNowButton setTitle:@"Watch Now" forState:UIControlStateNormal];
    
    [subscribeButton setFrame:CGRectMake(0, 0, kPopoverButtonWidth, kPopoverButtonHeight)];
    [watchNowButton setFrame:CGRectMake(0, subscribeButton.frame.origin.y + subscribeButton.frame.size.height + kPopoverButtonPadding, kPopoverButtonWidth, kPopoverButtonHeight)];

    [subscribeButton addTarget:self action:@selector(subscribeChannel:) forControlEvents:UIControlEventTouchUpInside];
    [subscribeButton addTarget:self action:@selector(watchChannel:) forControlEvents:UIControlEventTouchUpInside];
    
    UIView *rootView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kPopoverButtonWidth, watchNowButton.frame.origin.y + watchNowButton.frame.size.height)];
    [rootView addSubview:subscribeButton];
    [rootView addSubview:watchNowButton];
    self.view = rootView;
    [rootView release];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.subscribeButton = nil;
    self.watchNowButton = nil;
}

- (void)subscribeChannel:(id)sender 
{
    NSString *author = video.detail.author_username;
    // TODO: Get channel from author
    NMChannel *channel;
    [[NMTaskQueueController sharedTaskQueueController] issueSubscribe:YES channel:channel];
}

- (void)watchChannel:(id)sender 
{
    NSString *author = video.detail.author_username;
    // TODO: Get channel from author    
    NMChannel *channel;
    if (!subscribed) {
        [[NMTaskQueueController sharedTaskQueueController] issueSubscribe:YES channel:channel];
    }
}

@end
