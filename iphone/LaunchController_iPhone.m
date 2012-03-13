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

- (void)didFinish
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:NM_FIRST_LAUNCH_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
	taskQueueController.appFirstLaunch = NO;
    
    [delegate launchControllerDidFinish:self];    
}

- (void)showVideoViewAnimated
{
    [self didFinish];
}

- (void)handleDidGetChannelNotification:(NSNotification *)aNotification 
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:NM_CHANNEL_LAST_UPDATE];
    [self beginNewSession];

    [self didFinish];
}

@end
