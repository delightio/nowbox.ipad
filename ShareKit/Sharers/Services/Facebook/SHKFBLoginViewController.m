//
//  SHKFBLoginViewController.m
//  Nowmov
//
//  Created by Bill So on 26/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SHKFBLoginViewController.h"


@implementation SHKFBLoginViewController

@synthesize session;

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

- (id)initWithSession:(FBSession *)aSession {
	self = [super initWithNibName:nil bundle:nil];
	
	self.session = aSession;
	dialog = [[FBLoginDialog alloc] initWithSession:aSession];
	
	return self;
}

- (void)dealloc
{
	[session release];
	[dialog release];
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
- (void)loadView
{
	[self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)] autorelease] animated:NO];
	
	[dialog load];
	self.view = dialog;
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

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

- (void)cancel {
	[self dismissModalViewControllerAnimated:YES];
}

@end
