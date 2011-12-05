//
//  ToolTip.h
//  ipad
//
//  Created by Chris Haugli on 10/20/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/*** These are the events used to define when a tooltip will be shown ***/
typedef enum {
    ToolTipEventMinimumTime,
    ToolTipEventMaximumTime,
    ToolTipEventFirstLaunch,
    ToolTipEventVideoTap,
    ToolTipEventBadVideoTap,
    ToolTipEventChannelManagementTap,
    ToolTipEventFavoriteTap,
    ToolTipEventWatchLaterTap,
    ToolTipEventChannelListScroll
} ToolTipEventType;



/*** Contains information about each type of tooltip ***/
@interface ToolTip : NSObject 

// A unique identifier for the tooltip
@property (nonatomic, copy) NSString *name;

// A set of ToolTipCriteria that, when all are satisfied, results in the tooltip being shown
@property (nonatomic, retain) NSSet *validationCriteria;

// A set of ToolTipCriteria that, when all are satisfied, prevents the tooltip from being shown
@property (nonatomic, retain) NSSet *invalidationCriteria;

// The center position of the tooltip on the screen
@property (nonatomic, assign) CGPoint center;

// If true, elapsed counts for criteria will persist across sessions
@property (nonatomic, assign) BOOL keepCountsOnRestart;

// If true, elapsed counts for criteria are reset when the validation criteria are met (i.e. the tooltip can be shown multiple times within a session)
@property (nonatomic, assign) BOOL resetCountsOnDisplay;

// The tooltip image filename in the resource bundle
@property (nonatomic, copy) NSString *imageFile;

// The display text for the tooltip
@property (nonatomic, copy) NSString *displayText;

// Define how the display text should be positioned
@property (nonatomic, assign) UIEdgeInsets displayTextEdgeInsets;

// The time interval after which the tooltip should automatically hide. If 0, never auto-hide.
@property (nonatomic, assign) NSTimeInterval autoHideInSeconds;

// If set, any tooltips with this name will be invalidated once this tooltip is shown.
@property (nonatomic, copy) NSString *invalidatesToolTip;

// The target/action that should be performed when the tooltip is pressed
@property (nonatomic, assign) id target;
@property (nonatomic, assign) SEL action;

@end



/*** Defines a criteria for when a tooltip should be shown / not shown ***/
@interface ToolTipCriteria : NSObject

// The type of event, e.g. a specific button tap
@property (nonatomic, assign) ToolTipEventType eventType;

// The number of times this event must occur for this criteria to be met
@property (nonatomic, retain) NSNumber *count;

// The number of times this event has occurred so far
@property (nonatomic, retain) NSNumber *elapsedCount;

@end

