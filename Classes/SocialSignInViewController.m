//
//  SocialSignInViewController.m
//  Nowmov
//
//  Created by Bill So on 24/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SocialSignInViewController.h"
#import "VideoPlaybackViewController.h"
#import "SHKSharer.h"
#import "SHKFacebook.h"
#import "SHKTwitter.h"
#import "NMVideo.h"


@implementation SocialSignInViewController

@synthesize videoViewController;

//
//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}
//
- (void)dealloc {
	[videoViewController release];
    [super dealloc];
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
- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"Connect";
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

- (IBAction)connectFacebook:(id)sender {
	// stop video playback
	[videoViewController stopVideo];
	NSString * urlStr;
	NMVideo * video = videoViewController.currentVideo;
	if ( [video.service_name isEqualToString:@"youtube"] ) {
		urlStr = [NSString stringWithFormat:@"http://www.youtube.com/watch?v=%@", video.service_external_id];
	} else if ( [video.service_name isEqualToString:@"vimeo"] ) {
		urlStr = [NSString stringWithFormat:@"http://vimeo.com/%@", video.service_external_id];
	}
	[SHKFacebook shareURL:[NSURL URLWithString:urlStr] title:video.title];
}

- (IBAction)connectTwitter:(id)sender {
	// stop video playback
	[videoViewController stopVideo];
	NSString * urlStr;
	NMVideo * video = videoViewController.currentVideo;
	if ( [video.service_name isEqualToString:@"youtube"] ) {
		urlStr = [NSString stringWithFormat:@"http://www.youtube.com/watch?v=%@", video.service_external_id];
	} else if ( [video.service_name isEqualToString:@"vimeo"] ) {
		urlStr = [NSString stringWithFormat:@"http://vimeo.com/%@", video.service_external_id];
	}
	[SHKTwitter shareURL:[NSURL URLWithString:urlStr] title:video.title];
}

@end
