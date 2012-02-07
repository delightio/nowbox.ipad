//
//  LaunchController_iPhone.m
//  ipad
//
//  Created by Chris Haugli on 2/7/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "LaunchController_iPhone.h"
#import "ipadAppDelegate.h"

@implementation LaunchController_iPhone

@synthesize delegate;

- (void)handleDidGetChannelNotification:(NSNotification *)aNotification 
{
    // Unlike iPad, all we need is channels for now.
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:NM_FIRST_LAUNCH_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
	taskQueueController.appFirstLaunch = NO;
    
    [delegate launchControllerDidFinish:self];
}

@end
