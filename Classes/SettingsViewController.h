//
//  SettingsViewController.h
//  ipad
//
//  Created by Bill So on 8/1/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UITableViewController <UITextFieldDelegate> {
	IBOutlet UITextField * userIDField;
	IBOutlet UISwitch * hqSwitch, * mobileBrowserSwitch;
	IBOutlet UILabel * reloadNote;
	
	NSUserDefaults * userDefaults;
	
	UISwitch * hdSwitch, * pushNotificationSwitch, * emailNotificationSwitch, * favoriteChannelSwitch;
	BOOL viewPushedByNavigationController;
}

@end
