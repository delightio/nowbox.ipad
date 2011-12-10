//
//  ToolTipController.m
//  ipad
//
//  Created by Chris Haugli on 10/19/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "ToolTipController.h"
#import "ipadAppDelegate.h"
#import "TouchForwardingView.h"
#import "UIView+InteractiveAnimation.h"

#pragma mark - ToolTipController

@implementation ToolTipController

@synthesize dismissTouchArea;
@synthesize tooltipButton;
@synthesize delegate;

static ToolTipController *toolTipController = nil;

+ (ToolTipController *)sharedToolTipController
{
    if (!toolTipController) {
        toolTipController = [[ToolTipController alloc] init];
    }
    
    return toolTipController;
}

+ (NSSet *)parseCriteriaFromDictionary:(NSDictionary *)dictionary useSavedCounts:(BOOL)useSavedCounts
{
    NSMutableSet *criteriaSet = [NSMutableSet set];
    for (NSString *criteriaName in [dictionary allKeys]) {
        NSNumber *savedElapsedCount = nil;

        ToolTipCriteria *criteria = [[ToolTipCriteria alloc] init];
        criteria.count = [dictionary objectForKey:criteriaName];
        criteria.elapsedCount = [NSNumber numberWithInt:0];
        
        if ([criteriaName isEqualToString:@"MinimumTime"]) {
            criteria.eventType = ToolTipEventMinimumTime; 
        } else if ([criteriaName isEqualToString:@"MaximumTime"]) {
            criteria.eventType = ToolTipEventMaximumTime;
        } else if ([criteriaName isEqualToString:@"FirstLaunch"]) {
            criteria.eventType = ToolTipEventFirstLaunch;
        } else if ([criteriaName isEqualToString:@"VideoTap"]) {
            criteria.eventType = ToolTipEventVideoTap;
            if (useSavedCounts) {
                savedElapsedCount = [[NSUserDefaults standardUserDefaults] objectForKey:kVideoTapCountKey];
            }
        } else if ([criteriaName isEqualToString:@"BadVideoTap"]) {
            criteria.eventType = ToolTipEventBadVideoTap;
            if (useSavedCounts) {
                savedElapsedCount = [[NSUserDefaults standardUserDefaults] objectForKey:kBadVideoTapCountKey];
            }
        } else if ([criteriaName isEqualToString:@"ChannelManagementTap"]) {
            criteria.eventType = ToolTipEventChannelManagementTap;
            if (useSavedCounts) {
                savedElapsedCount = [[NSUserDefaults standardUserDefaults] objectForKey:kChannelManagementTapCountKey];
            }
        } else if ([criteriaName isEqualToString:@"SharedVideo"]) {
            criteria.eventType = ToolTipEventSharedVideo;
            if (useSavedCounts) {
                savedElapsedCount = [[NSUserDefaults standardUserDefaults] objectForKey:kSharedVideoTapCountKey];
            }
        } else if ([criteriaName isEqualToString:@"WatchLaterTap"]) {
            criteria.eventType = ToolTipEventWatchLaterTap;
            if (useSavedCounts) {
                savedElapsedCount = [[NSUserDefaults standardUserDefaults] objectForKey:kWatchLaterTapCountKey];
            }            
        } else if ([criteriaName isEqualToString:@"ChannelListScroll"]) {
            criteria.eventType = ToolTipEventChannelListScroll;
            if (useSavedCounts) {
                savedElapsedCount = [[NSUserDefaults standardUserDefaults] objectForKey:kChannelListScrollCountKey];
            }
        }
        
        if (savedElapsedCount) {
            criteria.elapsedCount = savedElapsedCount;
        }
        
        [criteriaSet addObject:criteria];
        [criteria release];
    }
    
    return criteriaSet;
}

