//
//  TwitterSignInViewController.m
//  ipad
//
//  Created by Bill So on 31/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TwitterSignInViewController.h"


@implementation TwitterSignInViewController

@synthesize requestToken, accessToken, callbackURLString;

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

- (void)dealloc
{
	[callbackURLString release];
	[consumer release];
	[requestToken release];
	[accessToken release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	// create container view
	UIView * ctnView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 480.0, 480.0)];
	// show progress view
	UIActivityIndicatorView * act = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[act startAnimating];
	act.center = CGPointMake(240.0, 240.0);
	act.tag = 1001;
	[ctnView addSubview:act];
	self.view = ctnView;
	[ctnView release];
	
	NSDictionary * infoDict = [[NSBundle mainBundle] infoDictionary];
	self.callbackURLString = [infoDict objectForKey:@"TwitterCallbackURL"];
	// make request to get access token
	consumer = [[OAConsumer alloc] initWithKey:[infoDict objectForKey:@"TwitterConsumerKey"] secret:[infoDict objectForKey:@"TwitterConsumerSecret"]];
    OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://twitter.com/oauth/request_token"] consumer:consumer token:nil realm:nil signatureProvider:nil];
	
	
	[oRequest setHTTPMethod:@"POST"];
		
    OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest delegate:self didFinishSelector:@selector(tokenRequestTicket:didFinishWithData:) didFailSelector:@selector(tokenRequestTicket:didFailWithError:)];
	[fetcher start];
	[oRequest release];
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	// create the web view
	webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
	webView.delegate = self;
	webView.scalesPageToFit = YES;
	webView.dataDetectorTypes = UIDataDetectorTypeNone;
	[self.view insertSubview:webView belowSubview:[self.view viewWithTag:1001]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)loadAuthorizationPage {	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://twitter.com/oauth/authorize?oauth_token=%@", requestToken.key]];
	
	[webView loadRequest:[NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0]];
	
}

#pragma mark Fetch Token Delegate
- (void)tokenRequestTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
	
	if (ticket.didSucceed) {
		NSString *responseBody = [[NSString alloc] initWithData:data
													   encoding:NSUTF8StringEncoding];
		self.requestToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
		[responseBody release];
		
		[self loadAuthorizationPage];
	} else {
		[self tokenRequestTicket:ticket didFailWithError:nil];
	}
}

- (void)tokenRequestTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error {
	// fail to get request token from twitter server. probably lost wifi connection or twitter server is down
}

#pragma mark WebView Delegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{		
	if ([request.URL.absoluteString rangeOfString:callbackURLString].location != NSNotFound)
	{
		// Get query
		NSMutableDictionary *queryParams = nil;
		if (request.URL.query != nil)
		{
			queryParams = [NSMutableDictionary dictionaryWithCapacity:0];
			NSArray *vars = [request.URL.query componentsSeparatedByString:@"&"];
			NSArray *parts;
			for(NSString *var in vars)
			{
				parts = [var componentsSeparatedByString:@"="];
				if (parts.count == 2)
					[queryParams setObject:[parts objectAtIndex:1] forKey:[parts objectAtIndex:0]];
			}
		}
		
		//TODO: Finish authorization successfully!! save stuff
//		[delegate tokenAuthorizeView:self didFinishWithSuccess:YES queryParams:queryParams error:nil];
//		self.delegate = nil;
		
		return NO;
	}
	
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	[self startSpinner];
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{	
	[self stopSpinner];
	
	// Extra sanity check for Twitter OAuth users to make sure they are using BROWSER with a callback instead of pin based auth
	if ([webView.request.URL.host isEqualToString:@"twitter.com"] && [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('oauth_pin').innerHTML"].length) {
		[self tokenAuthorizeView:self didFinishWithSuccess:NO queryParams:nil error:nil];
	}
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{	
	if ([error code] != NSURLErrorCancelled && [error code] != 102 && [error code] != NSURLErrorFileDoesNotExist)
	{
		[self stopSpinner];
		[self tokenAuthorizeView:self didFinishWithSuccess:NO queryParams:nil error:error];
	}
}

@end
