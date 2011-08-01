//
//  SettingsViewController.h
//  ipad
//
//  Created by Bill So on 8/1/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController <UITextFieldDelegate> {
	IBOutlet UITextField * userIDField;
	IBOutlet UISwitch * hqSwitch;
	IBOutlet UILabel * reloadNote;
}

- (IBAction)changeHQSetting:(id)sender;
- (IBAction)reloadApp:(id)sender;

@end
