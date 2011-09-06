//
//  SettingsViewController.m
//  ipad
//
//  Created by Bill So on 8/1/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "SettingsViewController.h"
#import "ipadAppDelegate.h"
#import "TwitterLoginViewController.h"
#import "NMLibrary.h"

#define NM_SETTING_HD_SWITCH_TAG					1001
#define NM_SETTING_FAVORITE_CHANNEL_SWITCH_TAG		1002
#define NM_SETTING_PUSH_NOTIFICATION_SWITCH_TAG		1003
#define NM_SETTING_EMAIL_NOTIFICATION_SWITCH_TAG	1004

@implementation SettingsViewController

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

- (void)dealloc {
    [super dealloc];
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
	userDefaults = [NSUserDefaults standardUserDefaults];
	self.title = @"Settings";
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissView:)];
	// set the current User ID
//	userIDField.text = [userDefaults stringForKey:NM_USER_ACCOUNT_ID_KEY];
	// set current HQ setting
//	hqSwitch.on = [userDefaults boolForKey:NM_USE_HIGH_QUALITY_VIDEO_KEY];
	
	hdSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
	hdSwitch.tag = NM_SETTING_HD_SWITCH_TAG;
	hdSwitch.on = [userDefaults boolForKey:NM_USE_HIGH_QUALITY_VIDEO_KEY];
	[hdSwitch addTarget:self action:@selector(saveSwitchSetting:) forControlEvents:UIControlEventValueChanged];

	favoriteChannelSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
	favoriteChannelSwitch.tag = NM_SETTING_FAVORITE_CHANNEL_SWITCH_TAG;
	[favoriteChannelSwitch addTarget:self action:@selector(saveSwitchSetting:) forControlEvents:UIControlEventValueChanged];
	
	pushNotificationSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
	pushNotificationSwitch.tag = NM_SETTING_PUSH_NOTIFICATION_SWITCH_TAG;
	[pushNotificationSwitch addTarget:self action:@selector(saveSwitchSetting:) forControlEvents:UIControlEventValueChanged];
	
	emailNotificationSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
	emailNotificationSwitch.tag = NM_SETTING_EMAIL_NOTIFICATION_SWITCH_TAG;
	[emailNotificationSwitch addTarget:self action:@selector(saveSwitchSetting:) forControlEvents:UIControlEventValueChanged];
	
#if TARGET_IPHONE_SIMULATOR
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleCreateChannelNotificaiton:) name:NMDidCreateChannelNotification object:nil];
	[nc addObserver:self selector:@selector(handleFailCreateChannelNotification:) name:NMDidFailCreateChannelNotification object:nil];
#endif
}

#if TARGET_IPHONE_SIMULATOR
- (void)handleCreateChannelNotificaiton:(NSNotification *)aNotificaiton {
	
}

- (void)handleFailCreateChannelNotification:(NSNotification *)aNotificaiton {
	NSDictionary * info = [aNotificaiton userInfo];
	NMTask * task = [info objectForKey:@"task"];
	NSString * resultStr = [[NSString alloc] initWithData:task.buffer encoding:NSUTF8StringEncoding];
	NSLog(@"fail creating channel %d, %@", task.httpStatusCode, resultStr);
	[resultStr release];
}
#endif

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
			NM_USE_HIGH_QUALITY_VIDEO = theSwitch.on;
			[userDefaults setBool:theSwitch.on forKey:NM_USE_HIGH_QUALITY_VIDEO_KEY];
			break;
		case NM_SETTING_FAVORITE_CHANNEL_SWITCH_TAG:
			[userDefaults setBool:theSwitch.on forKey:NM_SHOW_FAVORITE_CHANNEL_KEY];
			break;
		case NM_SETTING_PUSH_NOTIFICATION_SWITCH_TAG:
			[userDefaults setBool:theSwitch.on forKey:NM_ENABLE_PUSH_NOTIFICATION_KEY];
			break;
		case NM_SETTING_EMAIL_NOTIFICATION_SWITCH_TAG:
			[userDefaults setBool:theSwitch.on forKey:NM_ENABLE_EMAIL_NOTIFICATION_KEY];
			break;
			
		default:
			break;
	}
}

