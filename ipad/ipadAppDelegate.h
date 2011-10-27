//
//  ipadAppDelegate.h
//  ipad
//
//  Created by Bill So on 30/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MixpanelAPI.h"

extern NSString * const NM_CHANNEL_LAST_UPDATE;
extern NSString * const NM_LAST_SESSION_DATE;
extern NSString * const NM_USER_ACCOUNT_ID_KEY;
extern NSString * const NM_USER_FAVORITES_CHANNEL_ID_KEY;
extern NSString * const NM_USER_WATCH_LATER_CHANNEL_ID_KEY;
extern NSString * const NM_USER_HISTORY_CHANNEL_ID_KEY;
extern NSString * const NM_USER_FACEBOOK_CHANNEL_ID_KEY;
extern NSString * const NM_USER_TWITTER_CHANNEL_ID_KEY;
extern NSString * const NM_USE_HIGH_QUALITY_VIDEO_KEY;
extern NSString * const NM_YOUTUBE_MOBILE_BROWSER_RESOLUTION_KEY;
extern NSString * const NM_SESSION_ID_KEY;
extern NSString * const NM_FIRST_LAUNCH_KEY;
extern NSString * const NM_LAST_CHANNEL_ID_KEY;
extern NSString * const NM_SESSION_COUNT_KEY;
extern NSString * const NM_SHOW_FAVORITE_CHANNEL_KEY;	
extern NSString * const NM_ENABLE_PUSH_NOTIFICATION_KEY;
extern NSString * const NM_ENABLE_EMAIL_NOTIFICATION_KEY;

@class VideoPlaybackViewController;
@class LaunchViewController;

@interface ipadAppDelegate : NSObject <UIApplicationDelegate> {
	VideoPlaybackViewController *viewController;
//	LaunchViewController *launchViewController;
//	UINavigationController * navigationViewController;

@private
	NSUserDefaults * userDefaults;
    NSManagedObjectContext *managedObjectContext_;
    NSManagedObjectModel *managedObjectModel_;
    NSPersistentStoreCoordinator *persistentStoreCoordinator_;
    
    // Analytics
    MixpanelAPI *mixpanel;
    NSTimeInterval applicationStartTime;
    NSDateFormatter *dateFormatter;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet VideoPlaybackViewController * viewController;
//@property (nonatomic, retain) IBOutlet LaunchViewController * launchViewController;
//@property (nonatomic, retain) IBOutlet UINavigationController * navigationViewController;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (void)saveChannelID:(NSNumber *)chnNum;
- (void)saveCurrentVideoList:(NSArray *)vdoIDs;

@end
