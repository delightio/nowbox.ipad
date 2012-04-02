//
//  FacebookLoginViewController.m
//  ipad
//
//  Created by Chris Haugli on 3/30/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "FacebookLoginViewController.h"
#import "GridViewController.h"
#import "FacebookGridDataSource.h"
#import "NMAccountManager.h"
#import "NMDataType.h"
#import "Analytics.h"
#import "UIFont+BackupFont.h"
#import "ipadAppDelegate.h"

@interface FacebookLoginViewController (PrivateMethods)
- (void)showGridAnimated:(BOOL)animated;
- (void)beginNewSession;
@end

@implementation FacebookLoginViewController

@synthesize connectFacebookButton;
@synthesize activityIndicator;
@synthesize managedObjectContext;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aManagedObjectContext nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.managedObjectContext = aManagedObjectContext;
        [self beginNewSession];
    }
    return self;
}

- (void)dealloc
{
    @try {
        [[NMAccountManager sharedAccountManager] removeObserver:self forKeyPath:@"facebookAccountStatus"];
    } @catch (NSException *exception) {
        
    }
    
    [connectFacebookButton release];
    [activityIndicator release];
    [managedObjectContext release];
    
    [super dealloc];
}

- (void)beginNewSession {
	// start a new session
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    NSInteger sid = [df integerForKey:NM_SESSION_ID_KEY];
	NSDate * theDate = [df objectForKey:NM_LAST_SESSION_DATE];
	if ( [theDate timeIntervalSinceNow] < -NM_SESSION_DURATION ) {	// 30 min
		[[NMTaskQueueController sharedTaskQueueController] beginNewSession:++sid];
		[df setInteger:sid forKey:NM_SESSION_ID_KEY];
	} else {
		// use the same session
		[[NMTaskQueueController sharedTaskQueueController] resumeSession:sid];
	}
    [df synchronize];
}

- (void)showGridAnimated:(BOOL)animated
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:NM_FIRST_LAUNCH_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
	[NMTaskQueueController sharedTaskQueueController].appFirstLaunch = NO;
    
    GridDataSource *dataSource = [[FacebookGridDataSource alloc] initWithGridView:nil managedObjectContext:self.managedObjectContext];
    GridViewController *gridViewController = [[GridViewController alloc] initWithDataSource:dataSource managedObjectContext:self.managedObjectContext nibName:@"GridViewController" bundle:nil];
    [self.navigationController pushViewController:gridViewController animated:animated];
    [gridViewController release];
    [dataSource release];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    connectFacebookButton.titleLabel.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:24.0 backupFontName:@"Futura-Medium" size:22.0];
    
    NMSyncStatusType syncStatus = [[NMAccountManager sharedAccountManager].facebookAccountStatus integerValue];
    if (syncStatus > 0) {
        // User is already logged in
        [self showGridAnimated:NO];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.connectFacebookButton = nil;
    self.activityIndicator = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (IBAction)loginToFacebook:(id)sender
{
    [[NMAccountManager sharedAccountManager] addObserver:self forKeyPath:@"facebookAccountStatus" options:0 context:(void *)1002];

    [activityIndicator startAnimating];
    [UIView animateWithDuration:0.2 animations:^{
        connectFacebookButton.alpha = 0;
    }];
    
    [[NMAccountManager sharedAccountManager] authorizeFacebook];
    [[MixpanelAPI sharedAPI] track:AnalyticsEventStartFacebookLogin properties:[NSDictionary dictionaryWithObject:@"onboard" forKey:AnalyticsPropertySender]];        
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	NSInteger ctxInt = (NSInteger)context;
	NMSyncStatusType accStatus = 0;
	switch (ctxInt) {
		case 1002:
			// facebook
			accStatus = [[NMAccountManager sharedAccountManager].facebookAccountStatus integerValue];
			if (accStatus == NMSyncInitialSyncError) {
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Sorry, we weren't able to verify your account. Please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alertView show];
				[alertView release];
                
                [activityIndicator stopAnimating];
                [UIView animateWithDuration:0.2 animations:^{
                    connectFacebookButton.alpha = 1;
                }];
			} else if (accStatus > 0) {
                // Avoid multiple notifications
                [[NMAccountManager sharedAccountManager] removeObserver:self forKeyPath:@"facebookAccountStatus"];                
                [self showGridAnimated:YES];
            }
			break;
			
		default:
			[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
			return;
	}
}

@end
