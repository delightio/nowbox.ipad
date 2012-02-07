//
//  LaunchController_iPhone.h
//  ipad
//
//  Created by Chris Haugli on 2/7/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "LaunchController.h"

@protocol LaunchControllerDelegate;

@interface LaunchController_iPhone : LaunchController

@property (nonatomic, assign) id<LaunchControllerDelegate> delegate;

@end

@protocol LaunchControllerDelegate <NSObject>

- (void)launchControllerDidFinish:(LaunchController *)launchController;

@end