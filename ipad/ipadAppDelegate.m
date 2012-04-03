//
//  ipadAppDelegate.m
//  ipad
//
//  Created by Bill So on 30/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ipadAppDelegate.h"
#import "VideoPlaybackViewController.h"
#import "LaunchViewController.h"
#import "FacebookLoginViewController.h"
#import "GridViewController.h"
#import "NMLibrary.h"
#import "NMStyleUtility.h"
#import "ToolTipController.h"
#import "Crittercism.h"

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
NSString * const NM_LOGOUT_ON_APP_START_PREFERENCE_KEY = @"NM_LOGOUT_ON_APP_START_PREFERENCE_KEY";
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
// Facebook token
NSString * const NM_FACEBOOK_ACCESS_TOKEN_KEY = @"FBAccessTokenKey";
NSString * const NM_FACEBOOK_EXPIRATION_DATE_KEY = @"FBExpirationDateKey";
// setting view
NSString * const NM_VIDEO_QUALITY_KEY				= @"NM_VIDEO_QUALITY_KEY";
NSString * const NM_VIDEO_QUALITY_PREFERENCE_KEY	= @"NM_VIDEO_QUALITY_PREFERENCE_KEY";
//NSString * const NM_YOUTUBE_MOBILE_BROWSER_RESOLUTION_KEY = @"NM_YOUTUBE_MOBILE_BROWSER_RESOLUTION_KEY";
NSString * const NM_SHOW_FAVORITE_CHANNEL_KEY		= @"NM_SHOW_FAVORITE_CHANNEL_KEY";
NSString * const NM_ENABLE_PUSH_NOTIFICATION_KEY	= @"NM_ENABLE_PUSH_NOTIFICATION_KEY";
NSString * const NM_ENABLE_EMAIL_NOTIFICATION_KEY	= @"NM_ENABLE_EMAIL_NOTIFICATION_KEY";

BOOL NM_RUNNING_IOS_5;
BOOL NM_RUNNING_ON_IPAD;
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
      noNum, NM_VIDEO_QUALITY_PREFERENCE_KEY,
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
      noNum, NM_LOGOUT_ON_APP_START_PREFERENCE_KEY,
	  noNum, NM_USER_YOUTUBE_SYNC_ACTIVE_KEY,
	  zeroNum, NM_USER_YOUTUBE_LAST_SYNC_KEY,
	  [NSArray array], NM_LAST_VIDEO_LIST_KEY,
	  @"", NM_FACEBOOK_ACCESS_TOKEN_KEY,
	  dDate, NM_FACEBOOK_EXPIRATION_DATE_KEY,
	  nil]];
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
    NSLog(@"model: %@", [[UIDevice currentDevice] model]);
    [mixpanel registerSuperProperties:[NSDictionary dictionaryWithObjectsAndKeys:[[UIDevice currentDevice] model], AnalyticsPropertyDevice,
                                       [NSNumber numberWithInteger:sessionCount], AnalyticsPropertyVisitNumber, 
                                       [NSNumber numberWithBool:NO], AnalyticsPropertyFullScreenVideo, 
                                       [NSNumber numberWithBool:NO], AnalyticsPropertyFullScreenChannelPanel, 
                                       [NSNumber numberWithBool:(NM_USER_FACEBOOK_CHANNEL_ID != 0)], AnalyticsPropertyAuthFacebook,
                                       [NSNumber numberWithBool:(NM_USER_TWITTER_CHANNEL_ID != 0)], AnalyticsPropertyAuthTwitter, 
                                       [NSNumber numberWithBool:NM_USER_YOUTUBE_SYNC_ACTIVE], AnalyticsPropertyAuthYouTube, 
                                       NM_PRODUCT_NAME, AnalyticsPropertyProductName, nil]];
    
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
	NM_RUNNING_ON_IPAD = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    userDefaults = [NSUserDefaults standardUserDefaults];
    // Enable analytics and crash reporting
    [self setupMixpanel];
