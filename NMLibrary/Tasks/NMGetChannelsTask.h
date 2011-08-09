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
	NMChannel * trendingChannel;
	NMCategory * category;
	NSNumber * categoryID;
	NSString * searchWord;
}

@property (nonatomic, retain) NMChannel * trendingChannel;
@property (nonatomic, retain) NSString * searchWord;
@property (nonatomic, retain) NMCategory * category;
@property (nonatomic, retain) NSNumber * categoryID;

- (id)initGetFriendChannels;
- (id)initGetTopicChannels;
- (id)initGetDefaultChannels;

@end
