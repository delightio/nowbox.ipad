//
//  OnBoardProcessViewController.m
//  ipad
//
//  Created by Chris Haugli on 11/2/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "OnBoardProcessViewController.h"
#import "OnBoardProcessCategoryView.h"
#import "OnBoardProcessChannelView.h"
#import "SocialLoginViewController.h"
#import "NMTaskQueueController.h"
#import "NMDataController.h"
#import "NMDataType.h"
#import "NMCategory.h"
#import "NMChannel.h"
#import "Analytics.h"
#import "Crittercism.h"
#import "ipadAppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+InteractiveAnimation.h"

#define kChannelGridNumberOfRows 4
#define kChannelGridNumberOfColumns 3
#define kChannelGridItemHorizontalSpacing 300
#define kChannelGridItemPadding 10
#define kYouTubeSyncTimeoutInSeconds 20

@implementation OnBoardProcessViewController

@synthesize splashView;
@synthesize slideInView;
@synthesize tappableArea;
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
@synthesize selectedCategoryIndexes;
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
        
        self.selectedCategoryIndexes = [NSMutableIndexSet indexSet];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [youtubeTimeoutTimer invalidate]; youtubeTimeoutTimer = nil;
    [infoWaitTimer invalidate]; infoWaitTimer = nil;
    
    [splashView release];
    [slideInView release];
    [tappableArea release];
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
    [selectedCategoryIndexes release];
    
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
    [[NMTaskQueueController sharedTaskQueueController] issueGetFeaturedChannelsForCategories:[featuredCategories objectsAtIndexes:selectedCategoryIndexes]];
}

- (void)showProceedToChannelsButton
{
    NSLog(@"Onboard process continuing");
    // Allow the user to proceed past the info step
    [UIView animateWithInteractiveDuration:0.15 
                     animations:^{
                         settingUpView.alpha = 0;
                     }
                     completion:^(BOOL finished){
                         [UIView animateWithInteractiveDuration:0.15 
                                          animations:^{
                                              proceedToChannelsButton.alpha = 1;
                                          }];
                     }];    
}

- (void)updateSocialNetworkButtonTexts
{
    BOOL youtubeConnected = NM_USER_YOUTUBE_SYNC_ACTIVE;
    BOOL facebookConnected = NM_USER_FACEBOOK_CHANNEL_ID != 0;
    BOOL twitterConnected = NM_USER_TWITTER_CHANNEL_ID != 0;
    
    [youtubeButton setTitle:(youtubeConnected ? @"CONNECTED" : @"CONNECT") forState:UIControlStateNormal];
    [youtubeButton setSelected:youtubeConnected];
    [youtubeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected | UIControlStateHighlighted];
    [youtubeButton setUserInteractionEnabled:!youtubeConnected];
    
    [facebookButton setTitle:(facebookConnected ? @"CONNECTED" : @"CONNECT") forState:UIControlStateNormal];
    [facebookButton setSelected:facebookConnected];
    [facebookButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected | UIControlStateHighlighted];
    [facebookButton setUserInteractionEnabled:!facebookConnected];

    [twitterButton setTitle:(twitterConnected ? @"CONNECTED" : @"CONNECT") forState:UIControlStateNormal];
    [twitterButton setSelected:twitterConnected != 0];
    [twitterButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected | UIControlStateHighlighted];
    [twitterButton setUserInteractionEnabled:!twitterConnected];
}

- (void)youtubeTimeoutTimerFired
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NMDidPollUserNotification object:nil];
    youtubeTimeoutTimer = nil;
    youtubeSynced = YES;
    
    if (currentView && currentView == infoView) {
        [[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
    }
}

- (void)infoWaitTimerFired
{
    NSLog(@"Wait timer ready for onboard process to continue");
    infoWaitTimer = nil;
    infoWaitTimerFired = YES;
    
    if (videosReady) {
        [self showProceedToChannelsButton];
    }
}

- (void)notifyVideosReady
{
    NSLog(@"Videos ready for onboard process to continue");
    videosReady = YES;
    
    if (infoWaitTimerFired) {
        [self showProceedToChannelsButton];
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
        
    categoryGrid.itemSize = CGSizeMake(265, 96);
    channelsScrollView.itemSize = CGSizeMake(260, 90);
    channelsScrollView.verticalItemPadding = 18;
    
    // Sort the categories by sort order
    NSArray *categories = [[[NMTaskQueueController sharedTaskQueueController] dataController] categories];
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"nm_sort_order" ascending:YES];
    self.featuredCategories = [categories sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter]];
    [sorter release];
    [categoryGrid reloadData];
    
    // Have we already synced some services? (Probably only applicable for debugging)
    youtubeSynced = NM_USER_YOUTUBE_SYNC_ACTIVE;
    [self updateSocialNetworkButtonTexts];
    
    currentView = splashView;
    
    // Preload the categories view so that we can start downloading category icons
    categoriesView.frame = CGRectOffset(self.view.bounds, self.view.bounds.size.width, 0);
    [self.view addSubview:categoriesView];
    
    [[NMTaskQueueController sharedTaskQueueController] issueCreateUser];
}

