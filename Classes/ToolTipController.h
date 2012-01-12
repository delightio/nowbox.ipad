//
//  ToolTipController.h
//  ipad
//
//  Created by Chris Haugli on 10/19/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ToolTip.h"

#define kToolTipDefinitionFile @"Tooltips"

// User defaults keys
#define kVideoTapCountKey @"NMToolTipVideoTapCount"
#define kBadVideoTapCountKey @"NMToolTipBadVideoTapCount"
#define kChannelManagementTapCountKey @"NMChannelManagementTapCount"
#define kSharedVideoTapCountKey @"NMSharedVideoCount"
#define kWatchLaterTapCountKey @"NMWatchLaterTapCount"
#define kFavoriteTapCountKey @"NMFavoriteTapCount"
#define kChannelListScrollCountKey @"NMChannelListScrollCount"

@protocol ToolTipControllerDelegate;

@interface ToolTipController : NSObject {
    NSMutableSet *monitoredToolTips;
    NSTimeInterval startedTime;
    NSInteger firstLaunch;
    NSTimer *refreshTimer;
    NSTimer *autoHideTimer;
}

@property (nonatomic, retain) UIView *dismissTouchArea;
@property (nonatomic, retain) UIButton *tooltipButton;
@property (nonatomic, assign) id<ToolTipControllerDelegate> delegate;

+ (ToolTipController *)sharedToolTipController;

// Starts recording time elapsed
- (void)startTimer;

// View controllers are responsible for notifying the tooltip controller of any events (except time and session count). An optional sender object can be passed, which will be returned to the delegate if this event triggers a tooltip.
- (void)notifyEvent:(ToolTipEventType)eventType sender:(id)sender;

// Removes any tooltips that are no longer valid from being monitored
- (void)removeInvalidatedToolTips;

// Checks if any tooltips should be shown. If so, a notification will be sent.
- (void)performToolTipCheckForEventType:(ToolTipEventType)eventType sender:(id)sender;

// Creates the tooltip view and presents it
- (void)presentToolTip:(ToolTip *)tooltip inView:(UIView *)view;

// Resets all tooltips, as if the app was started for the very first time
- (void)resetTooltips;

@end

@protocol ToolTipControllerDelegate <NSObject>
- (BOOL)toolTipController:(ToolTipController *)controller shouldPresentToolTip:(ToolTip *)tooltip sender:(id)sender;
- (UIView *)toolTipController:(ToolTipController *)controller viewForPresentingToolTip:(ToolTip *)tooltip sender:(id)sender;
@end

