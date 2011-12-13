//
//  Analytics.h
//  ipad
//
//  Created by Chris Haugli on 10/28/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "MixpanelAPI.h"

/*********************************************
 *                 EVENTS                    *
 *********************************************/

// Generic events
#define AnalyticsEventLogin @"Login"
#define AnalyticsEventPlayVideo @"Play Video"
#define AnalyticsEventAppEnterForeground @"App Enter Foreground"
#define AnalyticsEventAppEnterBackground @"App Enter Background"
#define AnalyticsEventPresentTooltip @"Present Tooltip"
#define AnalyticsEventRateUsDialogShown @"Rate Us Dialog Shown"
#define AnalyticsEventRateUsDialogAccepted @"Rate Us Dialog Accepted"
#define AnalyticsEventRateUsDialogRejected @"Rate Us Dialog Rejected"

// Channel panel events
#define AnalyticsEventShowSettings @"Show Settings"
#define AnalyticsEventShowChannelManagement @"Show Channel Management"

// Channel management events
#define AnalyticsEventSelectCategory @"Select Category"
#define AnalyticsEventShowChannelDetails @"Show Channel Details"
#define AnalyticsEventShowSearch @"Show Search"
#define AnalyticsEventPerformSearch @"Perform Search"
#define AnalyticsEventSubscribeChannel @"Subscribe Channel"
#define AnalyticsEventUnsubscribeChannel @"Unsubscribe Channel"

// Player events
#define AnalyticsEventEnterFullScreenVideo @"Enter Full Screen Video"
#define AnalyticsEventExitFullScreenVideo @"Exit Full Screen Video"
#define AnalyticsEventEnterFullScreenChannelPanel @"Enter Full Screen Channel Panel"
#define AnalyticsEventExitFullScreenChannelPanel @"Enter Full Screen Channel Panel"
#define AnalyticsEventFavoriteVideo @"Favorite Video"
#define AnalyticsEventUnfavoriteVideo @"Unfavorite Video"
#define AnalyticsEventEnqueueVideo @"Enqueue Video"

// Social events
#define AnalyticsEventStartTwitterLogin @"Start Twitter Login"
#define AnalyticsEventCompleteTwitterLogin @"Complete Twitter Login"
#define AnalyticsEventTwitterLoginFailed @"Twitter Login Failed"
#define AnalyticsEventStartFacebookLogin @"Start Facebook Login"
#define AnalyticsEventCompleteFacebookLogin @"Complete Facebook Login"
#define AnalyticsEventFacebookLoginFailed @"Facebook Login Failed"
#define AnalyticsEventStartYouTubeLogin @"Start YouTube Login"
#define AnalyticsEventCompleteYouTubeLogin @"Complete YouTube Login"
#define AnalyticsEventYouTubeLoginFailed @"YouTube Login Failed"

/*********************************************
 *                PROPERTIES                 *
 *********************************************/

#define AnalyticsPropertyDevice @"Device"
#define AnalyticsPropertyVisitNumber @"Visit Number"
#define AnalyticsPropertyAuthFacebook @"Facebook Enabled"
#define AnalyticsPropertyAuthTwitter @"Twitter Enabled"
#define AnalyticsPropertyAuthYouTube @"YouTube Enabled"
#define AnalyticsPropertyChannelName @"Channel Name"
#define AnalyticsPropertySocialChannel @"Social Channel"
#define AnalyticsPropertySender @"Sender"
#define AnalyticsPropertySearchQuery @"Search Query"
#define AnalyticsPropertyCategoryName @"Category Name"
#define AnalyticsPropertyVideoName @"Video Name"
#define AnalyticsPropertyVideoId @"Video ID"
#define AnalyticsPropertyAirPlayActive @"AirPlay Active"
#define AnalyticsPropertyAction @"Action"
#define AnalyticsPropertySessionElapsedTime @"Session Elapsed Time"
#define AnalyticsPropertyTotalElapsedTime @"Total Elapsed Time"
#define AnalyticsPropertyRoundedTimeOnApp @"Rounded Time On App"
#define AnalyticsPropertyTimeOfDay @"Time Of Day"
#define AnalyticsPropertyDayOfWeek @"Day Of Week"
#define AnalyticsPropertyFullScreenVideo @"Full Screen Video"
#define AnalyticsPropertyFullScreenChannelPanel @"Full Screen Channel Panel"
#define AnalyticsPropertyTooltipName @"Tooltip Name"

