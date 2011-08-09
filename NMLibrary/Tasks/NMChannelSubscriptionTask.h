//
//  NMChannelSubscriptionTask.h
//  ipad
//
//  Created by Bill So on 8/9/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "NMTask.h"

@class NMChannel;

@interface NMChannelSubscriptionTask : NMTask {
	NMChannel * channel;
	NSNumber * channelID;
}

@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NSNumber * channelID;

- (id)initSubscribeChannel:(NMChannel *)aChn;
- (id)initUnsubscribeChannel:(NMChannel *)aChn;

@end
