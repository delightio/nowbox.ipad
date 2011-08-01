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
#import "NMLibrary.h"
#import "NMStyleUtility.h"

NSString * const NM_CHANNEL_LAST_UPDATE		= @"NM_CHANNEL_LAST_UPDATE";
NSString * const NM_USER_ACCOUNT_ID_KEY		= @"NM_USER_ACCOUNT_ID_KEY";
NSString * const NM_USE_HIGH_QUALITY_VIDEO_KEY		= @"NM_VIDEO_QUALITY_KEY";

@implementation ipadAppDelegate


@synthesize window=_window;
@synthesize viewController;
@synthesize launchViewController;
@synthesize managedObjectContext=managedObjectContext_;

+ (void)initialize {
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:[NSDate distantPast], NM_CHANNEL_LAST_UPDATE, [NSNumber numberWithInteger:1], NM_USER_ACCOUNT_ID_KEY, [NSNumber numberWithBool:YES], NM_USE_HIGH_QUALITY_VIDEO_KEY, nil]];
}

- (void)awakeFromNib {
	// when application:didFinishLaunchingWithOptions: is called the nib file may not have been loaded. Assign MOC to view controller here to ensure the view controller is loaded.
	viewController.managedObjectContext = self.managedObjectContext;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[NMStyleUtility sharedStyleUtility];
	self.viewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	// create task controller
	NMTaskQueueController * ctrl = [NMTaskQueueController sharedTaskQueueController];
	ctrl.managedObjectContext = self.managedObjectContext;
	    
	self.window.rootViewController = self.launchViewController;
	[self.window makeKeyAndVisible];
	
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */
	[viewController setPlaybackCheckpoint];
	[self saveContext];
}

//- (void)applicationWillEnterForeground:(UIApplication *)application
//{
//	[[NMTaskQueueController sharedTaskQueueController] issueGetLiveChannel];
//}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	 */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	/*
	 Called when the application is about to terminate.
	 Save data if appropriate.
	 See also applicationDidEnterBackground:.
	 */
	[viewController setPlaybackCheckpoint];
	[self saveContext];
}

- (void)saveContext {
    
    NSError *error = nil;
	NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc
{
	[_window release];
	[launchViewController release];
	[viewController release];
    [super dealloc];
}

#pragma mark Core Data stack

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
    
	//MARK: debug code
	NSLog(@"debug!!!!!!  removing local cache");
	NSFileManager * fm = [NSFileManager defaultManager];
	if ( [fm fileExistsAtPath:[storeURL path]] ) {
		// remove the file
		[fm removeItemAtURL:storeURL error:nil];
	}

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
