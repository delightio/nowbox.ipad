//
//  NMGetChannelsTask.h
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTask.h"

@class NMChannel;
@class NMCategory;

@interface NMGetChannelsTask : NMTask {
	NSArray * channelJSONKeys;
//	NMChannel * trendingChannel;
	NMCategory * category;
	NSString * searchWord;
	NSMutableIndexSet * channelIndexSet;
	NSMutableDictionary * parsedObjectDictionary;
	NSMutableArray * categoryIDs;
}

//@property (nonatomic, retain) NMChannel * trendingChannel;
@property (nonatomic, retain) NSString * searchWord;
@property (nonatomic, retain) NMCategory * category;

+ (NSMutableDictionary *)normalizeChannelDictionary:(NSDictionary *)chnCtnDict;

- (id)initGetDefaultChannels;
- (id)initGetChannelForCategory:(NMCategory *)aCat;
- (id)initSearchChannelWithKeyword:(NSString *)str;
- (id)initGetChannelWithID:(NSInteger)chnID;
- (id)initGetFeaturedChannelsForCategories:(NSArray *)catArray;
- (id)initCompareSubscribedChannels;

@end
