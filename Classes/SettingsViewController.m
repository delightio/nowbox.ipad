//
//  SettingsViewController.m
//  ipad
//
//  Created by Bill So on 8/1/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "SettingsViewController.h"
#import "ipadAppDelegate.h"
#import "SocialLoginViewController.h"
#import "ToolTipController.h"
#import "NMLibrary.h"
#import "NMStyleUtility.h"

#define NM_SETTING_HD_SWITCH_TAG					1001
//#define NM_SETTING_FAVORITE_CHANNEL_SWITCH_TAG		1002
//#define NM_SETTING_PUSH_NOTIFICATION_SWITCH_TAG		1003
//#define NM_SETTING_EMAIL_NOTIFICATION_SWITCH_TAG	1004
//#define	NM_SETTING_MOBILE_BROWSER_SWITCH_TAG		1005

@implementation SettingsViewController

- (void)dealloc {
//	[favoriteChannelSwitch release];
	[hdSwitch release];
//	[pushNotificationSwitch release];
//	[emailNotificationSwitch release];
    [super dealloc];
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	userDefaults = [NSUserDefaults standardUserDefaults];
	self.title = @"Settings";
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissView:)] autorelease];
	
    NSString *apiURL;
    CGRect footerLabelFrame;
#ifdef DEBUG
    apiURL = [NSString stringWithFormat:@"\n\nAPI URL: %@", NM_BASE_URL];
    footerLabelFrame = CGRectMake(0.0f, 0.0f, 320.0f, 104.0f);
#else
    apiURL = @"";
    footerLabelFrame = CGRectMake(0.0f, 0.0f, 320.0f, 68.0f);
#endif
    
	UILabel * footerLabel = [[UILabel alloc] initWithFrame:footerLabelFrame];
	footerLabel.backgroundColor = [NMStyleUtility sharedStyleUtility].clearColor;
	footerLabel.numberOfLines = 0;
	footerLabel.textAlignment = UITextAlignmentCenter;
	footerLabel.text = [NSString stringWithFormat:@"© 2011 Pipely Inc.\nVersion: %@\nUser ID: %d%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey], NM_USER_ACCOUNT_ID, apiURL];
	self.tableView.tableFooterView = footerLabel;
	[footerLabel release];
	// set the current User ID
//	userIDField.text = [userDefaults stringForKey:NM_USER_ACCOUNT_ID_KEY];
	// set current HQ setting
//	hqSwitch.on = [userDefaults boolForKey:NM_USE_HIGH_QUALITY_VIDEO_KEY];
	
	hdSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
	hdSwitch.tag = NM_SETTING_HD_SWITCH_TAG;
	hdSwitch.on = NM_VIDEO_QUALITY == NMVideoQualityAutoSelect;
	[hdSwitch addTarget:self action:@selector(saveSwitchSetting:) forControlEvents:UIControlEventValueChanged];
	
//	mobileBrowserSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
//	mobileBrowserSwitch.tag = NM_SETTING_MOBILE_BROWSER_SWITCH_TAG;
//	mobileBrowserSwitch.on = [userDefaults boolForKey:NM_YOUTUBE_MOBILE_BROWSER_RESOLUTION_KEY];
//	[mobileBrowserSwitch addTarget:self action:@selector(saveSwitchSetting:) forControlEvents:UIControlEventValueChanged];

//	favoriteChannelSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
//	favoriteChannelSwitch.tag = NM_SETTING_FAVORITE_CHANNEL_SWITCH_TAG;
//	favoriteChannelSwitch.on = NM_USER_SHOW_FAVORITE_CHANNEL;
//	[favoriteChannelSwitch addTarget:self action:@selector(saveSwitchSetting:) forControlEvents:UIControlEventValueChanged];
	
	
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [hdSwitch release]; hdSwitch = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if ( !viewPushedByNavigationController ) {
		[[NSNotificationCenter defaultCenter] postNotificationName:NMChannelManagementWillAppearNotification object:self];
		viewPushedByNavigationController = YES;
	}
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	if ( !viewPushedByNavigationController ) {
		[[NSNotificationCenter defaultCenter] postNotificationName:NMChannelManagementDidDisappearNotification object:self];
	}
}

