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
	IBOutlet UILabel * reloadNote;
	BOOL userSettingsChanged;
	NSMutableArray * autoPostSettings;
	NSMutableDictionary * uiTagIndexMap;
	
	NSUserDefaults * userDefaults;
	
//	UISwitch * hdSwitch, * pushNotificationSwitch, * emailNotificationSwitch, * favoriteChannelSwitch;
	UISwitch * hdSwitch;
	BOOL viewPushedByNavigationController;
}

@end