#ifndef DEBUG
    [Crittercism initWithAppID:NM_CRITTERCISM_APP_ID
                        andKey:NM_CRITTERCISM_OAUTH_KEY
                     andSecret:NM_CRITTERCISM_OAUTH_SECRET
         andMainViewController:viewController];
#endif
    
	// detect version
	if ( kCFCoreFoundationVersionNumber > 550.58f ) {
		NM_RUNNING_IOS_5 = YES;
	} else {
		NM_RUNNING_IOS_5 = NO;
	}

	// listen to notification showing alert
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleShowErrorAlertNotification:) name:NMShowErrorAlertNotification object:nil];
	
	[NMStyleUtility sharedStyleUtility];
    
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
	NM_USER_ACCOUNT_ID = [userDefaults integerForKey:NM_USER_ACCOUNT_ID_KEY];
	NM_USER_WATCH_LATER_CHANNEL_ID = [userDefaults integerForKey:NM_USER_WATCH_LATER_CHANNEL_ID_KEY];
	NM_USER_FAVORITES_CHANNEL_ID = [userDefaults integerForKey:NM_USER_FAVORITES_CHANNEL_ID_KEY];
	NM_USER_HISTORY_CHANNEL_ID = [userDefaults integerForKey:NM_USER_HISTORY_CHANNEL_ID_KEY];
	NM_USER_TWITTER_CHANNEL_ID = [userDefaults integerForKey:NM_USER_TWITTER_CHANNEL_ID_KEY];
	NM_USER_FACEBOOK_CHANNEL_ID = [userDefaults integerForKey:NM_USER_FACEBOOK_CHANNEL_ID_KEY];
	NM_USER_YOUTUBE_SYNC_ACTIVE = [userDefaults boolForKey:NM_USER_YOUTUBE_SYNC_ACTIVE_KEY];
	NM_USER_YOUTUBE_LAST_SYNC = [[userDefaults objectForKey:NM_USER_YOUTUBE_LAST_SYNC_KEY] unsignedIntegerValue];
	NM_VIDEO_QUALITY = [userDefaults integerForKey:NM_VIDEO_QUALITY_KEY];
	NM_USER_YOUTUBE_USER_NAME = [[userDefaults stringForKey:NM_USER_YOUTUBE_USER_NAME_KEY] retain];
	NM_USER_SHOW_FAVORITE_CHANNEL = [userDefaults boolForKey:NM_SHOW_FAVORITE_CHANNEL_KEY];
    NM_RATE_US_REMINDER_SHOWN = [userDefaults boolForKey:NM_RATE_US_REMINDER_SHOWN_KEY];
    NM_RATE_US_REMINDER_DEFER_COUNT = [userDefaults integerForKey:NM_RATE_US_REMINDER_DEFER_COUNT_KEY];
    NM_SHARE_COUNT = [userDefaults integerForKey:NM_SHARE_COUNT_KEY];
    
#ifdef FRIENDBOX
    UIViewController *rootViewController = [[FacebookLoginViewController alloc] initWithManagedObjectContext:self.managedObjectContext
                                                                                                     nibName:@"FacebookLoginViewController"
                                                                                                      bundle:nil];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
    navigationController.navigationBarHidden = YES;
    self.viewController = navigationController;
    [navigationController release];
    [rootViewController release];
#else
    if (NM_RUNNING_ON_IPAD) {
        VideoPlaybackViewController *playbackViewController = [[VideoPlaybackViewController alloc] initWithNibName:@"VideoPlaybackView" bundle:nil];
        playbackViewController.appDelegate = self;
        playbackViewController.managedObjectContext = self.managedObjectContext;
        self.viewController = playbackViewController;
        [playbackViewController release];
    } else {
        LaunchViewController *launchViewController = [[LaunchViewController alloc] initWithNibName:@"LaunchViewController" bundle:nil];
        launchViewController.delegate = self;
        self.viewController = launchViewController;
        [launchViewController release];
    }
