//
//  OnBoardProcessViewController.m
//  ipad
//
//  Created by Chris Haugli on 11/2/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "OnBoardProcessViewController.h"
#import "OnBoardProcessChannelView.h"
#import "SocialLoginViewController.h"
#import "NMTaskQueueController.h"
#import "NMDataController.h"
#import "NMDataType.h"
#import "NMCategory.h"
#import "NMChannel.h"
#import <QuartzCore/QuartzCore.h>

#define kChannelGridNumberOfRows 4
#define kChannelGridNumberOfColumns 3
#define kChannelGridItemHorizontalSpacing 300
#define kChannelGridItemPadding 10

@implementation OnBoardProcessViewController

@synthesize mainGradient;
@synthesize categoriesView;
@synthesize categoryGrid;
@synthesize socialView;
@synthesize infoView;
@synthesize proceedToChannelsButton;
@synthesize channelsView;
@synthesize channelsScrollView;
@synthesize channelsPageControl;
@synthesize featuredCategories;
@synthesize featuredChannels;
@synthesize subscribedChannels;
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {        
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

    [mainGradient release];
    [featuredChannels release];
    [subscribingChannels release];
    [subscribedChannels release];
    [categoriesView release];
    [categoryGrid release];
    [socialView release];
    [infoView release];
    [proceedToChannelsButton release];    
    [channelsView release];
    [channelsScrollView release];
    [channelsPageControl release];
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
    [[NMTaskQueueController sharedTaskQueueController] issueGetFeaturedChannelsForCategories:[featuredCategories objectsAtIndexes:categoryGrid.selectedButtonIndexes]];
}

- (void)notifyVideosReady
{
    // Allow the user to proceed past the info step
    [proceedToChannelsButton setTitle:@"NEXT" forState:UIControlStateNormal];
    proceedToChannelsButton.enabled = YES;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    categoriesView.backgroundColor = [UIColor clearColor];
    socialView.backgroundColor = [UIColor clearColor];
    infoView.backgroundColor = [UIColor clearColor];
    channelsView.backgroundColor = [UIColor clearColor];
    categoryGrid.backgroundColor = [UIColor clearColor];
    
    [mainGradient setColours:242:242:242 :234:234:234];
    mainGradient.layer.cornerRadius = 5;
    mainGradient.layer.masksToBounds = YES;
    
    // Sort the categories by name
    NSArray *categories = [[[NMTaskQueueController sharedTaskQueueController] dataController] categories];
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    self.featuredCategories = [categories sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter]];
    [sorter release];
    
    // Now we can populate the featured category list
    NSMutableArray *categoryTitles = [NSMutableArray array];
    for (NMCategory *category in featuredCategories) {
        [categoryTitles addObject:category.title];
    }
    [categoryGrid setCategoryTitles:categoryTitles];
    
    channelsScrollView.pageMarginLeft = 50;
    channelsScrollView.pageMarginRight = 50;
    
    // Show the login page to start
    [categoriesView setFrame:self.view.bounds];
    [self.view addSubview:categoriesView];    
    currentView = categoriesView;
    
    [[NMTaskQueueController sharedTaskQueueController] issueCreateUser];
}

- (void)viewDidUnload
{
    self.mainGradient = nil;
    self.categoriesView = nil;
    self.categoryGrid = nil;
    self.socialView = nil;
    self.infoView = nil;
    self.channelsView = nil;
    self.channelsScrollView = nil;
    self.channelsPageControl = nil;
    self.featuredCategories = nil;
    self.proceedToChannelsButton = nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - Actions

- (void)loginToSocialNetworkWithType:(NMSocialLoginType)loginType
{
    SocialLoginViewController *socialController = [[SocialLoginViewController alloc] initWithNibName:@"SocialLoginView" bundle:nil];
    socialController.loginType = loginType;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:socialController];
	navController.navigationBar.barStyle = UIBarStyleBlack;
    socialController.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissSocialLogin:)] autorelease];
    
    [navController setModalPresentationStyle:UIModalPresentationFormSheet];
    [self presentModalViewController:navController animated:YES];
    
    [socialController release];
    [navController release];      
}

- (IBAction)loginToYouTube:(id)sender
{
    [self loginToSocialNetworkWithType:NMLoginYouTubeType];
}

- (IBAction)loginToFacebook:(id)sender
{
    [self loginToSocialNetworkWithType:NMLoginFacebookType];
}

- (IBAction)loginToTwitter:(id)sender
{
    [self loginToSocialNetworkWithType:NMLoginTwitterType];
}

