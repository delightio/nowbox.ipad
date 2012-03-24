//
//  TwitterAccountPickerViewController.h
//  ipad
//
//  Created by Bill So on 1/24/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Accounts/Accounts.h>

@protocol TwitterAccountPickerViewControllerDelegate;

@interface TwitterAccountPickerViewController : UITableViewController

@property (nonatomic, retain) ACAccountStore * accountStore;
@property (nonatomic, retain) NSArray * twitterAccountArray;
@property (nonatomic, assign) id<TwitterAccountPickerViewControllerDelegate> delegate;

@end

@protocol TwitterAccountPickerViewControllerDelegate <NSObject>
@optional
- (void)twitterAccountPickerViewController:(TwitterAccountPickerViewController *)viewController didPickAccount:(ACAccount *)account;
- (void)twitterAccountPickerViewControllerDidCancel:(TwitterAccountPickerViewController *)viewController;
@end