#endif
    
	self.window.rootViewController = viewController;
	[self.window makeKeyAndVisible];
	
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];
    
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// stop all account sync related activity FIRST!!
	[[NMAccountManager sharedAccountManager] applicationDidSuspend];
	
    if ([viewController isKindOfClass:[VideoPlaybackViewController class]]) {
        [self saveCurrentVideoList:[((VideoPlaybackViewController *)viewController) markPlaybackCheckpoint]];
    }
	[self saveContext];
	// release the UI - in particular, remove just the movie player to save memory footprint
	
	// release core data
	
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval elapsedSessionTime = now - sessionStartTime;
    NSTimeInterval elapsedTotalTime = now - appStartTime;
    [[MixpanelAPI sharedAPI] track:AnalyticsEventAppEnterBackground properties:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:elapsedSessionTime], AnalyticsPropertySessionElapsedTime, 
                                                                                [NSNumber numberWithFloat:elapsedTotalTime], AnalyticsPropertyTotalElapsedTime, nil]];
	stopShowingError = YES;
	[[NMTaskQueueController sharedTaskQueueController].dataController clearChannelCache];
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
//		[tqc pollServerForChannelReadiness];
		if ( NM_USER_YOUTUBE_SYNC_ACTIVE ) {
			[tqc issueSyncRequest];
		}
		[[NMAccountManager sharedAccountManager] applicationDidLaunch];
	}
    
    if ([viewController isKindOfClass:[VideoPlaybackBaseViewController class]]) {
		// need to check the class type cause it could be the launch view controller instead of the playback view controller
        // refresh video
        [((VideoPlaybackViewController *)viewController).playbackModelController refreshDirectURLToBufferedVideos];
    }
    
    // Reset the session timer - consider this to be a new session for analytics purposes
    sessionStartTime = [[NSDate date] timeIntervalSince1970];
    [self updateMixpanelProperties];
    NSTimeInterval elapsedTotalTime = sessionStartTime - appStartTime;
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

    // User could have changed video quality in preferences
    NM_VIDEO_QUALITY = [userDefaults boolForKey:NM_VIDEO_QUALITY_PREFERENCE_KEY] ? NMVideoQualityAutoSelect : NMVideoQualityAlwaysSD;
    [userDefaults setInteger:NM_VIDEO_QUALITY forKey:NM_VIDEO_QUALITY_KEY];    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	/*
	 Called when the application is about to terminate.
	 Save data if appropriate.
	 See also applicationDidEnterBackground:.
	 */
    if ([viewController isKindOfClass:[VideoPlaybackViewController class]]) {
        [self saveCurrentVideoList:[((VideoPlaybackViewController *)viewController) markPlaybackCheckpoint]];
    }
	[self saveContext];
}

// Pre 4.2 support
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [[NMAccountManager sharedAccountManager].facebook handleOpenURL:url]; 
}

// For 4.2+ support
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[NMAccountManager sharedAccountManager].facebook handleOpenURL:url]; 
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
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"Nowmov" ofType:@"momd"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return managedObjectModel_;
//    managedObjectModel_ = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
//    return managedObjectModel_;
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
    
	NSFileManager * fm = [NSFileManager defaultManager];
    NSError *error = nil;
	NSDictionary * sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:storeURL error:&error];
	NSManagedObjectModel * destinationModel = [self managedObjectModel];
	[storeURL checkResourceIsReachableAndReturnError:&error];
	if (![fm fileExistsAtPath:[storeURL path]] || [destinationModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata] ) {
		// no need to perform migration
		persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
		if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
			[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
			if ( ![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error] ) {
				NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
				abort();
			}
		}    
	} else {
		// perform migration
		
	}
    
    return persistentStoreCoordinator_;
}

#pragma mark - LaunchViewControllerDelegate

- (void)launchViewControllerDidFinish:(LaunchViewController *)launchViewController
{
    GridViewController *gridViewController = [[GridViewController alloc] initWithManagedObjectContext:self.managedObjectContext nibName:@"GridViewController" bundle:[NSBundle mainBundle]];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:gridViewController];
    
    navigationController.navigationBarHidden = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    self.viewController = navigationController;
    self.window.rootViewController = navigationController;
    
    [gridViewController release];
    [navigationController release];
}

@end
