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
#import "Analytics.h"
#import "ipadAppDelegate.h"
#import <QuartzCore/QuartzCore.h>

#define kChannelGridNumberOfRows 4
#define kChannelGridNumberOfColumns 3
#define kChannelGridItemHorizontalSpacing 300
#define kChannelGridItemPadding 10
#define kYouTubeSyncTimeoutInSeconds 20

@implementation OnBoardProcessViewController

@synthesize mainGradient;
@synthesize splashView;
@synthesize categoriesView;
@synthesize categoryGrid;
@synthesize proceedToSocialButton;
@synthesize socialView;
@synthesize youtubeButton;
@synthesize facebookButton;
@synthesize twitterButton;
@synthesize infoView;
@synthesize settingUpView;
@synthesize proceedToChannelsButton;
@synthesize channelsView;
@synthesize channelsScrollView;
@synthesize featuredCategories;
@synthesize subscribedChannels;
@synthesize subscribingChannels;
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
        [nc addObserver:self selector:@selector(handleDidVerifyUserNotification:) name:NMDidVerifyUserNotification object:nil];
        [nc addObserver:self selector:@selector(handleDidFailVerifyUserNotification:) name:NMDidFailVerifyUserNotification object:nil];
        [nc addObserver:self selector:@selector(handleDidCompareSubscribedChannelsNotification:) name:NMDidCompareSubscribedChannelsNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [youtubeTimeoutTimer invalidate]; youtubeTimeoutTimer = nil;
    
    [mainGradient release];
    [splashView release];
    [subscribedChannels release];
    [subscribingChannels release];
    [categoriesView release];
    [categoryGrid release];
    [proceedToSocialButton release];
    [socialView release];
    [youtubeButton release];
    [facebookButton release];
    [twitterButton release];
    [infoView release];
    [settingUpView release];
    [proceedToChannelsButton release];    
    [channelsView release];
    [channelsScrollView release];
    [featuredCategories release];
    
    [super dealloc];
}

- (void)updateFontsForView:(UIView *)view
{
    // Update font to Futura Condensed if available
    static NSString *oldFontName = @"Futura-Medium";
    static NSString *newFontName = @"Futura-CondensedMedium";
    UIFont *condensedFont = [UIFont fontWithName:newFontName size:12.0];
    
    if (condensedFont) {
        for (UIView *subview in view.subviews) {
            if ([subview isKindOfClass:[UILabel class]]) {
                UILabel *label = (UILabel *)subview;
                if ([label.font.fontName isEqualToString:oldFontName]) {
                    [label setFont:[UIFont fontWithName:newFontName size:label.font.pointSize + 2]];
                }
            } else {
                [self updateFontsForView:subview];
            }
        }
    }
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
    
    currentView = view2;
    [self updateFontsForView:currentView];
}

- (void)subscribeToSelectedCategories
{
    [[NMTaskQueueController sharedTaskQueueController] issueGetFeaturedChannelsForCategories:[featuredCategories objectsAtIndexes:categoryGrid.selectedViewIndexes]];
}

- (void)notifyVideosReady
{
    // Allow the user to proceed past the info step
    [UIView animateWithDuration:0.15 
                     animations:^{
                         settingUpView.alpha = 0;
                     }
                     completion:^(BOOL finished){
                         [UIView animateWithDuration:0.15 
                                          animations:^{
                                              proceedToChannelsButton.alpha = 1;
                             
                         }];
                     }];
}

- (void)updateSocialNetworkButtonTexts
{
    [youtubeButton setTitle:(NM_USER_YOUTUBE_SYNC_ACTIVE ? @"CONNECTED" : @"CONNECT") forState:UIControlStateNormal];
    [youtubeButton setSelected:NM_USER_YOUTUBE_SYNC_ACTIVE];
    [youtubeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected | UIControlStateHighlighted];
    
    [facebookButton setTitle:(NM_USER_FACEBOOK_CHANNEL_ID != 0 ? @"CONNECTED" : @"CONNECT") forState:UIControlStateNormal];
    [facebookButton setSelected:NM_USER_FACEBOOK_CHANNEL_ID != 0];
    [facebookButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected | UIControlStateHighlighted];
    
    [twitterButton setTitle:(NM_USER_TWITTER_CHANNEL_ID != 0 ? @"CONNECTED" : @"CONNECT") forState:UIControlStateNormal];
    [twitterButton setSelected:NM_USER_TWITTER_CHANNEL_ID != 0];
    [twitterButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected | UIControlStateHighlighted];
}

