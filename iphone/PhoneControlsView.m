//
//  PhoneControlsView.m
//  ipad
//
//  Created by Chris Haugli on 2/22/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "PhoneControlsView.h"

@implementation PhoneControlsView

@synthesize backgroundView;

- (void)dealloc
{
    [backgroundView release];
    [super dealloc];
}

@end