#pragma mark Target action methods
- (void)saveSwitchSetting:(id)sender {
	UISwitch * theSwitch = (UISwitch *)sender;
	switch (theSwitch.tag) {
		case NM_SETTING_HD_SWITCH_TAG:
			NM_VIDEO_QUALITY = theSwitch.on ? NMVideoQualityAutoSelect : NMVideoQualityAlwaysSD;
			[userDefaults setInteger:NM_VIDEO_QUALITY forKey:NM_VIDEO_QUALITY_KEY];
			break;
//		case NM_SETTING_MOBILE_BROWSER_SWITCH_TAG:
//			NM_YOUTUBE_MOBILE_BROWSER_RESOLUTION = theSwitch.tag;
//			[userDefaults setBool:theSwitch.on forKey:NM_YOUTUBE_MOBILE_BROWSER_RESOLUTION_KEY];
//			break;
//		case NM_SETTING_FAVORITE_CHANNEL_SWITCH_TAG:
//			NM_USER_SHOW_FAVORITE_CHANNEL = theSwitch.on;
//			[[NMTaskQueueController sharedTaskQueueController].dataController updateFavoriteChannelHideStatus];
//			[userDefaults setBool:theSwitch.on forKey:NM_SHOW_FAVORITE_CHANNEL_KEY];
//			break;
//		case NM_SETTING_PUSH_NOTIFICATION_SWITCH_TAG:
//			[userDefaults setBool:theSwitch.on forKey:NM_ENABLE_PUSH_NOTIFICATION_KEY];
//			break;
//		case NM_SETTING_EMAIL_NOTIFICATION_SWITCH_TAG:
//			[userDefaults setBool:theSwitch.on forKey:NM_ENABLE_EMAIL_NOTIFICATION_KEY];
//			break;
		default:
			break;
	}
}

- (void)dismissView:(id)sender {
	viewPushedByNavigationController = NO;
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark text edit delegate
- (void)textFieldDidEndEditing:(UITextField *)textField {
	NSInteger uid = [textField.text integerValue];
	if ( uid ) {
		// save the user id
		[[NSUserDefaults standardUserDefaults] setInteger:uid forKey:NM_USER_ACCOUNT_ID_KEY];
		[[NSUserDefaults standardUserDefaults] synchronize];
		NM_USER_ACCOUNT_ID = uid;
	} else {
		UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil message:@"Wrong user ID" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
}

#pragma mark Table view delegate
// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"Cell";
	static NSString * EmailIdentifier = @"EmailCell";

    UITableViewCell * cell = nil;
	NSString * lblStr = nil;
	switch (indexPath.section) {
		case 0:
			cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
			}
			switch (indexPath.row) {
				case 0:
					// HD
					lblStr = @"High Definition Videos";
					cell.accessoryView = hdSwitch;
					break;
//				case 1:
//					// Mobile browser resolution
//					lblStr = @"Mobile Browser Resolution";
//					cell.accessoryView = mobileBrowserSwitch;
				default:
					break;
			}
			cell.textLabel.text = lblStr;
			break;
		case 1:
            cell = [tableView dequeueReusableCellWithIdentifier:EmailIdentifier];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:EmailIdentifier] autorelease];
            }
            cell.textLabel.text = @"Feedback? Email us at feedback@nowbox.com";
			
		default:
			break;
	}
	
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return nil;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 1) {
		[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
		
		MFMailComposeViewController * mvc = [[MFMailComposeViewController alloc] init];
		mvc.mailComposeDelegate = self;
		[mvc setSubject:@"NOWBOX iPad app user feedback"];
		[mvc setToRecipients:[NSArray arrayWithObject:@"feedback@nowbox.com"]];
		[mvc setMessageBody:[NSString stringWithFormat:@"\n\nVersion: %@\nUser ID: %d", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey], NM_USER_ACCOUNT_ID] isHTML:NO];
		[self presentModalViewController:mvc animated:YES];
		[mvc release];
    }
}

#pragma mark Mail Composer View
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	[self dismissModalViewControllerAnimated:YES];
}

@end
