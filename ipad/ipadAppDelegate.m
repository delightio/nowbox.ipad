//
//  ipadAppDelegate.m
//  ipad
//
//  Created by Bill So on 30/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ipadAppDelegate.h"
#import "VideoPlaybackViewController.h"
#import "NMLibrary.h"
#import "NMStyleUtility.h"
#import "ToolTipController.h"
#import "Crittercism.h"

#define NM_SESSION_DURATION		1800.0f // 30 min
#define NM_DEBUG_MIXPANEL_TOKEN @"79ed82e53930d8f41c4e87f7084d9158"
#define NM_PROD_MIXPANEL_TOKEN @"e447bed162e427230f5356bc987a5e16"
#define NM_CRITTERCISM_APP_ID @"4f0736d2b093151a900000e7"
#define NM_CRITTERCISM_OAUTH_KEY @"4f0736d2b093151a900000e7jgodwobq"
#define NM_CRITTERCISM_OAUTH_SECRET @"epms3z2y0tg1lzq6hbrpw8icgjtfnvvj"

// user data
NSString * const NM_USER_ACCOUNT_ID_KEY		= @"NM_USER_ACCOUNT_ID_KEY";
NSString * const NM_USER_FAVORITES_CHANNEL_ID_KEY = @"NM_USER_FAVORITES_CHANNEL_ID_KEY";
NSString * const NM_USER_WATCH_LATER_CHANNEL_ID_KEY = @"NM_USER_WATCH_LATER_CHANNEL_ID_KEY";
NSString * const NM_USER_HISTORY_CHANNEL_ID_KEY = @"NM_USER_HISTORY_CHANNEL_ID_KEY";
NSString * const NM_USER_FACEBOOK_CHANNEL_ID_KEY = @"NM_USER_FACEBOOK_CHANNEL_ID_KEY";
NSString * const NM_USER_TWITTER_CHANNEL_ID_KEY = @"NM_USER_TWITTER_CHANNEL_ID_KEY";
NSString * const NM_SETTING_FACEBOOK_AUTO_POST_KEY = @"NM_SETTING_FACEBOOK_AUTO_POST_KEY"; // just need the key. no need for the bool variable
NSString * const NM_USER_YOUTUBE_SYNC_ACTIVE_KEY = @"NM_USER_YOUTUBE_SYNC_ACTIVE_KEY";
NSString * const NM_USER_YOUTUBE_USER_NAME_KEY = @"NM_USER_YOUTUBE_USER_NAME_KEY";
NSString * const NM_USER_YOUTUBE_LAST_SYNC_KEY = @"NM_USER_YOUTUBE_LAST_SYNC_KEY";
NSString * const NM_USER_TOKEN_KEY = @"NM_USER_TOKEN_KEY";
NSString * const NM_USER_TOKEN_EXPIRY_DATE_KEY = @"NM_USER_TOKEN_EXPIRY_DATE_KEY";
NSString * const NM_SETTING_TWITTER_AUTO_POST_KEY = @"NM_SETTING_TWITTER_AUTO_POST_KEY";
// app session
NSString * const NM_CHANNEL_LAST_UPDATE		= @"NM_CHANNEL_LAST_UPDATE";
NSString * const NM_LAST_VIDEO_LIST_KEY		= @"NM_LAST_VIDEO_LIST_KEY";
NSString * const NM_LAST_SESSION_DATE		= @"NM_LAST_SESSION_DATE";
NSString * const NM_SESSION_ID_KEY			= @"NM_SESSION_ID_KEY";
NSString * const NM_FIRST_LAUNCH_KEY		= @"NM_FIRST_LAUNCH_KEY";
NSString * const NM_LAST_CHANNEL_ID_KEY		= @"NM_LAST_CHANNEL_ID_KEY";
NSString * const NM_SESSION_COUNT_KEY		= @"NM_SESSION_COUNT_KEY";
NSString * const NM_TIME_ON_APP_SINCE_INSTALL_KEY = @"NM_TIME_ON_APP_SINCE_INSTALL_KEY";
NSString * const NM_RATE_US_REMINDER_SHOWN_KEY = @"NM_RATE_US_REMINDER_SHOWN_KEY";
NSString * const NM_RATE_US_REMINDER_DEFER_COUNT_KEY = @"NM_RATE_US_REMINDER_DEFER_COUNT_KEY";
NSString * const NM_SHARE_COUNT_KEY         = @"NM_SHARE_COUNT_KEY";
// setting view
NSString * const NM_VIDEO_QUALITY_KEY				= @"NM_VIDEO_QUALITY_KEY";
//NSString * const NM_YOUTUBE_MOBILE_BROWSER_RESOLUTION_KEY = @"NM_YOUTUBE_MOBILE_BROWSER_RESOLUTION_KEY";
NSString * const NM_SHOW_FAVORITE_CHANNEL_KEY		= @"NM_SHOW_FAVORITE_CHANNEL_KEY";
NSString * const NM_ENABLE_PUSH_NOTIFICATION_KEY	= @"NM_ENABLE_PUSH_NOTIFICATION_KEY";
NSString * const NM_ENABLE_EMAIL_NOTIFICATION_KEY	= @"NM_ENABLE_EMAIL_NOTIFICATION_KEY";

