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
#define AnalyticsEventAppWillResignActive @"App Will Resign Active"
#define AnalyticsEventAppDidBecomeActive @"App Did Become Active"
#define AnalyticsEventPresentTooltip @"Present Tooltip"

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
#define AnalyticsEventEnqueueVideo @"Enqueue Video"

// Social events
#define AnalyticsEventStartTwitterLogin @"Start Twitter Login"
#define AnalyticsEventCompleteTwitterLogin @"Complete Twitter Login"
#define AnalyticsEventTwitterLoginFailed @"Twitter Login Failed"
#define AnalyticsEventStartFacebookLogin @"Start Facebook Login"
#define AnalyticsEventCompleteFacebookLogin @"Complete Facebook Login"
#define AnalyticsEventFacebookLoginFailed @"Facebook Login Failed"

/*********************************************
 *                PROPERTIES                 *
 *********************************************/

#define AnalyticsPropertyDevice @"device"
#define AnalyticsPropertyVisitNumber @"visit_number"
#define AnalyticsPropertyAuthFacebook @"auth_facebook"
#define AnalyticsPropertyAuthTwitter @"auth_twitter"
#define AnalyticsPropertyChannelName @"channel_name"
#define AnalyticsPropertySocialChannel @"social_channel"
#define AnalyticsPropertySender @"sender"
#define AnalyticsPropertySearchQuery @"search_query"
#define AnalyticsPropertyCategoryName @"category_name"
#define AnalyticsPropertyVideoName @"video_name"
#define AnalyticsPropertyVideoId @"video_id"
#define AnalyticsPropertyAction @"action"