- (void)viewDidUnload
{
    self.splashView = nil;
    self.slideInView = nil;
    self.tappableArea = nil;
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    slideInView.frame = CGRectOffset(slideInView.frame, 0, 200);
    [UIView animateWithDuration:0.5
                          delay:1.5
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         slideInView.frame = CGRectOffset(slideInView.frame, 0, -200);                         
                     }
                     completion:^(BOOL finished){
                         tappableArea.userInteractionEnabled = YES;
                     }];
}   

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - Actions

- (IBAction)categorySelected:(id)sender
{
	UIButton *categoryButton = (UIButton *)sender;
    NSUInteger index = [categoryButton tag];
    if ([selectedCategoryIndexes containsIndex:index]) {
        [categoryButton setSelected:NO];
        [selectedCategoryIndexes removeIndex:index];
    } else {
        [categoryButton setSelected:YES];
        [selectedCategoryIndexes addIndex:index];
    }
    
    BOOL showNextButton = ([selectedCategoryIndexes count] > 0 && userCreated);
        
    if ((proceedToSocialButton.alpha == 0 && showNextButton) || (proceedToSocialButton.alpha == 1 && !showNextButton)) {
        [UIView animateWithInteractiveDuration:0.3 animations:^{
            proceedToSocialButton.alpha = (showNextButton ? 1 : 0);
        }];
    }
}

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
        [[MixpanelAPI sharedAPI] track:AnalyticsEventStartYouTubeLogin properties:[NSDictionary dictionaryWithObject:@"onboard" forKey:AnalyticsPropertySender]];        
    }
}

- (IBAction)loginToFacebook:(id)sender
{
    if (![sender isSelected]) {    
        [self loginToSocialNetworkWithType:NMLoginFacebookType];
        [[MixpanelAPI sharedAPI] track:AnalyticsEventStartFacebookLogin properties:[NSDictionary dictionaryWithObject:@"onboard" forKey:AnalyticsPropertySender]];        
    }
}

- (IBAction)loginToTwitter:(id)sender
{
    if (![sender isSelected]) {    
        [self loginToSocialNetworkWithType:NMLoginTwitterType];
        [[MixpanelAPI sharedAPI] track:AnalyticsEventStartTwitterLogin properties:[NSDictionary dictionaryWithObject:@"onboard" forKey:AnalyticsPropertySender]];                
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
}

- (IBAction)switchToSocialView:(id)sender
{
    [self transitionFromView:categoriesView toView:socialView];
    
    if ([selectedCategoryIndexes count] > 0) {
        [self subscribeToSelectedCategories];
    }
}

- (IBAction)switchToInfoView:(id)sender
{
    [self transitionFromView:socialView toView:infoView];
    
    // If YouTube sync enabled, wait for it to finish or timeout. Otherwise we can get the subscribed channels directly.
    if (subscribingChannels && [subscribingChannels count] == 0 && (!NM_USER_YOUTUBE_SYNC_ACTIVE || youtubeSynced)) {
        [[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
    }
    
    [infoWaitTimer invalidate];
    infoWaitTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(infoWaitTimerFired) userInfo:nil repeats:NO];
}

- (IBAction)switchToChannelsView:(id)sender
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:NMDidSubscribeChannelNotification object:nil];
    
    [self transitionFromView:infoView toView:channelsView];
}

- (IBAction)switchToPlaybackView:(id)sender
{
    [delegate onBoardProcessViewControllerDidFinish:self];
}

#pragma mark - Notifications

- (void)handleDidCreateUserNotification:(NSNotification *)aNotification 
{    
    if (!userCreated) {
        userCreated = YES;

        // Begin new session
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSInteger sid = [userDefaults integerForKey:NM_SESSION_ID_KEY] + 1;
        [[NMTaskQueueController sharedTaskQueueController] beginNewSession:sid];
        
        // Save user ID and more
        [userDefaults setInteger:sid forKey:NM_SESSION_ID_KEY];
		[userDefaults setInteger:NM_USER_ACCOUNT_ID forKey:NM_USER_ACCOUNT_ID_KEY];
		[userDefaults setInteger:NM_USER_WATCH_LATER_CHANNEL_ID forKey:NM_USER_WATCH_LATER_CHANNEL_ID_KEY];
		[userDefaults setInteger:NM_USER_FAVORITES_CHANNEL_ID forKey:NM_USER_FAVORITES_CHANNEL_ID_KEY];
		[userDefaults setInteger:NM_USER_HISTORY_CHANNEL_ID forKey:NM_USER_HISTORY_CHANNEL_ID_KEY];
        [userDefaults synchronize];
        
        if ([selectedCategoryIndexes count] > 0) {
            [UIView animateWithInteractiveDuration:0.3 animations:^{
                proceedToSocialButton.alpha = 1;
            }];
        }
        
        NSString *userNameTag = [NSString stringWithFormat:@"User #%i", NM_USER_ACCOUNT_ID];
        [Crittercism setUsername:userNameTag];
        [[MixpanelAPI sharedAPI] identifyUser:[NSString stringWithFormat:@"%i", NM_USER_ACCOUNT_ID]];
        [[MixpanelAPI sharedAPI] setNameTag:userNameTag];
        [[MixpanelAPI sharedAPI] track:@"$born"];
        [[MixpanelAPI sharedAPI] track:AnalyticsEventLogin];
    }
}

