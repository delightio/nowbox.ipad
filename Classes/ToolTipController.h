//
//  ToolTipController.h
//  ipad
//
//  Created by Chris Haugli on 10/19/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kToolTipDefinitionFile @"Tooltips"

// User defaults keys
#define kVideoTapCountKey @"NMToolTipVideoTapCount"
#define kBadVideoTapCountKey @"NMToolTipBadVideoTapCount"
#define kChannelManagementTapCountKey @"NMChannelManagementTapCount"
#define kFavoriteTapCountKey @"NMFavoriteTapCount"

@class ToolTip;
@protocol ToolTipControllerDelegate;

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

@interface ToolTipController : NSObject {
    NSMutableSet *monitoredToolTips;
    NSTimeInterval startedTime;
    NSInteger firstLaunch;
    NSTimer *refreshTimer;
}

@property (nonatomic, retain) UIButton *dismissButton;
@property (nonatomic, retain) UIButton *tooltipButton;
@property (nonatomic, assign) id<ToolTipControllerDelegate> delegate;

+ (ToolTipController *)sharedToolTipController;

// Starts recording time elapsed
- (void)startTimer;

// View controllers are responsible for notifying the tooltip controller of any events (except time and session count)
- (void)notifyEvent:(ToolTipEventType)eventType;

// Removes any tooltips that are no longer valid from being monitored
- (void)removeInvalidatedToolTips;

// Checks if any tooltips should be shown. If so, a notification will be sent.
- (void)performToolTipCheckForEventType:(ToolTipEventType)eventType;

// Creates the tooltip view and presents it
- (void)presentToolTip:(ToolTip *)tooltip inView:(UIView *)view;

@end

@protocol ToolTipControllerDelegate <NSObject>
- (BOOL)toolTipController:(ToolTipController *)controller shouldPresentToolTip:(ToolTip *)tooltip;
- (UIView *)toolTipController:(ToolTipController *)controller viewForPresentingToolTip:(ToolTip *)tooltip;
@end

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

@end

// Defines a criteria for when a tooltip should be shown / not shown
@interface ToolTipCriteria : NSObject

@property (nonatomic, assign) ToolTipEventType eventType;
@property (nonatomic, retain) NSNumber *count;
@property (nonatomic, retain) NSNumber *elapsedCount;

@end
