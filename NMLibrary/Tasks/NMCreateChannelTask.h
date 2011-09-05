//
//  NMCreateChannelTask.h
//  ipad
//
//  Created by Bill So on 5/9/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMTask.h"

@class NMChannel;

@interface NMCreateChannelTask : NMTask {
	NSString * keyword;
	NMChannel * channel;
	NSMutableDictionary * channelDictionary;
}

@property (nonatomic, retain) NSString * keyword;
@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NSMutableDictionary * channelDictionary;

- (id)initWithKeyword:(NSString *)str;

@end
