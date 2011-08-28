//
//  TwitterLoginViewController.m
//  ipad
//
//  Created by Bill So on 14/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "TwitterLoginViewController.h"

@implementation TwitterLoginViewController
@synthesize loginWebView;

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
	[loginWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://api.nowmov.com/auth/twitter"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0f]];
	
	self.title = @"Login in Twitter";
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
    [loginWebView release];
    [super dealloc];
}

#pragma mark Webview delegate methods
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	NSLog(@"%@", [request URL]);
	return YES;
}
@end
