//
//  ipadAppDelegate.h
//  ipad
//
//  Created by Bill So on 30/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const NM_CHANNEL_LAST_UPDATE;
extern NSString * const NM_USER_ACCOUNT_ID_KEY;
extern NSString * const NM_USE_HIGH_QUALITY_VIDEO_KEY;
extern NSString * const NM_SESSION_ID_KEY;
extern NSString * const NM_FIRST_LAUNCH_KEY;
extern NSString * const NM_LAST_CHANNEL_ID_KEY;
extern NSString * const NM_SHOW_FAVORITE_CHANNEL_KEY;	
extern NSString * const NM_ENABLE_PUSH_NOTIFICATION_KEY;
extern NSString * const NM_ENABLE_EMAIL_NOTIFICATION_KEY;

@class VideoPlaybackViewController;
@class LaunchViewController;

@interface ipadAppDelegate : NSObject <UIApplicationDelegate> {
	VideoPlaybackViewController *viewController;
	LaunchViewController *launchViewController;

@private
	NSUserDefaults * userDefaults;
    NSManagedObjectContext *managedObjectContext_;
    NSManagedObjectModel *managedObjectModel_;
    NSPersistentStoreCoordinator *persistentStoreCoordinator_;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet VideoPlaybackViewController * viewController;
@property (nonatomic, retain) IBOutlet LaunchViewController * launchViewController;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (void)saveChannelID:(NSNumber *)chnNum;

@end
