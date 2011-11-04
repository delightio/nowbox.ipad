//
//  OnBoardProcessViewController.m
//  ipad
//
//  Created by Chris Haugli on 11/2/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "OnBoardProcessViewController.h"
#import "OnBoardProcessChannelView.h"
#import "NMTaskQueueController.h"
#import "NMDataController.h"
#import "NMDataType.h"
#import "NMCategory.h"
#import "NMChannel.h"

#define kCategoryGridNumberOfColumns 2
#define kCategoryGridItemHeight 50
#define kCategoryGridItemPadding 10
#define kChannelGridNumberOfRows 4
#define kChannelGridNumberOfColumns 3
#define kChannelGridItemHorizontalSpacing 300
#define kChannelGridItemPadding 10

@implementation OnBoardProcessViewController

@synthesize loginView;
@synthesize categoriesView;
@synthesize infoView;
@synthesize proceedToChannelsButton;
@synthesize channelsView;
@synthesize channelsScrollView;
@synthesize featuredCategories;
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        selectedCategoryIndexes = [[NSMutableIndexSet alloc] init];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(handleDidCreateUserNotification:) name:NMDidCreateUserNotification object:nil];
		[nc addObserver:self selector:@selector(handleLaunchFailNotification:) name:NMDidFailCreateUserNotification object:nil];
        [nc addObserver:self selector:@selector(handleDidGetFeaturedChannelsNotification:) name:NMDidGetFeaturedChannelsForCategories object:nil];
		[nc addObserver:self selector:@selector(handleLaunchFailNotification:) name:NMDidFailGetFeaturedChannelsForCategories object:nil];
        [nc addObserver:self selector:@selector(handleDidSubscribeNotification:) name:NMDidSubscribeChannelNotification object:nil];
        [nc addObserver:self selector:@selector(handleLaunchFailNotification:) name:NMDidFailSubscribeChannelNotification object:nil];
        [nc addObserver:self selector:@selector(handleDidGetChannelsNotification:) name:NMDidGetChannelsNotification object:nil];
        [nc addObserver:self selector:@selector(handleLaunchFailNotification:) name:NMDidFailGetChannelsNotification object:nil];
		[nc addObserver:self selector:@selector(handleLaunchFailNotification:) name:NMDidFailGetChannelVideoListNotification object:nil];        
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [selectedCategoryIndexes release];
    [subscribingChannels release];
    [loginView release];
    [categoriesView release];
    [infoView release];
    [proceedToChannelsButton release];    
    [channelsView release];
    [channelsScrollView release];
    [featuredCategories release];
    
    [super dealloc];
}

- (void)transitionFromView:(UIView *)view1 toView:(UIView *)view2
{
    view2.frame = CGRectOffset(self.view.bounds, self.view.bounds.size.width, 0);
    [self.view addSubview:view2];
    
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         view1.frame = CGRectOffset(view1.frame, -self.view.bounds.size.width, 0);
                         view2.frame = CGRectOffset(view2.frame, -self.view.bounds.size.width, 0);
                     }
                     completion:^(BOOL finished){
                         [view1 removeFromSuperview];                         
                     }];    
}

- (void)subscribeToSelectedCategories
{
    [[NMTaskQueueController sharedTaskQueueController] issueGetFeaturedChannelsForCategories:[featuredCategories objectsAtIndexes:selectedCategoryIndexes]];
}

- (void)notifyVideosReady
{
    // Allow the user to proceed past the info step
    [proceedToChannelsButton setTitle:@"Next" forState:UIControlStateNormal];
    proceedToChannelsButton.enabled = YES;
}

#pragma mark - Actions

