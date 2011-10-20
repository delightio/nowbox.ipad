//
//  ToolTip.m
//  ipad
//
//  Created by Chris Haugli on 10/20/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "ToolTip.h"

#pragma mark - ToolTip

@implementation ToolTip

@synthesize name;
@synthesize validationCriteria;
@synthesize invalidationCriteria;
@synthesize center;
@synthesize keepCountsOnRestart;
@synthesize resetCountsOnDisplay;
@synthesize imageFile;
@synthesize displayText;
@synthesize autoHideInSeconds;
@synthesize target;
@synthesize action;

- (void)dealloc
{
    [name release];
    [validationCriteria release];
    [invalidationCriteria release];
    [imageFile release];
    [displayText release];
    
    [super dealloc];
}

@end

#pragma mark - ToolTipCriteria

@implementation ToolTipCriteria

@synthesize eventType;
@synthesize count;
@synthesize elapsedCount;

- (void)dealloc
{
    [count release];
    [elapsedCount release];
    
    [super dealloc];
}

@end