BOOL NM_RUNNING_IOS_5;
NSInteger NM_LAST_CHANNEL_ID;

@implementation ipadAppDelegate


@synthesize window=_window;
//@synthesize navigationViewController;
@synthesize viewController;
//@synthesize launchViewController;
@synthesize managedObjectContext=managedObjectContext_;

+ (void)initialize {
	NSNumber * yesNum = [NSNumber numberWithBool:YES];
	NSNumber * noNum = [NSNumber numberWithBool:NO];
	NSNumber * zeroNum = [NSNumber numberWithInteger:0];
	NSDate * dDate = [NSDate distantPast];
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:
	 [NSDictionary dictionaryWithObjectsAndKeys:
	  dDate, NM_CHANNEL_LAST_UPDATE,
	  dDate, NM_LAST_SESSION_DATE,
	  zeroNum, NM_USER_ACCOUNT_ID_KEY, 
	  @"", NM_USER_TOKEN_KEY,
	  @"", NM_USER_YOUTUBE_USER_NAME_KEY,
	  dDate, NM_USER_TOKEN_EXPIRY_DATE_KEY,
      zeroNum, NM_TIME_ON_APP_SINCE_INSTALL_KEY,
      noNum, NM_RATE_US_REMINDER_SHOWN_KEY,
      zeroNum, NM_RATE_US_REMINDER_DEFER_COUNT_KEY,
      zeroNum, NM_SHARE_COUNT_KEY,
	  zeroNum, NM_VIDEO_QUALITY_KEY,
//	  [NSNumber numberWithBool:YES], NM_YOUTUBE_MOBILE_BROWSER_RESOLUTION_KEY,
	  noNum,  NM_SESSION_ID_KEY, 
	  yesNum, NM_FIRST_LAUNCH_KEY, 
	  [NSNumber numberWithInteger:-99999], NM_LAST_CHANNEL_ID_KEY, 
          [NSNumber numberWithInteger:0], NM_SESSION_COUNT_KEY,
	  yesNum, NM_SHOW_FAVORITE_CHANNEL_KEY,
	  noNum, NM_ENABLE_PUSH_NOTIFICATION_KEY,
	  noNum, NM_ENABLE_EMAIL_NOTIFICATION_KEY,
	  noNum, NM_USER_FAVORITES_CHANNEL_ID_KEY,
	  noNum, NM_USER_WATCH_LATER_CHANNEL_ID_KEY,
	  noNum, NM_USER_HISTORY_CHANNEL_ID_KEY,
	  yesNum, NM_SETTING_FACEBOOK_AUTO_POST_KEY,
	  yesNum, NM_SETTING_TWITTER_AUTO_POST_KEY,
	  noNum, NM_USER_YOUTUBE_SYNC_ACTIVE_KEY,
	  zeroNum, NM_USER_YOUTUBE_LAST_SYNC_KEY,
	  [NSArray array], NM_LAST_VIDEO_LIST_KEY,
	  nil]];
}