- (void)youtubeTimeoutTimerFired
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NMDidPollUserNotification object:nil];
    youtubeTimeoutTimer = nil;
    youtubeSynced = YES;
    
    if (currentView == infoView) {
        [[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
    }
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
    [categoryGrid setGridDelegate:self];
    
    channelsScrollView.pageMarginLeft = 50;
    channelsScrollView.pageMarginRight = 50;
    
    // Have we already synced some services? (Probably only applicable for debugging)
    youtubeSynced = NM_USER_YOUTUBE_SYNC_ACTIVE;
    [self updateSocialNetworkButtonTexts];
    
    currentView = splashView;
    
    [[NMTaskQueueController sharedTaskQueueController] issueCreateUser];
}

- (void)viewDidUnload
{
    self.mainGradient = nil;
    self.splashView = nil;
    self.categoriesView = nil;
    self.categoryGrid = nil;
    self.proceedToSocialButton = nil;
    self.socialView = nil;
    self.youtubeButton = nil;
    self.facebookButton = nil;
    self.twitterButton = nil;
    self.infoView = nil;
    self.channelsView = nil;
    self.channelsScrollView = nil;
    self.featuredCategories = nil;
    self.settingUpView = nil;
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
    socialController = [[SocialLoginViewController alloc] initWithNibName:@"SocialLoginView" bundle:nil];
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
    if (![sender isSelected]) {
        [self loginToSocialNetworkWithType:NMLoginYouTubeType];
    }
}

- (IBAction)loginToFacebook:(id)sender
{
    if (![sender isSelected]) {    
        [self loginToSocialNetworkWithType:NMLoginFacebookType];
    }
}

- (IBAction)loginToTwitter:(id)sender
{
    if (![sender isSelected]) {    
        [self loginToSocialNetworkWithType:NMLoginTwitterType];
    }
}

- (void)dismissSocialLogin:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
    socialController = nil;
}

- (IBAction)switchToCategoriesView:(id)sender
{
    [self transitionFromView:splashView toView:categoriesView];
    self.splashView = nil;
}

- (IBAction)switchToSocialView:(id)sender
{
    [self transitionFromView:categoriesView toView:socialView];
    
    if ([categoryGrid.selectedViewIndexes count] > 0) {
        [self subscribeToSelectedCategories];
    }
    
    self.categoriesView = nil;
}

- (IBAction)switchToInfoView:(id)sender
{
    [self transitionFromView:socialView toView:infoView];
    self.socialView = nil;
    
    // If YouTube sync enabled, wait for it to finish or timeout. Otherwise we can get the subscribed channels directly.
    if ([subscribingChannels count] == 0 && (!NM_USER_YOUTUBE_SYNC_ACTIVE || youtubeSynced)) {
        [[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
    }
}

- (IBAction)switchToChannelsView:(id)sender
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:NMDidSubscribeChannelNotification object:nil];
    
    [self transitionFromView:infoView toView:channelsView];
    self.infoView = nil;
}

- (IBAction)switchToPlaybackView:(id)sender
{
    [delegate onBoardProcessViewControllerDidFinish:self];
}

#pragma mark - Notifications

- (void)handleDidCreateUserNotification:(NSNotification *)aNotification 
{
    userCreated = YES;
    
    // Begin new session
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSInteger sid = [userDefaults integerForKey:NM_SESSION_ID_KEY] + 1;
	[[NMTaskQueueController sharedTaskQueueController] beginNewSession:sid];
	[userDefaults setInteger:sid forKey:NM_SESSION_ID_KEY];
    
    if ([categoryGrid.selectedViewIndexes count] > 0) {
        [UIView animateWithDuration:0.3 animations:^{
            proceedToSocialButton.alpha = 1;
        }];
    }
    
    [[MixpanelAPI sharedAPI] identifyUser:[NSString stringWithFormat:@"%i", NM_USER_ACCOUNT_ID]];
    [[MixpanelAPI sharedAPI] setNameTag:[NSString stringWithFormat:@"User #%i", NM_USER_ACCOUNT_ID]];
    [[MixpanelAPI sharedAPI] track:AnalyticsEventLogin];
}

