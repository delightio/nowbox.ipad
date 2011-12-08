//
//  PhoneLaunchController.m
//  ipad
//
//  Created by Chris Haugli on 12/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "PhoneLaunchController.h"

@implementation PhoneLaunchController

- (void)loadView
{
    [super loadView];
    [self updateViewForInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
}

- (void)updateViewForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    NSString *filePath;
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        filePath = [[NSBundle mainBundle] pathForResource:@"Default-Landscape" ofType:@"png"];
    } else {
        filePath = [[NSBundle mainBundle] pathForResource:@"Default" ofType:@"png"];
    }
    
    // imageWithContentsOfFile rather than imageNamed to avoid large splash image being cached
    self.logoImageView.image = [UIImage imageWithContentsOfFile:filePath];
}

@end
