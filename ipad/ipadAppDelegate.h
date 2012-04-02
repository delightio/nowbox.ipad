//
//  ipadAppDelegate.h
//  ipad
//
//  Created by Bill So on 30/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Analytics.h"
#import "LaunchViewController.h"
#import "FBConnect.h"

extern NSString * const NM_CHANNEL_LAST_UPDATE;
extern NSString * const NM_LAST_SESSION_DATE;
extern NSString * const NM_USER_ACCOUNT_ID_KEY;
extern NSString * const NM_USER_FAVORITES_CHANNEL_ID_KEY;
extern NSString * const NM_USER_WATCH_LATER_CHANNEL_ID_KEY;
extern NSString * const NM_USER_HISTORY_CHANNEL_ID_KEY;
extern NSString * const NM_USER_FACEBOOK_CHANNEL_ID_KEY;
extern NSString * const NM_USER_TWITTER_CHANNEL_ID_KEY;
extern NSString * const NM_USER_YOUTUBE_SYNC_ACTIVE_KEY;
extern NSString * const NM_USER_YOUTUBE_USER_NAME_KEY;
extern NSString * const NM_USER_YOUTUBE_LAST_SYNC_KEY;
extern NSString * const NM_TIME_ON_APP_SINCE_INSTALL_KEY;
extern NSString * const NM_RATE_US_REMINDER_SHOWN_KEY;
extern NSString * const NM_RATE_US_REMINDER_DEFER_COUNT_KEY;
extern NSString * const NM_SHARE_COUNT_KEY;
extern NSString * const NM_VIDEO_QUALITY_KEY;
extern NSString * const NM_VIDEO_QUALITY_PREFERENCE_KEY;
//extern NSString * const NM_YOUTUBE_MOBILE_BROWSER_RESOLUTION_KEY;
extern NSString * const NM_SESSION_ID_KEY;
extern NSString * const NM_FIRST_LAUNCH_KEY;
extern NSString * const NM_LAST_CHANNEL_ID_KEY;
extern NSString * const NM_SESSION_COUNT_KEY;
extern NSString * const NM_SHOW_FAVORITE_CHANNEL_KEY;	
extern NSString * const NM_ENABLE_PUSH_NOTIFICATION_KEY;
extern NSString * const NM_ENABLE_EMAIL_NOTIFICATION_KEY;
extern NSString * const NM_SETTING_FACEBOOK_AUTO_POST_KEY;
extern NSString * const NM_SETTING_TWITTER_AUTO_POST_KEY;
extern NSString * const NM_LOGOUT_ON_APP_START_PREFERENCE_KEY;

@class VideoPlaybackViewController;
@class LaunchViewController;

@interface ipadAppDelegate : NSObject <UIApplicationDelegate, LaunchViewControllerDelegate> {
	UIViewController *viewController;

@private
	BOOL stopShowingError;
	NSUserDefaults * userDefaults;
    NSManagedObjectContext *managedObjectContext_;
    NSManagedObjectModel *managedObjectModel_;
    NSPersistentStoreCoordinator *persistentStoreCoordinator_;
    
    // Analytics
    MixpanelAPI *mixpanel;
    NSTimeInterval appStartTime;        // When the app was launched
    NSTimeInterval sessionStartTime;    // When the app last became the foreground app
    NSTimeInterval activeStartTime;     // When the app last became active
    NSDateFormatter *dateFormatter;
    
    NSTimeInterval lastTimeOnAppSinceInstall;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIViewController * viewController;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (void)saveChannelID:(NSNumber *)chnNum;
- (void)saveCurrentVideoList:(NSArray *)vdoIDs;
- (NSTimeInterval)timeOnAppSinceInstall;

@end