- (void)awakeFromNib {
	// when application:didFinishLaunchingWithOptions: is called the nib file may not have been loaded. Assign MOC to view controller here to ensure the view controller is loaded.
	viewController.managedObjectContext = self.managedObjectContext;
}

- (void)handleShowErrorAlertNotification:(NSNotification *)aNotification {
	if ( stopShowingError ) return;
	NSError * error = [[aNotification userInfo] objectForKey:@"error"];
	NSString * title = nil;
	NSString * message = nil;
	NSString * errDmn = [error domain];
	if ( [errDmn isEqualToString:NSURLErrorDomain] ) {
		title = @"Connection Error";
		message = [error localizedDescription];
	} else if ( [errDmn isEqualToString:NMServiceErrorDomain] ) {
		switch ([error code]) {
			case 404:
				title = @"Authorization Error";
				message = @"Please contact us for assistance";
				break;
				
			default:
				title = @"Access Denied";
				message = @"Please contact us for assistance";
				break;
		}
	}
	UIAlertView * alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
}

- (void)updateMixpanelProperties {
    // Get the time elapsed rounded to the nearest 10 minutes
    NSDate *now = [NSDate date];
    NSTimeInterval timeOnApp = [now timeIntervalSince1970] - sessionStartTime;
    NSNumber *roundedTime = [NSNumber numberWithInteger:((NSInteger) timeOnApp / 600) * 10];
    
    [dateFormatter setDateFormat:@"HH00"];
    NSString *timeString = [dateFormatter stringFromDate:now];
    [dateFormatter setDateFormat:@"EEEE"];
    NSString *dayOfWeekString = [dateFormatter stringFromDate:now];
    
    [mixpanel registerSuperProperties:[NSDictionary dictionaryWithObjectsAndKeys:roundedTime, AnalyticsPropertyRoundedTimeOnApp,
                                       timeString, AnalyticsPropertyTimeOfDay,
                                       dayOfWeekString, AnalyticsPropertyDayOfWeek, nil]];
}

- (void)setupMixpanel {
    NSInteger sessionCount = [userDefaults integerForKey:NM_SESSION_COUNT_KEY] + 1;
	[userDefaults setInteger:sessionCount forKey:NM_SESSION_COUNT_KEY];
    [userDefaults synchronize];
    
#ifdef MIXPANEL_PROD
    mixpanel = [MixpanelAPI sharedAPIWithToken:NM_PROD_MIXPANEL_TOKEN];
#else
    mixpanel = [MixpanelAPI sharedAPIWithToken:NM_DEBUG_MIXPANEL_TOKEN];
#endif
    
    [mixpanel registerSuperProperties:[NSDictionary dictionaryWithObjectsAndKeys:@"iPad", AnalyticsPropertyDevice,
                                       [NSNumber numberWithInteger:sessionCount], AnalyticsPropertyVisitNumber, 
                                       [NSNumber numberWithBool:NO], AnalyticsPropertyFullScreenVideo, 
                                       [NSNumber numberWithBool:NO], AnalyticsPropertyFullScreenChannelPanel, 
                                       [NSNumber numberWithBool:(NM_USER_FACEBOOK_CHANNEL_ID != 0)], AnalyticsPropertyAuthFacebook,
                                       [NSNumber numberWithBool:(NM_USER_TWITTER_CHANNEL_ID != 0)], AnalyticsPropertyAuthTwitter, 
                                       [NSNumber numberWithBool:NM_USER_YOUTUBE_SYNC_ACTIVE], AnalyticsPropertyAuthYouTube, nil]];
    
    sessionStartTime = [[NSDate date] timeIntervalSince1970];
    appStartTime = sessionStartTime;
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease]];
    [self updateMixpanelProperties];
    [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(updateMixpanelProperties) userInfo:nil repeats:YES];
}

