//
//  NMDataController.h
//  Nowmov
//
//  Created by Bill So on 05/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTask.h"

@class NMChannel;
@class NMVideo;

@interface NMDataController : NSObject {
	NSNotificationCenter * notificationCenter;
	NSOperationQueue * operationQueue;
	
	NSManagedObjectContext * managedObjectContext;
	NSPredicate * channelNamePredicateTemplate;
	NSPredicate * channelNamesPredicateTemplate;
	
	NSArray * sortedVideoList;
}

@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NSArray * sortedVideoList;

- (void)createDataParsingOperationForTask:(NMTask *)atask;

// general data manipulation
- (void)deleteManagedObjects:(id<NSFastEnumeration>)objs;
- (void)deleteAllVideos;
// channels
- (NMChannel *)insertNewChannel;
- (NSDictionary *)fetchChannelsForNames:(NSArray *)channelAy;
// video
- (NMVideo *)insertNewVideo;
- (NSArray *)sortedVideoListForChannel:(NMChannel *)chn;
//- (NSArray *)sortedLiveChannelVideoList;

@end
