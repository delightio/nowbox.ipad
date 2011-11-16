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

@synthesize splashView;
@synthesize slideInView;
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
@synthesize shadowDownView;
@synthesize shadowUpView;
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
    
    [splashView release];
    [slideInView release];
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
    [shadowDownView release];
    [shadowUpView release];
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

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    categoriesView.backgroundColor = [UIColor clearColor];
    socialView.backgroundColor = [UIColor clearColor];
    infoView.backgroundColor = [UIColor clearColor];
    channelsView.backgroundColor = [UIColor clearColor];
        
    categoryGrid.itemSize = CGSizeMake(265, 96);
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
    
    [[NMTaskQueueController sharedTaskQueueController] issueCreateUser];
}

- (void)viewDidUnload
{
    self.splashView = nil;
    self.slideInView = nil;
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
    self.shadowDownView = nil;
    self.shadowUpView = nil;
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
                          delay:0.5
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         slideInView.frame = CGRectOffset(slideInView.frame, 0, -200);                         
                     }
                     completion:^(BOOL finished){
                         
                     }];
}   

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - Actions

- (IBAction)categorySelected:(id)sender
{
    NSUInteger index = [sender tag];
    if ([selectedCategoryIndexes containsIndex:index]) {
        [sender setSelected:NO];
        [selectedCategoryIndexes removeIndex:index];
    } else {
        [sender setSelected:YES];
        [selectedCategoryIndexes addIndex:index];
    }
    
    BOOL showNextButton = ([selectedCategoryIndexes count] > 0 && userCreated);
        
    if ((proceedToSocialButton.alpha == 0 && showNextButton) || (proceedToSocialButton.alpha == 1 && !showNextButton)) {
        [UIView animateWithDuration:0.3 animations:^{
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
    if ([subscribingChannels count] == 0 && (!NM_USER_YOUTUBE_SYNC_ACTIVE || youtubeSynced)) {
        [[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
    }
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
        [userDefaults setInteger:sid forKey:NM_SESSION_ID_KEY];
        
        if ([selectedCategoryIndexes count] > 0) {
            [UIView animateWithDuration:0.3 animations:^{
                proceedToSocialButton.alpha = 1;
            }];
        }
        
        [[MixpanelAPI sharedAPI] identifyUser:[NSString stringWithFormat:@"%i", NM_USER_ACCOUNT_ID]];
        [[MixpanelAPI sharedAPI] setNameTag:[NSString stringWithFormat:@"User #%i", NM_USER_ACCOUNT_ID]];
        [[MixpanelAPI sharedAPI] track:@"$born"];
        [[MixpanelAPI sharedAPI] track:AnalyticsEventLogin];
    }
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
        if (currentView && currentView == infoView && (!NM_USER_YOUTUBE_SYNC_ACTIVE || youtubeSynced)) {
            [[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
        }
    }
}

- (NSString *)reasonForChannel:(NMChannel *)channel
{
/*    // Is the channel from the user's YouTube account?
    NMCategory *youtubeCategory = [[[NMTaskQueueController sharedTaskQueueController] dataController] internalYouTubeCategory];
    if ([youtubeCategory.channels containsObject:channel]) {
        return @"from YouTube account";
    }*/
    
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
    
    // Set shadow alpha
    [self scrollViewDidScroll:channelsScrollView];
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
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Sorry, we were unable to connect your account. Please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
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
        
        UIButton *categoryButton = (UIButton *) [gridScrollView dequeueReusableSubview];
        if (!categoryButton) {
            categoryButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [categoryButton addTarget:self action:@selector(categorySelected:) forControlEvents:UIControlEventTouchUpInside];
            [categoryButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            [categoryButton setBackgroundImage:[UIImage imageNamed:@"onboard-category-background-default.png"] forState:UIControlStateNormal];
            [categoryButton setBackgroundImage:[UIImage imageNamed:@"onboard-category-background-selected.png"] forState:UIControlStateSelected];
            [categoryButton setImage:[UIImage imageNamed:@"onboard-category-icon.png"] forState:UIControlStateNormal];
            [categoryButton setImageEdgeInsets:UIEdgeInsetsMake(0, 18, 2, 0)];
            [categoryButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 30, 2, 0)];            
            [categoryButton setTitleColor:[UIColor colorWithRed:76/255.0 green:77/255.0 blue:74/255.0 alpha:1] forState:UIControlStateNormal];
            [categoryButton setTitleColor:[UIColor colorWithRed:76/255.0 green:77/255.0 blue:74/255.0 alpha:1] forState:UIControlStateSelected];
            [categoryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
            [categoryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted | UIControlStateSelected];
            [categoryButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [categoryButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateHighlighted];
            [categoryButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateHighlighted | UIControlStateSelected];
            [categoryButton.titleLabel setShadowOffset:CGSizeMake(0, 1)];
            
            UIFont *font = [UIFont fontWithName:@"Futura-CondensedMedium" size:20.0];
            if (!font) {
                font = [UIFont fontWithName:@"Futura-Medium" size:18.0];
            }
            [categoryButton.titleLabel setFont:font];
        }
        
        [categoryButton setTitle:[category.title uppercaseString] forState:UIControlStateNormal];
        [categoryButton setSelected:[selectedCategoryIndexes containsIndex:index]];
        
        return categoryButton;
        
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    shadowDownView.alpha = MIN(1, MAX(0, scrollView.contentOffset.y / 10));
    shadowUpView.alpha = MIN(1, MAX(0, (scrollView.contentSize.height - (scrollView.contentOffset.y + scrollView.frame.size.height)) / 10));
}

@end