- (NSTimeInterval)timeOnAppSinceInstall
{
    NSTimeInterval timeOnAppSinceInstall = lastTimeOnAppSinceInstall + ([[NSDate date] timeIntervalSince1970] - activeStartTime);
//    NSLog(@"time on app since install: %f", timeOnAppSinceInstall);
    return timeOnAppSinceInstall;
}

#pragma mark Application Lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    userDefaults = [NSUserDefaults standardUserDefaults];

    // Enable analytics and crash reporting
    [self setupMixpanel];
    [Crittercism initWithAppID:NM_CRITTERCISM_APP_ID
                        andKey:NM_CRITTERCISM_OAUTH_KEY
                     andSecret:NM_CRITTERCISM_OAUTH_SECRET
         andMainViewController:viewController];
    
	// detect version
	if ( kCFCoreFoundationVersionNumber > 550.58f ) {
		NM_RUNNING_IOS_5 = YES;
	} else {
		NM_RUNNING_IOS_5 = NO;
	}

	// listen to notification showing alert
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleShowErrorAlertNotification:) name:NMShowErrorAlertNotification object:nil];
	
	[NMStyleUtility sharedStyleUtility];
	self.viewController.appDelegate = self;
	// create task controller
	NMTaskQueueController * ctrl = [NMTaskQueueController sharedTaskQueueController];
	ctrl.managedObjectContext = self.managedObjectContext;

#ifdef DEBUG_ONBOARD_PROCESS
	[userDefaults setBool:YES forKey:NM_FIRST_LAUNCH_KEY];
	[[NMCacheController sharedCacheController] removeAllFiles];
	// delete image cache
	// clear core data
#endif
	// check first launch
	if ( [userDefaults boolForKey:NM_FIRST_LAUNCH_KEY] ) {
		// first time launching the app
		// create internal channels
		[ctrl.dataController setUpDatabaseForFirstLaunch];
		[[NMCacheController sharedCacheController] removeAllFiles];
	}
	NM_LAST_CHANNEL_ID = [userDefaults integerForKey:NM_LAST_CHANNEL_ID_KEY];
    
	self.window.rootViewController = viewController;
	[self.window makeKeyAndVisible];
	
//	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];
  	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:NULL];  
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */
	[self saveCurrentVideoList:[viewController markPlaybackCheckpoint]];
	[self saveContext];
	// release the UI - in particular, remove just the movie player to save memory footprint
	
	// release core data
	
	// cancel tasks
//	[[NMTaskQueueController sharedTaskQueueController] cancelAllTasks];
	[[NMTaskQueueController sharedTaskQueueController] stopPollingServer];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval elapsedSessionTime = now - sessionStartTime;
    NSTimeInterval elapsedTotalTime = now - appStartTime;
    [[MixpanelAPI sharedAPI] track:AnalyticsEventAppEnterBackground properties:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:elapsedSessionTime], AnalyticsPropertySessionElapsedTime, 
                                                                                [NSNumber numberWithFloat:elapsedTotalTime], AnalyticsPropertyTotalElapsedTime, nil]];
	stopShowingError = YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// listen to notification showing alert
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleShowErrorAlertNotification:) name:NMShowErrorAlertNotification object:nil];
	NM_LAST_CHANNEL_ID = [userDefaults integerForKey:NM_LAST_CHANNEL_ID_KEY];
