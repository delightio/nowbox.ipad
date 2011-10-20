//
//  ToolTip.h
//  ipad
//
//  Created by Chris Haugli on 10/20/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

// These are the events used to define when a tooltip will be shown
typedef enum {
    ToolTipEventMinimumTime,
    ToolTipEventMaximumTime,
    ToolTipEventFirstLaunch,
    ToolTipEventVideoTap,
    ToolTipEventBadVideoTap,
    ToolTipEventChannelManagementTap,
    ToolTipEventFavoriteTap
} ToolTipEventType;

// Contains information about each type of tooltip
@interface ToolTip : NSObject 

@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) NSSet *validationCriteria;
@property (nonatomic, retain) NSSet *invalidationCriteria;
@property (nonatomic, assign) CGPoint center;
@property (nonatomic, assign) BOOL keepCountsOnRestart;
@property (nonatomic, assign) BOOL resetCountsOnDisplay;
@property (nonatomic, copy) NSString *imageFile;
@property (nonatomic, copy) NSString *displayText;
@property (nonatomic, assign) NSTimeInterval autoHideInSeconds;
@property (nonatomic, assign) id target;
@property (nonatomic, assign) SEL action;

@end

// Defines a criteria for when a tooltip should be shown / not shown
@interface ToolTipCriteria : NSObject

@property (nonatomic, assign) ToolTipEventType eventType;
@property (nonatomic, retain) NSNumber *count;
@property (nonatomic, retain) NSNumber *elapsedCount;

@end