- (void)handleDidGetFeaturedChannelsNotification:(NSNotification *)aNotification
{
    NSArray *featuredChannels = [[aNotification userInfo] objectForKey:@"channels"];
    self.subscribingChannels = [NSMutableSet setWithArray:featuredChannels];
    [[NMTaskQueueController sharedTaskQueueController] issueSubscribeChannels:featuredChannels];    
}

- (void)handleDidSubscribeNotification:(NSNotification *)aNotification 
{
    NMChannel *channel = [[aNotification userInfo] objectForKey:@"channel"];
    [subscribingChannels removeObject:channel];
    
    if ([subscribingChannels count] == 0) {
        // All channels have been subscribed to
        if (currentView == infoView && (!NM_USER_YOUTUBE_SYNC_ACTIVE || youtubeSynced)) {
            [[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
        }
    }
}

- (NSString *)reasonForChannel:(NMChannel *)channel
{
    // Is the channel from the user's YouTube account?
    NMCategory *youtubeCategory = [[[NMTaskQueueController sharedTaskQueueController] dataController] internalYouTubeCategory];
    if ([youtubeCategory.channels containsObject:channel]) {
        return @"from YouTube";
    }
    
    // Is the channel part of a category the user selected?
    NSArray *selectedCategories = [featuredCategories objectsAtIndexes:categoryGrid.selectedViewIndexes];    
    for (NMCategory *category in selectedCategories) {        
        if ([channel.categories containsObject:category]) {
            return [NSString stringWithFormat:@"from %@", category.title];
        }
    }
    
    return @"Featured Channel";
}

- (void)handleDidGetChannelsNotification:(NSNotification *)aNotification
{
    // Filter out NOWBOX channels (like Watch Later / Favorites)
    NSMutableArray *allSubscribedChannels = [NSMutableArray arrayWithArray:[[NMTaskQueueController sharedTaskQueueController].dataController subscribedChannels]];
    [allSubscribedChannels removeObject:[[NMTaskQueueController sharedTaskQueueController].dataController userFacebookStreamChannel]];
    [allSubscribedChannels removeObject:[[NMTaskQueueController sharedTaskQueueController].dataController userTwitterStreamChannel]];     
    self.subscribedChannels = [allSubscribedChannels filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type != 1"]];
    
    [channelsScrollView reloadData];      
}

- (void)handleLaunchFailNotification:(NSNotification *)aNotification 
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Sorry, it looks like the service is down. Please try again later." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}

- (void)handleDidVerifyUserNotification:(NSNotification *)aNotification 
{
    [self updateSocialNetworkButtonTexts];
    
    if (socialController.loginType == NMLoginYouTubeType && NM_USER_YOUTUBE_SYNC_ACTIVE) {
        [youtubeTimeoutTimer invalidate];
        youtubeTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:kYouTubeSyncTimeoutInSeconds target:self selector:@selector(youtubeTimeoutTimerFired) userInfo:nil repeats:NO];
    }
    
    [self dismissSocialLogin:nil];
}

- (void)handleDidFailVerifyUserNotification:(NSNotification *)aNotification 
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Sorry, we were unable to connect your account. Please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    [self dismissSocialLogin:nil];    
}

- (void)handleDidCompareSubscribedChannelsNotification:(NSNotification *)aNotification 
{
    youtubeSynced = YES;
    
    if (currentView == infoView) {
        [[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    exit(0);
}

#pragma mark - CategorySelectionGridDelegate

- (void)categorySelectionGrid:(CategorySelectionGrid *)aCategoryGrid didSelectCategoryAtIndex:(NSUInteger)index
{
    BOOL showNextButton = ([aCategoryGrid.selectedViewIndexes count] > 0 && userCreated);
    
    if ((proceedToSocialButton.alpha == 0 && showNextButton) || (proceedToSocialButton.alpha == 1 && !showNextButton)) {
        [UIView animateWithDuration:0.3 animations:^{
            proceedToSocialButton.alpha = (showNextButton ? 1 : 0);
        }];
    }
}

#pragma mark - GridScrollViewDelegate

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
