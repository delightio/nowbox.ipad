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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setContentSizeForViewInPopover:CGSizeMake(500, 500)];
    }
    return self;
}

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
	    
    loadingPageLoading = YES;
	NSString * filename = nil;
	switch (loginType) {
		case NMLoginTwitterType:
			self.title = @"Twitter";
			filename = @"TwitterLoading";
			break;
			
		case NMLoginFacebookType:
			self.title = @"Facebook";
			filename = @"FacebookLoading";
			break;
			
		case NMLoginYouTubeType:
			self.title = @"YouTube";
			filename = @"YoutubeLoading";
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	NSHTTPCookie *cookie;
	NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	for (cookie in [storage cookies]) {
		[storage deleteCookie:cookie];
	}
	[progressContainerView release];
    [loginWebView release];
    [super dealloc];
}

#pragma mark Notificaiton handler
- (void)delayPushOutView {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)delayShowYouTubeErroView {
	progressContainerView.alpha = 0.0f;
	NSURL * theURL = [[NSBundle mainBundle] URLForResource:@"YoutubeError" withExtension:@"html"];
	[loginWebView loadRequest:[NSURLRequest requestWithURL:theURL]];
	self.navigationItem.hidesBackButton = NO;
}

- (void)handleSocialMediaLoginNotificaiton:(NSNotification *)aNotificaiton {
	// save the user
	NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
	// user stream channels
	[defs setInteger:NM_USER_FACEBOOK_CHANNEL_ID forKey:NM_USER_FACEBOOK_CHANNEL_ID_KEY];
	[defs setInteger:NM_USER_TWITTER_CHANNEL_ID forKey:NM_USER_TWITTER_CHANNEL_ID_KEY];
	[defs setInteger:NM_USER_FAVORITES_CHANNEL_ID forKey:NM_USER_FAVORITES_CHANNEL_ID_KEY];
	[defs setInteger:NM_USER_WATCH_LATER_CHANNEL_ID forKey:NM_USER_WATCH_LATER_CHANNEL_ID_KEY];
	[defs setInteger:NM_USER_HISTORY_CHANNEL_ID forKey:NM_USER_HISTORY_CHANNEL_ID_KEY];
	//uid
	[defs setInteger:NM_USER_ACCOUNT_ID forKey:NM_USER_ACCOUNT_ID_KEY];
	[defs setBool:NM_USER_YOUTUBE_SYNC_ACTIVE forKey:NM_USER_YOUTUBE_SYNC_ACTIVE_KEY];
	[defs setObject:NM_USER_YOUTUBE_USER_NAME forKey:NM_USER_YOUTUBE_USER_NAME_KEY];
	[defs setInteger:NM_USER_YOUTUBE_LAST_SYNC forKey:NM_USER_YOUTUBE_LAST_SYNC_KEY];
	[defs synchronize];
    
    [[MixpanelAPI sharedAPI] registerSuperProperties:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:(NM_USER_FACEBOOK_CHANNEL_ID != 0)], AnalyticsPropertyAuthFacebook,
                                                      [NSNumber numberWithBool:(NM_USER_TWITTER_CHANNEL_ID != 0)], AnalyticsPropertyAuthTwitter, nil]];
    switch (loginType) {
        case NMLoginTwitterType:
		{
            [[MixpanelAPI sharedAPI] track:AnalyticsEventCompleteTwitterLogin];
            [[MixpanelAPI sharedAPI] track:AnalyticsEventSubscribeChannel properties:[NSDictionary dictionaryWithObjectsAndKeys:@"Twitter", AnalyticsPropertyChannelName,
                                                                                      @"channelmanagement_login", AnalyticsPropertySender, 
                                                                                      [NSNumber numberWithBool:YES], AnalyticsPropertySocialChannel, nil]];
			// channel refresh command is issued in TaskQueueScheduler
			
			// listen to channel refresh notification 
			NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
			[nc addObserver:self selector:@selector(handleChannelRefreshNotification:) name:NMDidGetChannelsNotification object:nil];
			[nc addObserver:self selector:@selector(handleChannelRefreshNotification:) name:NMDidFailGetChannelsNotification object:nil];
           break;
		}
			
        case NMLoginFacebookType:
		{
            [[MixpanelAPI sharedAPI] track:AnalyticsEventCompleteFacebookLogin];
            [[MixpanelAPI sharedAPI] track:AnalyticsEventSubscribeChannel properties:[NSDictionary dictionaryWithObjectsAndKeys:@"Facebook", AnalyticsPropertyChannelName,
                                                                                      @"channelmanagement_login", AnalyticsPropertySender, 
                                                                                      [NSNumber numberWithBool:YES], AnalyticsPropertySocialChannel, nil]];
			// channel refresh command is issued in TaskQueueScheduler
			
			// listen to channel refresh notification 
			NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
			[nc addObserver:self selector:@selector(handleChannelRefreshNotification:) name:NMDidGetChannelsNotification object:nil];
			[nc addObserver:self selector:@selector(handleChannelRefreshNotification:) name:NMDidFailGetChannelsNotification object:nil];
           break;
		}
			
		case NMLoginYouTubeType:
            [[MixpanelAPI sharedAPI] track:AnalyticsEventCompleteYouTubeLogin];
            [[MixpanelAPI sharedAPI] track:AnalyticsEventSubscribeChannel properties:[NSDictionary dictionaryWithObjectsAndKeys:@"YouTube", AnalyticsPropertyChannelName,
																					@"channelmanagement_login", AnalyticsPropertySender, 
																					[NSNumber numberWithBool:YES], AnalyticsPropertySocialChannel, nil]];
			// dismiss the view right away
			progressLabel.text = @"Verified Successfully";
			[loadingIndicator stopAnimating];
			[self performSelector:@selector(delayPushOutView) withObject:nil afterDelay:1.5];
			break;
			
        default:
            break;
    }
}

