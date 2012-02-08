//
//  ShareViewController.m
//  ipad
//
//  Created by Chris Haugli on 11/7/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "ShareViewController.h"
#import "ipadAppDelegate.h"
#import "SocialLoginViewController.h"
#import "NMTaskQueueController.h"
#import "NMDataType.h"
#import "Analytics.h"
#import "ToolTipController.h"
#import "VideoPlaybackViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+InteractiveAnimation.h"

#define kMaxTwitterCharacters 119
#define kDefaultFacebookText @"Watching \"%@\""
#define kDefaultTwitterText @"Watching \"%@\""

@implementation ShareViewController

@synthesize shareMode;
@synthesize messageText;
@synthesize characterCountLabel;
@synthesize shareButton;
@synthesize progressView;
@synthesize video;
@synthesize duration;
@synthesize elapsedSeconds;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil video:(NMVideo *)aVideo shareMode:(ShareMode)aShareMode duration:(NSInteger)aDuration elapsedSeconds:(NSInteger)anElapsedSeconds
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)] autorelease];
        self.video = aVideo;
        self.shareMode = aShareMode;
        self.duration = aDuration;
        self.elapsedSeconds = anElapsedSeconds;

        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(handleDidShareVideoNotification:) name:NMDidPostSharingNotification object:nil];
        [nc addObserver:self selector:@selector(handleDidFailShareVideoNotification:) name:NMDidFailPostSharingNotification object:nil];
        [nc addObserver:self selector:@selector(handleSocialMediaLoginNotification:) name:NMDidVerifyUserNotification object:nil];
        
        videoAlreadyFavorited = [aVideo.nm_favorite boolValue];
        
        self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Message"
                                                                                  style:UIBarButtonItemStyleBordered
                                                                                 target:nil
                                                                                 action:nil] autorelease];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [messageText release];
    [characterCountLabel release];
    [shareButton release];
    [progressView release];
    [video release];
    
    [super dealloc];
}

- (void)setShareMode:(ShareMode)aShareMode
{
    shareMode = aShareMode;

    if (shareMode == ShareModeFacebook) {
        self.title = @"Facebook";
        [shareButton setTitle:@"POST" forState:UIControlStateNormal];
        characterCountLabel.hidden = YES;
        messageText.text = [NSString stringWithFormat:kDefaultFacebookText, video.title];            
    } else {
        self.title = @"Twitter";
        [shareButton setTitle:@"TWEET" forState:UIControlStateNormal];
        characterCountLabel.hidden = NO;
        messageText.text = [NSString stringWithFormat:kDefaultTwitterText, video.title];            
    }
}

- (void)showLoginPage
{
    UIView *superview = self.navigationController.view.superview;
    
    // Hide shadow flicker when resizing
    float oldShadowOpacity = superview.layer.shadowOpacity;
    
    void (^completion)(BOOL) = ^(BOOL finished){
        superview.layer.shadowOpacity = oldShadowOpacity;
        
        // Go to Twitter/FB login page
        SocialLoginViewController *loginController = [[SocialLoginViewController alloc] initWithNibName:@"SocialLoginView" bundle:[NSBundle mainBundle]];
        loginController.navigationItem.backBarButtonItem.title = @"Back";
        NMSocialLoginType loginType;
        NSString *analyticsEvent;
        
        if (shareMode == ShareModeTwitter) {
            loginType = NMLoginTwitterType;
            analyticsEvent = AnalyticsEventStartTwitterLogin;
        } else {
            loginType = NMLoginFacebookType;
            analyticsEvent = AnalyticsEventStartFacebookLogin;
        }
        
        loginController.loginType = loginType;
        [self.navigationController pushViewController:loginController animated:YES];
        [loginController release];
        
        [[MixpanelAPI sharedAPI] track:analyticsEvent properties:[NSDictionary dictionaryWithObject:@"sharebutton" forKey:AnalyticsPropertySender]];
    };
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Make view taller so login page fits
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             superview.layer.shadowOpacity = 0;                                 
                             superview.bounds = CGRectMake(0, 0, 500, 525);
                             
                             UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
                             
                             CGRect frame = superview.frame;
                             frame.origin.x = (statusBarOrientation == UIInterfaceOrientationLandscapeRight ? [[UIScreen mainScreen] bounds].size.width - frame.size.width - 20 : 20);
                             superview.frame = frame;
                         }
                         completion:completion];  
    } else {
        completion(NO);
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];    
    
    [self setShareMode:shareMode];

    progressView.layer.cornerRadius = 15.0;
    progressView.layer.masksToBounds = NO;
    
    [self textViewDidChange:messageText];
    [messageText becomeFirstResponder];
    
    UIFont *condensedFont = [UIFont fontWithName:@"Futura-CondensedMedium" size:16.0f];
    if (condensedFont) {
        [shareButton.titleLabel setFont:condensedFont];
    }
}

- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];
	if (!viewPushedByNavigationController) {
		[[NSNotificationCenter defaultCenter] postNotificationName:NMChannelManagementWillAppearNotification object:self];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
        
    if (autoPost) {
        [self shareButtonPressed:nil];
        autoPost = NO;
    }
    
    if (!viewPushedByNavigationController || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        viewPushedByNavigationController = YES;
    } else {
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             // Return to original size
                             UIView *superview = self.navigationController.view.superview;
                             superview.bounds = CGRectMake(0, 0, 500, 325);

                             UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];

                             CGRect frame = superview.frame;
                             frame.origin.x = (statusBarOrientation == UIInterfaceOrientationLandscapeRight ? [[UIScreen mainScreen] bounds].size.width - frame.size.width - 40 : 40);
                             superview.frame = frame;
                         }
                         completion:^(BOOL finished){
                         }];     
    }
}

- (void)viewDidDisappear:(BOOL)animated 
{
	[super viewDidDisappear:animated];
	if (!viewPushedByNavigationController) {
		[[NSNotificationCenter defaultCenter] postNotificationName:NMChannelManagementDidDisappearNotification object:self];
	}
}

- (void)viewDidUnload
{
    self.messageText = nil;
    self.characterCountLabel = nil;
    self.progressView = nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
    } else {
        return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
    }
}

#pragma mark - Actions

- (IBAction)cancelButtonPressed:(id)sender
{
    [[MixpanelAPI sharedAPI] track:AnalyticsEventCancelShareDialog properties:[NSDictionary dictionaryWithObjectsAndKeys:video.title, AnalyticsPropertyVideoName, 
                                                                               video.nm_id, AnalyticsPropertyVideoId,
                                                                               (shareMode == ShareModeTwitter ? @"Twitter" : @"Facebook"), AnalyticsPropertyShareType,
                                                                               nil]];

    viewPushedByNavigationController = NO;
    [self dismissModalViewControllerAnimated:YES];    
}

- (IBAction)shareButtonPressed:(id)sender
{
    if (shareMode == ShareModeFacebook) {
        if (NM_USER_FACEBOOK_CHANNEL_ID != 0) {
            // Post on Facebook
            [[NMTaskQueueController sharedTaskQueueController] issueShareWithService:NMLoginFacebookType
                                                                               video:video 
                                                                            duration:duration
                                                                      elapsedSeconds:elapsedSeconds
                                                                             message:messageText.text];
            progressView.hidden = NO;
            [shareButton setEnabled:NO];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil 
                                                                message:@"You are not logged in to Facebook. Would you like to log in now?"
                                                               delegate:self
                                                      cancelButtonTitle:@"No Thanks"
                                                      otherButtonTitles:@"Log In", nil];
            [alertView show];
            [alertView release];
        }
    } else {
        if (NM_USER_TWITTER_CHANNEL_ID != 0) {
            // Post on Twitter
            NSInteger remainingCharacters = kMaxTwitterCharacters - [[messageText text] length];
            if (remainingCharacters >= 0) {
                [[NMTaskQueueController sharedTaskQueueController] issueShareWithService:NMLoginTwitterType
                                                                                   video:video 
                                                                                duration:duration
                                                                          elapsedSeconds:elapsedSeconds
                                                                                 message:messageText.text];
                progressView.hidden = NO;
                [shareButton setEnabled:NO];            
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                    message:[NSString stringWithFormat:@"Sorry, but your message is too long. Try something a bit shorter.", (shareMode == ShareModeFacebook ? @"posted" : @"tweeted")]
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [alertView show];
                [alertView release];
            }
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil 
                                                                message:@"You are not logged in to Twitter. Would you like to log in now?"
                                                               delegate:self
                                                      cancelButtonTitle:@"No Thanks"
                                                      otherButtonTitles:@"Log In", nil];
            [alertView show];
            [alertView release];
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                [messageText resignFirstResponder];
            }
        }        
    }
}