- (void)categoryButtonPressed:(id)sender
{
    UIButton *categoryButton = (UIButton *)sender;
    NSInteger categoryIndex = [categoryButton tag];
    if ([selectedCategoryIndexes containsIndex:categoryIndex]) {
        [categoryButton setBackgroundImage:[[UIImage imageNamed:@"button-gray-background"] stretchableImageWithLeftCapWidth:7 topCapHeight:0] forState:UIControlStateNormal];
        [categoryButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];        
        [selectedCategoryIndexes removeIndex:categoryIndex];
    } else {
        [categoryButton setBackgroundImage:[[UIImage imageNamed:@"button-red-background"] stretchableImageWithLeftCapWidth:7 topCapHeight:0] forState:UIControlStateNormal];
        [categoryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [selectedCategoryIndexes addIndex:categoryIndex];
    }
}

- (IBAction)switchToInfoView:(id)sender
{
    [self transitionFromView:loginView toView:infoView];
    currentView = infoView;
    
    if (userCreated) {
        if ([selectedCategoryIndexes count] == 0) {
            // Didn't select any categories, skip the subscribe step
            [[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
        } else {
            [self subscribeToSelectedCategories];
        }
    }
}

- (IBAction)switchToChannelsView:(id)sender
{
    [self transitionFromView:infoView toView:channelsView];
    currentView = channelsView;
}

- (IBAction)switchToPlaybackView:(id)sender
{
    [delegate onBoardProcessViewControllerDidFinish:self];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"playback_background_pattern"]];
    loginView.backgroundColor = [UIColor clearColor];
    infoView.backgroundColor = [UIColor clearColor];
    channelsView.backgroundColor = [UIColor clearColor];
    
    // Sort the categories by name
    NSArray *categories = [[[NMTaskQueueController sharedTaskQueueController] dataController] categories];
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    self.featuredCategories = [categories sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter]];
    [sorter release];
    
    // Now we can populate the featured category list
    CGFloat itemWidth = (categoriesView.frame.size.width - (kCategoryGridNumberOfColumns - 1) * kCategoryGridItemPadding) / kCategoryGridNumberOfColumns;
    
    NSUInteger row = 0, col = 0;
    for (NMCategory *category in featuredCategories) {
        UIButton *categoryButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        categoryButton.frame = CGRectMake(col * (itemWidth + kCategoryGridItemPadding), row * (kCategoryGridItemHeight + kCategoryGridItemPadding),
                                          itemWidth, kCategoryGridItemHeight);
        [categoryButton setTitle:category.title forState:UIControlStateNormal];
        [categoryButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [categoryButton setBackgroundImage:[[UIImage imageNamed:@"button-gray-background"] stretchableImageWithLeftCapWidth:7 topCapHeight:0] forState:UIControlStateNormal];
        [categoryButton setTag:row*kCategoryGridNumberOfColumns + col];
        [categoryButton addTarget:self action:@selector(categoryButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [categoriesView addSubview:categoryButton];
        
        col++;
        if (col >= kCategoryGridNumberOfColumns) {
            row++;            
            col = 0;
        }
    }
    
    // Show the login page to start
    [loginView setFrame:self.view.bounds];
    [self.view addSubview:loginView];    
    currentView = loginView;
    
    [[NMTaskQueueController sharedTaskQueueController] issueCreateUser];
}

- (void)viewDidUnload
{
    self.loginView = nil;
    self.categoriesView = nil;
    self.infoView = nil;
    self.channelsView = nil;
    self.channelsScrollView = nil;
    self.featuredCategories = nil;
    self.proceedToChannelsButton = nil;
    
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - Notifications

- (void)handleDidCreateUserNotification:(NSNotification *)aNotification 
{
    userCreated = YES;
    if (currentView == infoView) {
        // We were waiting on this call to finish
        if ([selectedCategoryIndexes count] == 0) {
            // Didn't select any categories, skip the subscribe step
            [[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
        } else {
            [self subscribeToSelectedCategories];
        }
    }
}

- (void)handleDidGetFeaturedChannelsNotification:(NSNotification *)aNotification
{
    subscribingChannels = [[NSMutableSet alloc] initWithArray:[[aNotification userInfo] objectForKey:@"channels"]];
    
    for (NMChannel *channel in subscribingChannels) {
        [[NMTaskQueueController sharedTaskQueueController] issueSubscribe:YES channel:channel];
    }
}

- (void)handleDidSubscribeNotification:(NSNotification *)aNotification 
{
    NMChannel *channel = [[aNotification userInfo] objectForKey:@"channel"];
    [subscribingChannels removeObject:channel];
    
    if ([subscribingChannels count] == 0) {
        // All channels have been subscribed to - ready to get the channel list
        [[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
    }
}

- (void)handleDidGetChannelsNotification:(NSNotification *)aNotification
{
    // Set up channels view
    NSArray *channels = [[NMTaskQueueController sharedTaskQueueController].dataController subscribedChannels];
    NSUInteger row = 0, col = 0, page = 0;
    CGFloat leftPos = (channelsScrollView.frame.size.width - (kChannelGridItemHorizontalSpacing * kChannelGridNumberOfColumns)) / 2;
    
    for (NMChannel *channel in channels) {
        OnBoardProcessChannelView *channelView = [[OnBoardProcessChannelView alloc] init];
        [channelView setTitle:channel.title];
        [channelView setReason:@"No reason..."];
        [channelView.thumbnailImage setImageForChannel:channel];
        
        CGRect frame = channelView.frame;
        frame.origin.x = (page * channelsScrollView.frame.size.width) + col * kChannelGridItemHorizontalSpacing + leftPos;
        frame.origin.y = row * (channelView.frame.size.height + kChannelGridItemPadding);
        channelView.frame = frame;
        
        [channelsScrollView addSubview:channelView];
        [channelView release];
        
        channelsScrollView.contentSize = CGSizeMake((page + 1) * channelsScrollView.frame.size.width, channelsScrollView.frame.size.height);
        
        col++;
        if (col >= kChannelGridNumberOfColumns) {
            row++;            
            col = 0;

            if (row >= kChannelGridNumberOfRows) {
                page++;
                row = 0;
            }
        }
    }
}

- (void)handleLaunchFailNotification:(NSNotification *)aNotification 
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Sorry, it looks like the service is currently down. Please try again in a little while." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    exit(0);
}

@end