- (void)setup
{
    [monitoredToolTips removeAllObjects];
    
    // Load the tooltip definitions from a plist
    NSString *definitionFile = [[NSBundle mainBundle] pathForResource:kToolTipDefinitionFile ofType:@"plist"];
    NSDictionary *definitionDict = [NSDictionary dictionaryWithContentsOfFile:definitionFile];
    
    for (NSString *key in [definitionDict allKeys]) {
        NSDictionary *propertyDict = [definitionDict objectForKey:key];
        
        ToolTip *toolTip = [[ToolTip alloc] init];
        toolTip.name = key;
        toolTip.center = CGPointMake([[propertyDict objectForKey:@"CenterX"] floatValue],
                                     [[propertyDict objectForKey:@"CenterY"] floatValue]);
        toolTip.keepCountsOnRestart = [[propertyDict objectForKey:@"KeepCountsOnRestart"] boolValue];
        toolTip.resetCountsOnDisplay = [[propertyDict objectForKey:@"ResetCountsOnDisplay"] boolValue];            
        toolTip.displayText = [propertyDict objectForKey:@"DisplayText"];
        toolTip.displayTextEdgeInsets = UIEdgeInsetsMake([[propertyDict objectForKey:@"DisplayTextEdgeInsetsTop"] floatValue], 
                                                         [[propertyDict objectForKey:@"DisplayTextEdgeInsetsLeft"] floatValue], 
                                                         [[propertyDict objectForKey:@"DisplayTextEdgeInsetsBottom"] floatValue], 
                                                         [[propertyDict objectForKey:@"DisplayTextEdgeInsetsRight"] floatValue]);
        toolTip.displayTextShadowHidden = [[propertyDict objectForKey:@"DisplayTextShadowHidden"] boolValue];
        toolTip.imageFile = [propertyDict objectForKey:@"ImageFile"];
        toolTip.autoHideInSeconds = [[propertyDict objectForKey:@"AutoHideInSeconds"] floatValue];
        toolTip.invalidatesToolTip = [propertyDict objectForKey:@"InvalidatesToolTip"];
        
        NSDictionary *validationDict = [propertyDict objectForKey:@"ValidationCriteria"];
        toolTip.validationCriteria = [ToolTipController parseCriteriaFromDictionary:validationDict 
                                                                     useSavedCounts:toolTip.keepCountsOnRestart];
        
        NSDictionary *invalidationDict = [propertyDict objectForKey:@"InvalidationCriteria"];
        toolTip.invalidationCriteria = [ToolTipController parseCriteriaFromDictionary:invalidationDict
                                                                       useSavedCounts:toolTip.keepCountsOnRestart];
        
        [monitoredToolTips addObject:toolTip];
        [toolTip release];
    }
    
    [self startTimer];
}

- (id)init
{
    self = [super init];
    if (self) {
        monitoredToolTips = [[NSMutableSet alloc] init];        
        firstLaunch = ([[[NSUserDefaults standardUserDefaults] objectForKey:NM_SESSION_COUNT_KEY] integerValue] == 1);
        
        [self setup];
    }
    
    return self;
}

- (void)dealloc
{
    [refreshTimer invalidate];
    [autoHideTimer invalidate];
    
    [monitoredToolTips release];
    [dismissTouchArea release];
    [tooltipButton release];
    
    [super dealloc];
}

- (void)startTimer
{
    startedTime = [[NSDate date] timeIntervalSince1970];
    
    if (!refreshTimer) {
        refreshTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(timerFired) userInfo:nil repeats:YES];
    }
}

- (void)timerFired
{
    [self performToolTipCheckForEventType:ToolTipEventMinimumTime sender:nil];
    [self performToolTipCheckForEventType:ToolTipEventMaximumTime sender:nil];
}

- (BOOL)validateCriteriaSet:(NSSet *)criteriaSet
{
    if ([criteriaSet count] == 0) {
        return NO;
    }
    
    for (ToolTipCriteria *criteria in criteriaSet) {
        switch (criteria.eventType) {
            case ToolTipEventMinimumTime:
                if ([[NSDate date] timeIntervalSince1970] - startedTime < [criteria.count floatValue]) {
                    return NO;
                }
                break;
            case ToolTipEventMaximumTime:
                if ([[NSDate date] timeIntervalSince1970] - startedTime > [criteria.count floatValue]) {
                    return NO;
                }
                break;
            case ToolTipEventFirstLaunch:
                if (firstLaunch != [criteria.count boolValue]) {
                    return NO;
                }
                break;
            default:
                if ([criteria.elapsedCount compare:criteria.count] == NSOrderedAscending) {
                    return NO;
                }
                break;
        }
    }
    
    return YES;    
}