//	[[NMTaskQueueController sharedTaskQueueController] issueGetLiveChannel];
	// start a new session
	NSDate * theDate = [userDefaults objectForKey:NM_LAST_SESSION_DATE];
	NSInteger sid = [userDefaults integerForKey:NM_SESSION_ID_KEY];
	NSArray * vdoList = [userDefaults objectForKey:NM_LAST_VIDEO_LIST_KEY];
	NMTaskQueueController * tqc = [NMTaskQueueController sharedTaskQueueController];
	tqc.dataController.lastSessionVideoIDs = vdoList;
	if ( [theDate timeIntervalSinceNow] < -NM_SESSION_DURATION ) {	// 30 min
		[tqc beginNewSession:++sid];
		[userDefaults setInteger:sid forKey:NM_SESSION_ID_KEY];
	} else {
		// use the same session
		[tqc resumeSession:sid];
	}
	if ( ![userDefaults boolForKey:NM_FIRST_LAUNCH_KEY] ) {
		// poll the server to see if those hidden has got content now.
		[tqc issueRefreshHiddenSubscribedChannels];
		[tqc pollServerForChannelReadiness];
		if ( NM_USER_YOUTUBE_SYNC_ACTIVE ) {
			[tqc issueSyncRequest];
		}
	}
	// refresh video
	[viewController.playbackModelController refreshDirectURLToBufferedVideos];
    
    // Reset the session timer - consider this to be a new session for analytics purposes
    sessionStartTime = [[NSDate date] timeIntervalSince1970];
    [self updateMixpanelProperties];
    NSTimeInterval elapsedTotalTime = [[NSDate date] timeIntervalSince1970] - appStartTime;
    [[MixpanelAPI sharedAPI] track:AnalyticsEventAppEnterForeground properties:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:0], AnalyticsPropertySessionElapsedTime, 
                                                                                [NSNumber numberWithFloat:elapsedTotalTime], AnalyticsPropertyTotalElapsedTime, nil]];
	stopShowingError = NO;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:NM_LAST_SESSION_DATE];
    [[NSUserDefaults standardUserDefaults] setFloat:[self timeOnAppSinceInstall] forKey:NM_TIME_ON_APP_SINCE_INSTALL_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    activeStartTime = [[NSDate date] timeIntervalSince1970];    
    lastTimeOnAppSinceInstall = [[NSUserDefaults standardUserDefaults] floatForKey:NM_TIME_ON_APP_SINCE_INSTALL_KEY];    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	/*
	 Called when the application is about to terminate.
	 Save data if appropriate.
	 See also applicationDidEnterBackground:.
	 */
	[self saveCurrentVideoList:[viewController markPlaybackCheckpoint]];
	[self saveContext];
}

#pragma mark User Defaults

- (void)saveChannelID:(NSNumber *)chnNum {
	NM_LAST_CHANNEL_ID = [chnNum integerValue];
	[userDefaults setInteger:[chnNum integerValue] forKey:NM_LAST_CHANNEL_ID_KEY];
}

- (void)saveCurrentVideoList:(NSArray *)vdoIDs {
	[userDefaults setObject:vdoIDs forKey:NM_LAST_VIDEO_LIST_KEY];
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc
{
	[_window release];
//	[navigationViewController release];
//	[launchViewController release];
	[viewController release];
    [dateFormatter release];

    [super dealloc];
}

#pragma mark Core Data stack
- (void)saveContext {
    
    NSError *error = nil;
	NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
			//            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			//            abort();
//			UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Capture this screen and send to Bill!!!" message:[NSString stringWithFormat:@"Unresolved error %@, %@", error, [error userInfo]] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
//			[alert show];
//			[alert release];
			
			// we should relaunch the app if there's error saving the context
			// reset the context
			//[managedObjectContext reset];
			// fetch stuff as if it's a new channel
			
        } 
    }
}


- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
    
    if (managedObjectContext_ != nil) {
        return managedObjectContext_;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext_ = [[NSManagedObjectContext alloc] init];
        [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext_;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel_ != nil) {
        return managedObjectModel_;
    }
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"Nowmov" ofType:@"mom"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return managedObjectModel_;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (persistentStoreCoordinator_ != nil) {
        return persistentStoreCoordinator_;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Nowmov.sqlite"];
    
#ifdef DEBUG_ONBOARD_PROCESS
	NSLog(@"debug!!!!!!  removing local cache to fool onboard process");
	NSFileManager * fm = [NSFileManager defaultManager];
	if ( [fm fileExistsAtPath:[storeURL path]] ) {
		// remove the file
		[fm removeItemAtURL:storeURL error:nil];
	}
#endif

    NSError *error = nil;
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
		[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
		[persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error];
		//        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		//        abort();
    }    
    
    return persistentStoreCoordinator_;
}

@end