- (void)handleDidGetFeaturedChannelsNotification:(NSNotification *)aNotification
{
    NSArray *featuredChannels = [[aNotification userInfo] objectForKey:@"channels"];
    
    if ([featuredChannels count] > 0) {
        self.subscribingChannels = [NSMutableSet setWithArray:featuredChannels];
        [[NMTaskQueueController sharedTaskQueueController] issueSubscribeChannels:featuredChannels];    
    } else {
        // Skip to next step
        if (currentView && currentView == infoView && (!NM_USER_YOUTUBE_SYNC_ACTIVE || youtubeSynced)) {
            [[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
        }
    }
}

- (void)handleDidSubscribeNotification:(NSNotification *)aNotification 
{
    NMChannel *channel = [[aNotification userInfo] objectForKey:@"channel"];
    [subscribingChannels removeObject:channel];
    
    if ([subscribingChannels count] == 0) {
        // All channels have been subscribed to
        if (currentView && currentView == infoView && (!NM_USER_YOUTUBE_SYNC_ACTIVE || youtubeSynced)) {
            [[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
        }
    }
}

- (NSString *)reasonForChannel:(NMChannel *)channel
{
    if (channel == [[NMTaskQueueController sharedTaskQueueController].dataController userFacebookStreamChannel]) {
        return @"Facebook channel";
    } else if (channel == [[NMTaskQueueController sharedTaskQueueController].dataController userTwitterStreamChannel]) {
        return @"Twitter channel";
    }
    
    // Is the channel part of a category the user selected?
    NSArray *selectedCategories = [featuredCategories objectsAtIndexes:selectedCategoryIndexes];    
    for (NMCategory *category in selectedCategories) {        
        if ([channel.categories containsObject:category]) {
            return [NSString stringWithFormat:@"from %@", category.title];
        }
    }
    
    return @"from YouTube account";
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
    if (!alertShowing) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Sorry, it looks like the service is down. Please try again later." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        [alertView release];
        alertShowing = YES;
    }
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
    NSString *message;
    if (socialController.loginType == NMLoginYouTubeType) {
        message = @"Sorry. Please note we only support YouTube accounts right now.";
    } else {
        message = @"Sorry, we weren't able to verify your account. Please try again later.";
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    [self dismissSocialLogin:nil];    
}

- (void)handleDidCompareSubscribedChannelsNotification:(NSNotification *)aNotification 
{
    youtubeSynced = YES;
    [youtubeTimeoutTimer invalidate]; youtubeTimeoutTimer = nil;
    
    if (currentView && currentView == infoView) {
        [[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    exit(0);
}

#pragma mark - GridScrollViewDelegate

- (NSUInteger)gridScrollViewNumberOfItems:(GridScrollView *)gridScrollView
{
    if (gridScrollView == categoryGrid) {
        // Category grid
        return [featuredCategories count];
    } else {
        // Channels grid
        return [subscribedChannels count];
    }
}

- (UIView *)gridScrollView:(GridScrollView *)gridScrollView viewForItemAtIndex:(NSUInteger)index
{
    if (gridScrollView == categoryGrid) {
        // Categories
        NMCategory *category = [featuredCategories objectAtIndex:index];
        
		OnBoardProcessCategoryView *categoryView = (OnBoardProcessCategoryView *)[gridScrollView dequeueReusableSubview];
        if (!categoryView) {
			categoryView = [[[OnBoardProcessCategoryView alloc] init] autorelease];
            [categoryView.button addTarget:self action:@selector(categorySelected:) forControlEvents:UIControlEventTouchUpInside];
            [categoryView.button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted | UIControlStateSelected];
            [categoryView.button setTitleShadowColor:[UIColor clearColor] forState:UIControlStateHighlighted | UIControlStateSelected];
            
            UIFont *font = [UIFont fontWithName:@"Futura-CondensedMedium" size:20.0];
            if (!font) {
                font = [UIFont fontWithName:@"Futura-Medium" size:18.0];
            }
            [categoryView.button.titleLabel setFont:font];
        }
        
        [categoryView.button setTag:index];
        [categoryView.button setTitle:[category.title uppercaseString] forState:UIControlStateNormal];
        [categoryView.button setSelected:[selectedCategoryIndexes containsIndex:index]];
		[categoryView.thumbnailImage setImageForCategory:category];
        
        return categoryView;
        
    } else {
        // Channels
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
}

@end
