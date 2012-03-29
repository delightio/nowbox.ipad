//
//  LaunchViewController.m
//  ipad
//
//  Created by Chris Haugli on 2/7/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "LaunchViewController.h"

@implementation LaunchViewController

@synthesize delegate;

- (void)setup
{    
    launchController = [[LaunchController_iPhone alloc] init];
    ((LaunchController_iPhone *)launchController).delegate = self;
    ((LaunchController_iPhone *)launchController).viewController = self;
    [launchController loadView];    
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    [launchController release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - LaunchControllerDelegate

- (void)launchControllerDidFinish:(LaunchController *)launchController
{
    [delegate launchViewControllerDidFinish:self];
}

@end
