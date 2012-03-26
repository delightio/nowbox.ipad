//
//  NMGetChannelVideosTask.h
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTask.h"
#import "NMTaskQueueController.h"

@class NMChannel;

@interface NMGetChannelVideoListTask : NMTask {
	NMChannel * channel;
	NSString * channelName;
	NSString * urlString;
	NSMutableArray * parsedDetailObjects;
	BOOL newChannel;
	NSUInteger numberOfVideoAdded, totalNumberOfRows;
	NSUInteger numberOfRowsFromServer;
	NSUInteger currentPage;
	BOOL isFavoriteChannel, isWatchLaterChannel;
	NSString * videoID;
}

@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NSString * channelName;
@property (nonatomic, retain) NSString * urlString;
@property (nonatomic) NSUInteger currentPage;
@property (nonatomic) BOOL newChannel;
@property (nonatomic) NSUInteger numberOfVideoAdded;
@property (nonatomic, retain) NSString * videoID;

// in this wind-down version. we only have one single channel - Live
//- (id)initWithChannel:(NMChannel *)aChn;
- (id)initGetMoreVideoForChannel:(NMChannel *)aChn;
- (id)initGetNewerVideoForChannel:(NMChannel *)aChn since:(NSString *)aSinceID;
- (id)initGetOlderVideoForChannel:(NMChannel *)aChn after:(NSString *)aMaxID;

+ (NSMutableDictionary *)normalizeVideoDictionary:(NSDictionary *)dict;
+ (NSMutableDictionary *)normalizeDetailDictionary:(NSDictionary *)dict;

@end
