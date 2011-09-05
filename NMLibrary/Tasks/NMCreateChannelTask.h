//
//  NMCreateChannelTask.h
//  ipad
//
//  Created by Bill So on 5/9/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMTask.h"

@interface NMCreateChannelTask : NMTask {
	NSString * keyword;
	NSDictionary * channelDictionary;
}

@property (nonatomic, retain) NSString * keyword;
@property (nonatomic, retain) NSDictionary * channelDictionary;

- (id)initWithKeyword:(NSString *)str;

@end
