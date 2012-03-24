//
//  TwitterAccountPickerViewController.m
//  ipad
//
//  Created by Bill So on 1/24/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "TwitterAccountPickerViewController.h"
#import "NMLibrary.h"

@implementation TwitterAccountPickerViewController

@synthesize accountStore = _accountStore;
@synthesize twitterAccountArray = _twitterAccountArray;
@synthesize delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
		_accountStore = [[ACAccountStore alloc] init];
    }
    return self;
}

- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[_accountStore release];
	[_twitterAccountArray release];
    
	[super dealloc];
}

- (void)loadTwitterAccounts 
{
	ACAccountType *accountType = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
	self.twitterAccountArray = [_accountStore accountsWithAccountType:accountType];
	// get which account(s) is/are selected	
}

- (void)cancelButtonPressed:(id)sender
{
    if ([delegate respondsToSelector:@selector(twitterAccountPickerViewControllerDidCancel:)]) {
        [delegate twitterAccountPickerViewControllerDidCancel:self];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.title = @"Twitter";
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)] autorelease];
    
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
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    ACAccount * acObj = [_twitterAccountArray objectAtIndex:indexPath.row];
	cell.textLabel.text = acObj.accountDescription;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Select an account to sign in";
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	ACAccount * acObj = [_twitterAccountArray objectAtIndex:indexPath.row];
	[[NMAccountManager sharedAccountManager] subscribeAccount:acObj];
    
    if ([delegate respondsToSelector:@selector(twitterAccountPickerViewController:didPickAccount:)]) {
        [delegate twitterAccountPickerViewController:self didPickAccount:acObj];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
        
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