- (void)removeInvalidatedToolTips
{
    NSMutableSet *toolTipsToRemove = [NSMutableSet set];
    for (ToolTip *tooltip in monitoredToolTips) {
        if ([self validateCriteriaSet:tooltip.invalidationCriteria]) {
            [toolTipsToRemove addObject:tooltip];
        }
    }
    
    [monitoredToolTips minusSet:toolTipsToRemove];
}

- (void)performToolTipCheckForEventType:(ToolTipEventType)eventType sender:(id)sender
{
    [self removeInvalidatedToolTips];
    
    ToolTip *tooltipToShow = nil;
    
    for (ToolTip *tooltip in monitoredToolTips) {
        if ([self validateCriteriaSet:tooltip.validationCriteria]) {
            // Check that validation criteria contains an event of this type
            for (ToolTipCriteria *criteria in tooltip.validationCriteria) {
                if (criteria.eventType == eventType) {
                    // Tooltip should be shown
                    if (!tooltipButton && [delegate toolTipController:self shouldPresentToolTip:tooltip sender:sender]) {
                        tooltipToShow = tooltip;
                        break;
                    }            
                }
            }
        }
        
        if (tooltipToShow) {
            break;
        }
    }
    
    if (tooltipToShow) {
        [self presentToolTip:tooltipToShow
                      inView:[delegate toolTipController:self viewForPresentingToolTip:tooltipToShow sender:sender]];
    }    
}

- (void)notifyEvent:(ToolTipEventType)eventType sender:(id)sender
{
    // Update the elapsed count for each tooltip's criteria
    for (ToolTip *tooltip in monitoredToolTips) {
        NSMutableSet *allCriteria = [NSMutableSet setWithSet:tooltip.validationCriteria];
        [allCriteria unionSet:tooltip.invalidationCriteria];
        
        for (ToolTipCriteria *criteria in allCriteria) {
            if (criteria.eventType == eventType) {
                criteria.elapsedCount = [NSNumber numberWithInt:[criteria.elapsedCount intValue] + 1];                
            }
        }
    }
    
/*  // Need to implement this better. [NSUserDefaults synchronize] is too slow.  
 
    // Update the global elapsed counts
    NSString *key = nil;
    switch (eventType) {
        case ToolTipEventVideoTap:              key = kVideoTapCountKey; break;
        case ToolTipEventBadVideoTap:           key = kBadVideoTapCountKey; break;
        case ToolTipEventChannelManagementTap:  key = kChannelManagementTapCountKey; break;
        case ToolTipEventSharedVideo:           key = kSharedVideoCountKey; break;
        case ToolTipEventWatchLaterTap:         key = kWatchLaterCountKey; break;
        case ToolTipEventChannelListScroll:     key = kChannelListScrollCountKey; break;
        default: break;
    }
    if (key) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        int newValue = [[userDefaults objectForKey:key] intValue] + 1;
        [userDefaults setObject:[NSNumber numberWithInt:newValue] forKey:key];
        [userDefaults synchronize];
    }*/
    
    // Check if any tooltips can be shown
    [self performToolTipCheckForEventType:eventType sender:sender];
}

