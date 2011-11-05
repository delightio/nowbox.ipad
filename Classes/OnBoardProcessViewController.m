//
//  OnBoardProcessViewController.m
//  ipad
//
//  Created by Chris Haugli on 11/2/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "OnBoardProcessViewController.h"
#import "OnBoardProcessChannelView.h"
#import "CategorySelectionViewController.h"
#import "NMTaskQueueController.h"
#import "NMDataController.h"
#import "NMDataType.h"
#import "NMCategory.h"
#import "NMChannel.h"

#define kChannelGridNumberOfRows 4
#define kChannelGridNumberOfColumns 3
#define kChannelGridItemHorizontalSpacing 300
#define kChannelGridItemPadding 10

@implementation OnBoardProcessViewController

@synthesize loginView;
@synthesize categoryGrid;
@synthesize infoView;
@synthesize proceedToChannelsButton;
@synthesize channelsView;
@synthesize channelsScrollView;
@synthesize channelsPageControl;
@synthesize featuredCategories;
@synthesize featuredChannels;
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

    [featuredChannels release];
    [subscribingChannels release];
    [loginView release];
    [categoryGrid release];
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
    [proceedToChannelsButton setTitle:@"Next" forState:UIControlStateNormal];
    proceedToChannelsButton.enabled = YES;
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
    NSMutableArray *categoryTitles = [NSMutableArray array];
    for (NMCategory *category in featuredCategories) {
        [categoryTitles addObject:category.title];
    }
    [categoryGrid setCategoryTitles:categoryTitles];
    
    channelsScrollView.pageMarginLeft = 50;
    channelsScrollView.pageMarginRight = 50;
    
    // Show the login page to start
    [loginView setFrame:self.view.bounds];
    [self.view addSubview:loginView];    
    currentView = loginView;
    
    [[NMTaskQueueController sharedTaskQueueController] issueCreateUser];
}

- (void)viewDidUnload
{
    self.loginView = nil;
    self.categoryGrid = nil;
    self.infoView = nil;
    self.channelsView = nil;
    self.channelsScrollView = nil;
    self.channelsPageControl = nil;
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

#pragma mark - Actions

- (IBAction)switchToInfoView:(id)sender
{
    [self transitionFromView:loginView toView:infoView];
    currentView = infoView;
    
    if (userCreated) {
        if ([categoryGrid.selectedButtonIndexes count] == 0) {
            // Didn't select any categories, skip the subscribe step
            [[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
        } else {
            [self subscribeToSelectedCategories];
        }
    }
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

- (IBAction)addInterests:(id)sender
{
    CategorySelectionViewController *categorySelectionController = [[CategorySelectionViewController alloc] initWithCategories:featuredCategories 
                                                                                                       selectedCategoryIndexes:categoryGrid.selectedButtonIndexes
                                                                                                            subscribedChannels:featuredChannels];
    categorySelectionController.delegate = self;
    
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:categorySelectionController];
	navController.navigationBar.barStyle = UIBarStyleBlack;
    
    [navController setModalPresentationStyle:UIModalPresentationFormSheet];
    [self presentModalViewController:navController animated:YES];
    
    [categorySelectionController release];
    [navController release];
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
    // Is the channel one of the user's YouTube channels?
    // TODO
    
    // Is the channel part of a category the user selected?
    NSArray *selectedCategories = [featuredCategories objectsAtIndexes:categoryGrid.selectedButtonIndexes];    
    for (NMCategory *category in selectedCategories) {
        if ([channel.categories containsObject:category]) {
            return [NSString stringWithFormat:@"from %@", category.title];
        }
    }
    
    return @"No reason...";
}

- (void)handleDidGetChannelsNotification:(NSNotification *)aNotification
{
    [channelsScrollView reloadData];
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
    NSArray *channels = [[NMTaskQueueController sharedTaskQueueController].dataController subscribedChannels];
    return [channels count];
}

- (UIView *)gridScrollView:(GridScrollView *)gridScrollView viewForItemAtIndex:(NSUInteger)index
{
    NSArray *channels = [[NMTaskQueueController sharedTaskQueueController].dataController subscribedChannels];
    NMChannel *channel = [channels objectAtIndex:index];
    
    OnBoardProcessChannelView *channelView = (OnBoardProcessChannelView *) [gridScrollView dequeueReusableSubview];
    if (!channelView) {
        channelView = [[[OnBoardProcessChannelView alloc] init] autorelease];
    }
    
    [channelView setTitle:channel.title];
    [channelView setReason:[self reasonForChannel:channel]];
    [channelView.thumbnailImage setImageForChannel:channel];
    
    return channelView;
}

#pragma mark CategorySelectionViewControllerDelegate;

- (void)categorySelectionViewControllerWillDismiss:(CategorySelectionViewController *)controller
{
    categoryGrid.selectedButtonIndexes = controller.categoryGrid.selectedButtonIndexes;
}

@end
