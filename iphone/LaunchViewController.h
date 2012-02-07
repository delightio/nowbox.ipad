//
//  LaunchViewController.h
//  ipad
//
//  Created by Chris Haugli on 2/7/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LaunchController_iPhone.h"

@protocol LaunchViewControllerDelegate;

@interface LaunchViewController : UIViewController <LaunchControllerDelegate> {
    LaunchController *launchController;
}

@property (nonatomic, assign) IBOutlet id<LaunchViewControllerDelegate> delegate;

@end

@protocol LaunchViewControllerDelegate <NSObject>

- (void)launchViewControllerDidFinish:(LaunchViewController *)launchViewController;

@end