- (void)dismissView:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)changeHQSetting:(id)sender {
	[[NSUserDefaults standardUserDefaults] setBool:hqSwitch.on forKey:NM_USE_HIGH_QUALITY_VIDEO_KEY];
}

- (IBAction)reloadApp:(id)sender {
	reloadNote.hidden = NO;
	[userIDField resignFirstResponder];
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
#if TARGET_IPHONE_SIMULATOR
	return 6;
#else
	return 5;
#endif
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger numRow = 1;
	switch (section) {
		case 2:
		case 4:
			numRow = 2;
			break;
			
		default:
			break;
	}
	return numRow;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"Cell";
	static NSString * SocialCellIdentifier = @"SocialCell";
	static NSString * EmailCellIdentifier = @"EmailCell";
    
    UITableViewCell * cell;
	NSString * lblStr = nil;
	switch (indexPath.section) {
		case 1:
			cell = [tableView dequeueReusableCellWithIdentifier:EmailCellIdentifier];
			if ( cell == nil ) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SocialCellIdentifier] autorelease];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				// create text field
				userIDField = [[UITextField alloc] initWithFrame:CGRectMake(0.0, 14.0, 200.0, 24.0)];
				userIDField.borderStyle = UITextBorderStyleNone;
				userIDField.placeholder = @"Your Email Address";
				userIDField.delegate = self;
				userIDField.textAlignment = UITextAlignmentRight;
				cell.accessoryView = userIDField;
			}
			cell.textLabel.text = @"Email (User ID for now)";
			userIDField.text = [userDefaults stringForKey:NM_USER_ACCOUNT_ID_KEY];
			break;
		case 2:
			cell = [tableView dequeueReusableCellWithIdentifier:SocialCellIdentifier];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:SocialCellIdentifier] autorelease];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}
			switch (indexPath.row) {
				case 0:
					cell.textLabel.text = @"Twitter";
					cell.detailTextLabel.text = @"Login";
					break;
				case 1:
					cell.textLabel.text = @"Facebook";
					cell.detailTextLabel.text = @"Login";
					break;
				default:
					break;
			}
			break;
#if TARGET_IPHONE_SIMULATOR
		case 5:
			cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			}
			cell.textLabel.text = @"Create Keyword Channel";
			break;
#endif
			
		default:
			cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
			}
			switch (indexPath.section) {
				case 0:
					// HD
					lblStr = @"HD";
					cell.accessoryView = hdSwitch;
					break;
				case 3:
					lblStr = @"Show Favorites Channel";
					cell.accessoryView = favoriteChannelSwitch;
					break;
				case 4:
				{
					switch (indexPath.row) {
						case 0:
							lblStr = @"Push Notification";
							cell.accessoryView = pushNotificationSwitch;
							break;
						case 1:
							lblStr = @"Email";
							cell.accessoryView = emailNotificationSwitch;
							break;
						default:
							break;
					}
					break;
				}	
					
				default:
					break;
			}
			cell.textLabel.text = lblStr;
			break;
	}
	
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 2:
			return @"Social";
			
		case 4:
			return @"Notifications";
			
		default:
			break;
	}
	return nil;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ( indexPath.section == 2 && indexPath.row == 0 ) {
		TwitterLoginViewController * twitterCtrl = [[TwitterLoginViewController alloc] initWithNibName:@"TwitterLoginView" bundle:nil];
		[self.navigationController pushViewController:twitterCtrl animated:YES];
		[twitterCtrl release];
	}
#if TARGET_IPHONE_SIMULATOR
	if ( indexPath.section == 5 ) {
		[[NMTaskQueueController sharedTaskQueueController] issueCreateChannelWithKeyword:[NSString stringWithFormat:@"testing_%d", rand()]];
	}
#endif
}


@end