- (void)handleChannelRefreshNotification:(NSNotification *)aNotification {
	progressLabel.text = @"Verified Successfully";
	[loadingIndicator stopAnimating];
	[self performSelector:@selector(delayPushOutView) withObject:nil afterDelay:1.5];
}

- (void)handleLoginFailNotification:(NSNotification *)aNotification {
	progressLabel.text = @"Verification Process Failed";
	[loadingIndicator stopAnimating];
	if ( loginType == NMLoginYouTubeType ) {
		// show a longer error view
		[self performSelector:@selector(delayShowYouTubeErroView) withObject:nil afterDelay:1.0];
	} else {
		[self performSelector:@selector(delayPushOutView) withObject:nil afterDelay:1.0];
	}
    
    switch (loginType) {
        case NMLoginTwitterType:
            [[MixpanelAPI sharedAPI] track:AnalyticsEventTwitterLoginFailed];
            break;
        case NMLoginFacebookType:
            [[MixpanelAPI sharedAPI] track:AnalyticsEventFacebookLoginFailed];
            break;
		case NMLoginYouTubeType:
            [[MixpanelAPI sharedAPI] track:AnalyticsEventYouTubeLoginFailed];
			break;
        default:
            break;
    }
}

#pragma mark Webview delegate methods
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	NSURL * theURL = [request URL];
	switch (loginType) {
		case NMLoginTwitterType:
		{
//			NSLog(@"Twitter URL: %@", [theURL absoluteString]);
			if ( [[theURL host] isEqualToString:NM_BASE_URL_TOKEN] && [[theURL path] isEqualToString:@"/auth/twitter/callback"] ) {
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
			
		case NMLoginFacebookType:
		{
//			NSLog(@"Facebook URL: %@", [theURL absoluteString]);
			if ( [[theURL host] isEqualToString:NM_BASE_URL_TOKEN] && [[theURL path] isEqualToString:@"/auth/facebook/callback"] ) {
				self.navigationItem.hidesBackButton = YES;
				// we should intercept this call. Use task queue scheduler.
				// pass the interface control back the the channel management view controller
				progressContainerView.alpha = 0.0f;
				progressContainerView.frame = self.view.bounds;
				[self.view addSubview:progressContainerView];
				
				// create the new URL by inserting the user ID
				NSArray * ay = [[theURL absoluteString] componentsSeparatedByString:@"#"];
				NSString * urlStr = [NSString stringWithFormat:@"%@&user_id=%d", [ay objectAtIndex:0], NM_USER_ACCOUNT_ID];
//				NSLog(@"Facebook verification URL: %@", urlStr);
				
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
			
		case NMLoginYouTubeType:
		{
//			NSLog(@"YouTube URL: %@", [theURL absoluteString]);
			if ( [[theURL host] isEqualToString:NM_BASE_URL_TOKEN] && [[theURL path] isEqualToString:@"/auth/you_tube/callback"] ) {
				self.navigationItem.hidesBackButton = YES;
				// we should intercept this call. Use task queue scheduler.
				// pass the interface control back the the channel management view controller
				progressContainerView.alpha = 0.0f;
				progressContainerView.frame = self.view.bounds;
				[self.view addSubview:progressContainerView];
				// show a dark gray screen for now.
				[[NMTaskQueueController sharedTaskQueueController] issueVerifyYouTubeAccountWithURL:theURL];
				
				[UIView animateWithDuration:0.25f animations:^{
					progressContainerView.alpha = 1.0f;
				} completion:^(BOOL finished) {
					[loadingIndicator startAnimating];
				}];
				
				return NO;
			} else {
				NSString * urlStr = [theURL absoluteString];
				if ( urlStr ) {
					NSRange rng = [urlStr rangeOfString:@"ltmpl=sso"];
					if ( rng.location != NSNotFound ) {
						// need to modify this
						urlStr = [urlStr stringByReplacingCharactersInRange:rng withString:@"ltmpl=mobile"];
						NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
						[webView performSelector:@selector(loadRequest:) withObject:request afterDelay:0.0];
						return NO;
					}
				}
			}
			break;
		}
			
		default:
			break;
	}
	return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (loadingPageLoading) {
        loadingPageLoading = NO;
        
		NSString * urlStr = nil;
		switch (loginType) {
			case NMLoginTwitterType:
				urlStr = [NSString stringWithFormat:@"http://%@/auth/twitter?user_id=%d", NM_BASE_URL_TOKEN, NM_USER_ACCOUNT_ID];
				break;
				
			case NMLoginFacebookType:
				urlStr = [NSString stringWithFormat:@"http://%@/auth/facebook", NM_BASE_URL_TOKEN];
				break;
				
			case NMLoginYouTubeType:
				urlStr = [NSString stringWithFormat:@"http://%@/auth/you_tube?user_id=%d", NM_BASE_URL_TOKEN, NM_USER_ACCOUNT_ID];
				break;
				
			default:
				break;
		}
		
		[loginWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0f]];
    }
}

@end
