//
//  TwitterAccountPickerViewController.m
//  ipad
//
//  Created by Bill So on 1/24/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "TwitterAccountPickerViewController.h"
#import "NMLibrary.h"
#import "NMStyleUtility.h"

@implementation TwitterAccountPickerViewController

@synthesize accountStore = _accountStore;
@synthesize twitterAccountArray = _twitterAccountArray;
@synthesize delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
		_accountStore = [[ACAccountStore alloc] init];
		// observe changes in account manager
		[[NMAccountManager sharedAccountManager] addObserver:self forKeyPath:@"twitterAccountStatus" options:0 context:(void *)1001];
    }
    return self;
}

- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NMAccountManager sharedAccountManager] removeObserver:self forKeyPath:@"twitterAccountStatus"];
    
	[_accountStore release];
	[_twitterAccountArray release];
	
	[activityIndicator release];
	[progressContainerView release];
    
	[super dealloc];
}

- (void)loadTwitterAccounts 
{
	ACAccountType *accountType = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
	self.twitterAccountArray = [_accountStore accountsWithAccountType:accountType];
	// get which account(s) is/are selected	
}

//- (void)cancelButtonPressed:(id)sender
//{
//    if ([delegate respondsToSelector:@selector(twitterAccountPickerViewControllerDidCancel:)]) {
//        [delegate twitterAccountPickerViewControllerDidCancel:self];
//    }
//}

- (void)createProgressContainerView {
	if ( progressContainerView ) return;
	CGRect theFrame = self.view.bounds;
	NMStyleUtility * theStyle = [NMStyleUtility sharedStyleUtility];
	UIView * ctnView = [[UIView alloc] initWithFrame:theFrame];
	ctnView.backgroundColor = [theStyle.blackColor colorWithAlphaComponent:0.5];
	// text label
	UILabel * lbl = [[UILabel alloc] initWithFrame:CGRectMake(0.0, floorf(theFrame.size.height / 2.0) - 10.0, theFrame.size.width, 24.0f)];
	lbl.text = @"Connecting to Twitter...";
	lbl.backgroundColor = theStyle.clearColor;
	lbl.textColor = [UIColor whiteColor];
	lbl.shadowOffset = CGSizeMake(0.0, 1.0);
	lbl.textAlignment = UITextAlignmentCenter;
	lbl.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
	[ctnView addSubview:lbl], [lbl release];
	// activity indicator
	activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	CGSize theSize = activityIndicator.bounds.size;
	theFrame.origin.x = floorf((theFrame.size.width - theSize.width) / 2.0);
	theFrame.origin.y = floorf(theFrame.size.height / 2.0 + 14.0);
	theFrame.size = theSize;
	activityIndicator.frame = theFrame;
	[ctnView addSubview:activityIndicator];
	
	progressContainerView = ctnView;
	progressContainerView.alpha = 0.0;
	
	[self.view addSubview:progressContainerView];
	[UIView animateWithDuration:0.25 animations:^{
		progressContainerView.alpha = 1.0;
	} completion:^(BOOL finished) {
		[activityIndicator startAnimating];
	}];
}

- (void)delayDismissViewController {
	[activityIndicator stopAnimating];
	// dismiss the view
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ( context == (void *)1001 ) {
		// check the value
		NMAccountManager * mgr = object;
		switch ( [mgr.twitterAccountStatus integerValue]) {
			case  NMSyncSyncInProgress:
				[self performSelector:@selector(delayDismissViewController) withObject:nil afterDelay:1.0];
				break;
				
			default:
				break;
		}
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.title = @"Twitter";
//	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)] autorelease];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountNotification:) name:ACAccountStoreDidChangeNotification object:nil];
	[self loadTwitterAccounts];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (NM_RUNNING_ON_IPAD) {
        return UIInterfaceOrientationIsLandscape(interfaceOrientation);
    } else {
        return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_twitterAccountArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    ACAccount * acObj = [_twitterAccountArray objectAtIndex:indexPath.row];
	cell.textLabel.text = acObj.accountDescription;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Pick an account:";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	return @"Nowbox will check your Twitter feed and show you videos posted by people your follow.";
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	ACAccount * acObj = [_twitterAccountArray objectAtIndex:indexPath.row];
	[[NMAccountManager sharedAccountManager] subscribeAccount:acObj];
    
    if ([delegate respondsToSelector:@selector(twitterAccountPickerViewController:didPickAccount:)]) {
        [delegate twitterAccountPickerViewController:self didPickAccount:acObj];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	// show container view
	[self createProgressContainerView];
        
//	NMTaskQueueController * tqCtrl = [NMTaskQueueController sharedTaskQueueController];
//	NMChannel * chnObj = [tqCtrl.dataController insertChannelWithAccount:acObj];
//	[tqCtrl issueProcessFeedForChannel:chnObj];
	//TODO: in production version, we should do the fetch after the user dismiss this view.
}

#pragma mark Notification handler

- (void)handleAccountNotification:(NSNotification *)aNotification 
{
	[self loadTwitterAccounts];
	[self.tableView reloadData];
}

@end
