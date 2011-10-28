//
//  TwitterLoginViewController.m
//  ipad
//
//  Created by Bill So on 14/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "SocialLoginViewController.h"
#import "ipadAppDelegate.h"
#import "NMLibrary.h"

@implementation SocialLoginViewController
@synthesize loginWebView, progressContainerView;
@synthesize loginType;

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	
	NSString * filename = nil;
	switch (loginType) {
		case LoginTwitterType:
			self.title = @"Twitter";
			filename = @"TwitterLoading";
			break;
			
		case LoginFacebookType:
			self.title = @"Facebook";
			filename = @"FacebookLoading";
			break;
			
		default:
			break;
	}
	NSURL * theURL = [[NSBundle mainBundle] URLForResource:filename withExtension:@"html"];
	[loginWebView loadRequest:[NSURLRequest requestWithURL:theURL]];
	
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleSocialMediaLoginNotificaiton:) name:NMDidVerifyUserNotification object:nil];
	[nc addObserver:self selector:@selector(handleLoginFailNotification:) name:NMDidFailVerifyUserNotification object:nil];
}

- (void)viewDidUnload
{
    [self setLoginWebView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	NSString * urlStr = nil;
	switch (loginType) {
		case LoginTwitterType:
			urlStr = [NSString stringWithFormat:@"http://api.nowbox.com/auth/twitter?user_id=%d", NM_USER_ACCOUNT_ID];
			break;
			
		case LoginFacebookType:
			urlStr = @"http://api.nowbox.com/auth/facebook";
			break;
			
		default:
			break;
	}
	
	[loginWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0f]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[progressContainerView release];
    [loginWebView release];
    [super dealloc];
}

#pragma mark Notificaiton handler
- (void)delayPushOutView {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)handleSocialMediaLoginNotificaiton:(NSNotification *)aNotificaiton {
	// save the user
	NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
	[defs setInteger:NM_USER_FACEBOOK_CHANNEL_ID forKey:NM_USER_FACEBOOK_CHANNEL_ID_KEY];
	[defs setInteger:NM_USER_TWITTER_CHANNEL_ID forKey:NM_USER_TWITTER_CHANNEL_ID_KEY];
	[defs setInteger:NM_USER_ACCOUNT_ID forKey:NM_USER_ACCOUNT_ID_KEY];
    
    [[MixpanelAPI sharedAPI] registerSuperProperties:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:(NM_USER_FACEBOOK_CHANNEL_ID != 0)], @"auth_facebook",
                                                      [NSNumber numberWithBool:(NM_USER_TWITTER_CHANNEL_ID != 0)], @"auth_twitter", nil]];
    switch (loginType) {
        case LoginTwitterType:
            [[MixpanelAPI sharedAPI] track:@"Complete Twitter Login"];
            [[MixpanelAPI sharedAPI] track:@"Subscribe Channel" properties:[NSDictionary dictionaryWithObjectsAndKeys:@"Twitter", @"channel_name",
                                                                            @"channelmanagement_login", @"sender", 
                                                                            [NSNumber numberWithBool:YES], @"social_channel", nil]];

            break;
        case LoginFacebookType:
            [[MixpanelAPI sharedAPI] track:@"Complete Facebook Login"];
            [[MixpanelAPI sharedAPI] track:@"Subscribe Channel" properties:[NSDictionary dictionaryWithObjectsAndKeys:@"Facebook", @"channel_name",
                                                                            @"channelmanagement_login", @"sender", 
                                                                            [NSNumber numberWithBool:YES], @"social_channel", nil]];

            break;
        default:
            break;
    }
	// channel refresh command is issued in TaskQueueScheduler
	
	// listen to channel refresh notification 
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleChannelRefreshNotification:) name:NMDidGetChannelsNotification object:nil];
	[nc addObserver:self selector:@selector(handleChannelRefreshNotification:) name:NMDidFailGetChannelsNotification object:nil];
}

- (void)handleChannelRefreshNotification:(NSNotification *)aNotification {
	progressLabel.text = @"Verified Successfully";
	[loadingIndicator stopAnimating];
	[self performSelector:@selector(delayPushOutView) withObject:nil afterDelay:1.5f];
}

- (void)handleLoginFailNotification:(NSNotification *)aNotification {
	progressLabel.text = @"Verification Process Failed";
	[loadingIndicator stopAnimating];
	[self performSelector:@selector(delayPushOutView) withObject:nil afterDelay:1.0f];
    
    switch (loginType) {
        case LoginTwitterType:
            [[MixpanelAPI sharedAPI] track:@"Twitter Login Failed"];
            break;
        case LoginFacebookType:
            [[MixpanelAPI sharedAPI] track:@"Facebook Login Failed"];
            break;
        default:
            break;
    }
}

#pragma mark Webview delegate methods
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	NSURL * theURL = [request URL];
	switch (loginType) {
		case LoginTwitterType:
		{
			NSLog(@"Twitter URL: %@", [theURL absoluteString]);
			if ( [[theURL host] isEqualToString:@"api.nowbox.com"] && [[theURL path] isEqualToString:@"/auth/twitter/callback"] ) {
				self.navigationItem.hidesBackButton = YES;
				// we should intercept this call. Use task queue scheduler.
				// pass the interface control back the the channel management view controller
				progressContainerView.alpha = 0.0f;
				progressContainerView.frame = self.view.bounds;
				[self.view addSubview:progressContainerView];
				// show a dark gray screen for now.
				[[NMTaskQueueController sharedTaskQueueController] issueVerifyTwitterAccountWithURL:theURL];
				
				[UIView animateWithDuration:0.25f animations:^{
					progressContainerView.alpha = 1.0f;
				} completion:^(BOOL finished) {
					[loadingIndicator startAnimating];
				}];
				
				return NO;
			}
			break;
		}
			
		case LoginFacebookType:
		{
			NSLog(@"Facebook URL: %@", [theURL absoluteString]);
			if ( [[theURL host] isEqualToString:@"api.nowbox.com"] && [[theURL path] isEqualToString:@"/auth/facebook/callback"] ) {
				self.navigationItem.hidesBackButton = YES;
				// we should intercept this call. Use task queue scheduler.
				// pass the interface control back the the channel management view controller
				progressContainerView.alpha = 0.0f;
				progressContainerView.frame = self.view.bounds;
				[self.view addSubview:progressContainerView];
				
				// create the new URL by inserting the user ID
				NSArray * ay = [[theURL absoluteString] componentsSeparatedByString:@"#"];
				NSString * urlStr = [NSString stringWithFormat:@"%@&user_id=%d", [ay objectAtIndex:0], NM_USER_ACCOUNT_ID];
				NSLog(@"Facebook verification URL: %@", urlStr);
				
				// show a dark gray screen for now.
				[[NMTaskQueueController sharedTaskQueueController] issueVerifyFacebookAccountWithURL:[NSURL URLWithString:urlStr]];
				
				[UIView animateWithDuration:0.25f animations:^{
					progressContainerView.alpha = 1.0f;
				} completion:^(BOOL finished) {
					[loadingIndicator startAnimating];
				}];
				
				return NO;
			}
			break;
		}
			
		default:
			break;
	}
	return YES;
}
@end
