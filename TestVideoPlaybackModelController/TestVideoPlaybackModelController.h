//
//  TestVideoPlaybackModelController.h
//  TestVideoPlaybackModelController
//
//  Created by Bill So on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>


@class VideoPlaybackModelController;

@interface TestVideoPlaybackModelController : SenTestCase {
@private
    VideoPlaybackModelController * playbackModelController;
    NSManagedObjectContext *managedObjectContext_;
    NSManagedObjectModel *managedObjectModel_;
    NSPersistentStoreCoordinator *persistentStoreCoordinator_;
}

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end