- (void)dismissSocialLogin:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)switchToSocialView:(id)sender
{
    [self transitionFromView:categoriesView toView:socialView];
    currentView = socialView;
    
    if ([categoryGrid.selectedButtonIndexes count] == 0) {
        // Didn't select any categories, skip the subscribe step
        [[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
    } else {
        [self subscribeToSelectedCategories];
    }
}

- (IBAction)switchToInfoView:(id)sender
{
    [self transitionFromView:socialView toView:infoView];
    currentView = infoView;
}

- (IBAction)switchToChannelsView:(id)sender
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:NMDidSubscribeChannelNotification object:nil];
    
    [self transitionFromView:infoView toView:channelsView];
    currentView = channelsView;
}

- (IBAction)switchToPlaybackView:(id)sender
{
    [delegate onBoardProcessViewControllerDidFinish:self];
}

- (IBAction)pageControlValueChanged:(id)sender
{
    [channelsScrollView setContentOffset:CGPointMake(channelsPageControl.currentPage * channelsScrollView.frame.size.width, 0) animated:YES];
    scrollingFromPageControl = YES;
}

#pragma mark - Notifications

- (void)handleDidCreateUserNotification:(NSNotification *)aNotification 
{
    userCreated = YES;
    if (currentView == infoView) {
        // We were waiting on this call to finish
        if ([categoryGrid.selectedButtonIndexes count] == 0) {
            // Didn't select any categories, skip the subscribe step
            [[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
        } else {
            [self subscribeToSelectedCategories];
        }
    }
}

- (void)handleDidGetFeaturedChannelsNotification:(NSNotification *)aNotification
{
    self.featuredChannels = [NSSet setWithArray:[[aNotification userInfo] objectForKey:@"channels"]];
    
    if (currentView != channelsView) {
        subscribingChannels = [[NSMutableSet alloc] initWithSet:featuredChannels];
        for (NMChannel *channel in subscribingChannels) {
            [[NMTaskQueueController sharedTaskQueueController] issueSubscribe:YES channel:channel];
        }
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

- (NSString *)reasonForChannel:(NMChannel *)channel
{
    // Is the channel part of a category the user selected?
    NSArray *selectedCategories = [featuredCategories objectsAtIndexes:categoryGrid.selectedButtonIndexes];    
    for (NMCategory *category in selectedCategories) {        
        if ([channel.categories containsObject:category]) {
            return [NSString stringWithFormat:@"from %@", category.title];
        }
    }
    
    return @"From YouTube";
}

- (void)handleDidGetChannelsNotification:(NSNotification *)aNotification
{
    // Filter out NOWBOX channels (like Watch Later / Favorites)
    NSArray *allSubscribedChannels = [[NMTaskQueueController sharedTaskQueueController].dataController subscribedChannels];
    self.subscribedChannels = [allSubscribedChannels filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type != 1"]];
    
    [CATransaction begin];
	CATransition *animation = [CATransition animation];
	animation.type = kCATransitionFade;
	animation.duration = 0.4;
	[[channelsScrollView layer] addAnimation:animation forKey:@"Fade"];
    [channelsScrollView reloadData];      
	[CATransaction commit];
    
    channelsPageControl.numberOfPages = channelsScrollView.contentSize.width / channelsScrollView.frame.size.width;
}

- (void)handleLaunchFailNotification:(NSNotification *)aNotification 
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Sorry, it looks like the service is down. Please try again in a little while." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    exit(0);
}

#pragma mark - GridScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!scrollingFromPageControl) {
        NSInteger page = round(scrollView.contentOffset.x / scrollView.frame.size.width);
        page = MAX(page, 0);
        page = MIN(page, channelsPageControl.numberOfPages - 1);
        
        channelsPageControl.currentPage = page;
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    scrollingFromPageControl = NO;
}

- (NSUInteger)gridScrollViewNumberOfItems:(GridScrollView *)gridScrollView
{
    return [subscribedChannels count];
}

- (UIView *)gridScrollView:(GridScrollView *)gridScrollView viewForItemAtIndex:(NSUInteger)index
{
    NMChannel *channel = [subscribedChannels objectAtIndex:index];
    
    OnBoardProcessChannelView *channelView = (OnBoardProcessChannelView *) [gridScrollView dequeueReusableSubview];
    if (!channelView) {
        channelView = [[[OnBoardProcessChannelView alloc] init] autorelease];
    }
    
    [channelView setTitle:channel.title];
    [channelView setReason:[self reasonForChannel:channel]];
    [channelView.thumbnailImage setImageForChannel:channel];
    
    return channelView;
}

@end
