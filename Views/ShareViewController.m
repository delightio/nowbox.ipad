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
#import <QuartzCore/QuartzCore.h>

#define kMaxTwitterCharacters 119
#define kDefaultFacebookText @"Watch \"%@\""
#define kDefaultTwitterText @"Watch \"%@\" on @NOWBOX"

@implementation ShareViewController

@synthesize shareMode;
@synthesize messageText;
@synthesize characterCountLabel;
@synthesize socialNetworkToggle;
@synthesize progressView;
@synthesize video;
@synthesize duration;
@synthesize elapsedSeconds;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil video:(NMVideo *)aVideo duration:(NSInteger)aDuration elapsedSeconds:(NSInteger)anElapsedSeconds
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Message";
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)] autorelease];
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Post" style:UIBarButtonItemStyleDone target:self action:@selector(shareButtonPressed:)] autorelease];
        self.video = aVideo;
        self.duration = aDuration;
        self.elapsedSeconds = anElapsedSeconds;
        
        [self setContentSizeForViewInPopover:CGSizeMake(500, 200)];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(handleDidShareVideoNotification:) name:NMDidPostSharingNotification object:nil];
        [nc addObserver:self selector:@selector(handleDidFailShareVideoNotification:) name:NMDidFailPostSharingNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [messageText release];
    [characterCountLabel release];
    [socialNetworkToggle release];
    [progressView release];
    [video release];
    
    [super dealloc];
}

- (void)setShareMode:(ShareMode)aShareMode
{
    shareMode = aShareMode;
    
    NSString *defaultFacebookText = [NSString stringWithFormat:kDefaultFacebookText, video.title];
    NSString *defaultTwitterText = [NSString stringWithFormat:kDefaultTwitterText, video.title];
    
    if (shareMode == ShareModeFacebook) {
        self.navigationItem.rightBarButtonItem.title = @"Post";
        characterCountLabel.hidden = YES;
        
        if (video && ([messageText.text isEqualToString:defaultTwitterText] || [messageText.text length] == 0)) {
            messageText.text = defaultFacebookText;
        }
    } else {
        self.navigationItem.rightBarButtonItem.title = @"Tweet";
        characterCountLabel.hidden = NO;
        
        if (video && ([messageText.text isEqualToString:defaultFacebookText] || [messageText.text length] == 0)) {
            messageText.text = defaultTwitterText;
        }
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];    
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.shareMode = [userDefaults integerForKey:NM_LAST_SOCIAL_NETWORK];   
    socialNetworkToggle.selectedSegmentIndex = shareMode;
    
    progressView.layer.cornerRadius = 15.0;
    progressView.layer.masksToBounds = NO;
    
    [messageText becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];
	if (!viewPushedByNavigationController) {
		[[NSNotificationCenter defaultCenter] postNotificationName:NMChannelManagementWillAppearNotification object:self];
		viewPushedByNavigationController = YES;
	}
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self textViewDidChange:messageText];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:shareMode forKey:NM_LAST_SOCIAL_NETWORK];
    [userDefaults synchronize];
    
    [super viewWillDisappear:animated];
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
    self.socialNetworkToggle = nil;
    self.progressView = nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

#pragma mark - Actions

- (IBAction)cancelButtonPressed:(id)sender
{
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
            [self.navigationItem.rightBarButtonItem setEnabled:NO];
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
                [self.navigationItem.rightBarButtonItem setEnabled:NO];            
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
        }        
    }
}

- (IBAction)shareModeChanged:(id)sender
{
    if ([sender selectedSegmentIndex] == 0) {
        self.shareMode = ShareModeFacebook;
    } else {
        self.shareMode = ShareModeTwitter;
    }
}

#pragma mark - Notifications

- (void)handleDidShareVideoNotification:(NSNotification *)aNotification 
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:[NSString stringWithFormat:@"Your message was successfully %@.", (shareMode == ShareModeFacebook ? @"posted" : @"tweeted")]
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    
    progressView.hidden = YES;
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
}

- (void)handleDidFailShareVideoNotification:(NSNotification *)aNotification 
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:[NSString stringWithFormat:@"Sorry, but something went wrong and your message could not be %@. Please try again a bit later.", (shareMode == ShareModeFacebook ? @"posted" : @"tweeted")]
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    
    progressView.hidden = YES;
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
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
    if ([alertView numberOfButtons] == 1) {
        [self cancelButtonPressed:nil];
    } else if (buttonIndex == 1) {
        if (shareMode == ShareModeFacebook) {
            // Go to Facebook login page
            SocialLoginViewController *loginController = [[SocialLoginViewController alloc] initWithNibName:@"SocialLoginView" bundle:[NSBundle mainBundle]];
            loginController.loginType = NMLoginFacebookType;
            [self.navigationController pushViewController:loginController animated:YES];
            [loginController release];
            
            [[MixpanelAPI sharedAPI] track:AnalyticsEventStartFacebookLogin properties:[NSDictionary dictionaryWithObject:@"sharebutton" forKey:AnalyticsPropertySender]];
        } else {
            // Go to Twitter login page
            SocialLoginViewController *loginController = [[SocialLoginViewController alloc] initWithNibName:@"SocialLoginView" bundle:[NSBundle mainBundle]];
            loginController.loginType = NMLoginTwitterType;
            [self.navigationController pushViewController:loginController animated:YES];
            [loginController release];
            
            [[MixpanelAPI sharedAPI] track:AnalyticsEventStartTwitterLogin properties:[NSDictionary dictionaryWithObject:@"sharebutton" forKey:AnalyticsPropertySender]];
        }
    }
}

@end