#pragma mark - Notifications

- (void)handleDidShareVideoNotification:(NSNotification *)aNotification 
{
    void (^completion)(void) = ^{
        [self cancelButtonPressed:nil];
        [self performSelector:@selector(delayedNotifyShareVideo) withObject:nil afterDelay:0.3];                
    };
    
    if ([[(ipadAppDelegate *)[[UIApplication sharedApplication] delegate] viewController] isKindOfClass:[VideoPlaybackViewController class]]) {
    
        VideoPlaybackViewController *playbackController = (VideoPlaybackViewController *)[(ipadAppDelegate *)[[UIApplication sharedApplication] delegate] viewController];
    
        // Show "rate us" reminder after the second time a user shares a video
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setInteger:++NM_SHARE_COUNT forKey:NM_SHARE_COUNT_KEY];
        [userDefaults synchronize];
    
        if ([playbackController shouldShowRateUsReminder] && NM_SHARE_COUNT == 2) {
            [playbackController showRateUsReminderCompletion:completion];
        } else {
            completion();
        }
    }
    progressView.hidden = YES;
    [shareButton setEnabled:YES];
    
    [[MixpanelAPI sharedAPI] track:AnalyticsEventCompleteShareDialog properties:[NSDictionary dictionaryWithObjectsAndKeys:video.title, AnalyticsPropertyVideoName, 
                                                                             video.nm_id, AnalyticsPropertyVideoId,
                                                                             (shareMode == ShareModeTwitter ? @"Twitter" : @"Facebook"), AnalyticsPropertyShareType,
                                                                             nil]];
}

- (void)handleDidFailShareVideoNotification:(NSNotification *)aNotification 
{
    NSDictionary *userInfo = [aNotification userInfo];
    NSInteger statusCode = [[userInfo objectForKey:@"code"] integerValue];
    
    if (statusCode == 400) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil 
                                                            message:@"Sorry, but something went wrong and your message could not be posted. Please try logging in again."
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Log In", nil];
        [alertView show];
        [alertView release];
        [messageText resignFirstResponder];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:[NSString stringWithFormat:@"Sorry, but something went wrong and your message could not be %@. Please try again a bit later.", (shareMode == ShareModeFacebook ? @"posted" : @"tweeted")]
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        alertView.tag = -1;
        [alertView show];
        [alertView release];        
    }
    
    progressView.hidden = YES;
    [shareButton setEnabled:YES];
    
    [[MixpanelAPI sharedAPI] track:AnalyticsEventShareFailed properties:[NSDictionary dictionaryWithObjectsAndKeys:video.title, AnalyticsPropertyVideoName, 
                                                                         video.nm_id, AnalyticsPropertyVideoId,
                                                                         (shareMode == ShareModeTwitter ? @"Twitter" : @"Facebook"), AnalyticsPropertyShareType,
                                                                         nil]];
}

- (void)handleSocialMediaLoginNotification:(NSNotification *)aNotification 
{
    autoPost = YES;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    NSInteger remainingCharacters = kMaxTwitterCharacters - [[textView text] length];
    characterCountLabel.text = [NSString stringWithFormat:@"%i", remainingCharacters];
    
    if (remainingCharacters < 0) {
        characterCountLabel.textColor = [UIColor redColor];
    } else {
        characterCountLabel.textColor = [UIColor blackColor];
    }        
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self showLoginPage];
    }
}

- (void)delayedNotifyShareVideo
{
    switch (shareMode) {
        case ShareModeFacebook:
            [[ToolTipController sharedToolTipController] notifyEvent:ToolTipEventShareFacebook sender:nil];        
            break;
        case ShareModeTwitter:
            [[ToolTipController sharedToolTipController] notifyEvent:ToolTipEventShareTwitter sender:nil];        
            break;
        default:
            break;
    }
}

@end
