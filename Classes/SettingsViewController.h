//
//  SettingsViewController.h
//  ipad
//
//  Created by Bill So on 8/1/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface SettingsViewController : UITableViewController <UITextFieldDelegate, MFMailComposeViewControllerDelegate> {
	IBOutlet UITextField * userIDField;
	IBOutlet UILabel * reloadNote;
	
	NSUserDefaults * userDefaults;
	
//	UISwitch * hdSwitch, * pushNotificationSwitch, * emailNotificationSwitch, * favoriteChannelSwitch;
	UISwitch * hdSwitch;
	BOOL viewPushedByNavigationController;
}

@end