- (void)presentToolTip:(ToolTip *)tooltip inView:(UIView *)view
{
    if (tooltip.autoHideInSeconds > 0) {
        // Dismiss automatically after a time interval
        if (autoHideTimer) [autoHideTimer invalidate];
        autoHideTimer = [NSTimer scheduledTimerWithTimeInterval:tooltip.autoHideInSeconds
                                                         target:self 
                                                       selector:@selector(dismissTooltip) 
                                                       userInfo:nil 
                                                        repeats:NO];
    }
    
    // Dismiss by tapping outside tooltip
    self.dismissTouchArea = [[[TouchForwardingView alloc] initWithFrame:view.bounds] autorelease];
    [(TouchForwardingView *)dismissTouchArea addTarget:self action:@selector(dismissTooltip)];
    [view addSubview:dismissTouchArea];
    
    // Create the tooltip button
    UIImage *tooltipImage = [UIImage imageNamed:tooltip.imageFile];
    self.tooltipButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [tooltipButton setBackgroundImage:tooltipImage forState:UIControlStateNormal];
    [tooltipButton setFrame:CGRectMake(0, 0, tooltipImage.size.width, tooltipImage.size.height)];
    [tooltipButton setCenter:tooltip.center];

    if (tooltip.displayText) {
        [tooltipButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14]];
        [tooltipButton.titleLabel setShadowColor:(tooltip.displayTextShadowHidden ? [UIColor clearColor] : [UIColor darkGrayColor])];
        [tooltipButton.titleLabel setShadowOffset:CGSizeMake(0, 1)];
        [tooltipButton.titleLabel setLineBreakMode:UILineBreakModeWordWrap];
        [tooltipButton.titleLabel setTextAlignment:UITextAlignmentCenter];
        [tooltipButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [tooltipButton setTitle:tooltip.displayText forState:UIControlStateNormal];
        [tooltipButton setTitleEdgeInsets:tooltip.displayTextEdgeInsets];
    }
    
    if (tooltip.target && tooltip.action) {
        tooltipButton.userInteractionEnabled = YES;
        [tooltipButton addTarget:tooltip.target action:tooltip.action forControlEvents:UIControlEventTouchUpInside];
        [tooltipButton addTarget:self action:@selector(dismissTooltip) forControlEvents:UIControlEventTouchUpInside];
    } else {
        tooltipButton.userInteractionEnabled = NO;
    }
    
    [view addSubview:tooltipButton];

    [tooltipButton setAlpha:0.0f];
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         tooltipButton.alpha = 1.0f; 
                     }
                     completion:^(BOOL finished){
                         
                     }];
    
    // Does this tooltip invalidate any other tooltips?
    NSMutableSet *tooltipsToRemove = [NSMutableSet set];
    if (tooltip.invalidatesToolTip) {
        for (ToolTip *tt in monitoredToolTips) {
            if ([[tt name] isEqualToString:[tooltip invalidatesToolTip]]) {
                [tooltipsToRemove addObject:tt];
            }
        }
    }
    [monitoredToolTips minusSet:tooltipsToRemove];
    
    [[MixpanelAPI sharedAPI] track:AnalyticsEventPresentTooltip properties:[NSDictionary dictionaryWithObjectsAndKeys:tooltip.name, AnalyticsPropertyTooltipName, nil]];

    if (tooltip.resetCountsOnDisplay) {
        // Tooltip can be shown again, reset all the criteria
        for (ToolTipCriteria *criteria in tooltip.validationCriteria) {
            criteria.elapsedCount = [NSNumber numberWithInt:0];
        }
    } else {
        // Tooltip cannot be shown again, remove it
        [monitoredToolTips removeObject:tooltip];                        
    }
}

- (void)dismissTooltip
{
    [autoHideTimer invalidate]; autoHideTimer = nil;
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         tooltipButton.alpha = 0.0f;
                     }
                     completion:^(BOOL finished){
                         [tooltipButton removeFromSuperview];
                         [dismissTouchArea removeFromSuperview];
                         self.tooltipButton = nil;
                         self.dismissTouchArea = nil;                         
                     }];
}

- (void)resetTooltips
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSNumber numberWithInt:0] forKey:NM_SESSION_COUNT_KEY];
    [userDefaults setObject:[NSNumber numberWithInt:0] forKey:kVideoTapCountKey];
    [userDefaults setObject:[NSNumber numberWithInt:0] forKey:kBadVideoTapCountKey];
    [userDefaults setObject:[NSNumber numberWithInt:0] forKey:kChannelManagementTapCountKey];
    [userDefaults setObject:[NSNumber numberWithInt:0] forKey:kSharedVideoTapCountKey];
    [userDefaults setObject:[NSNumber numberWithInt:0] forKey:kWatchLaterTapCountKey];
    [userDefaults setObject:[NSNumber numberWithInt:0] forKey:kChannelListScrollCountKey];
    [userDefaults synchronize];
    
    firstLaunch = YES;
    [self setup];
}

@end
