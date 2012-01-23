//
//  NMParseTwitterFeedTask.m
//  ipad
//
//  Created by Bill So on 1/23/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMParseTwitterFeedTask.h"
#import <Twitter/Twitter.h>

@implementation NMParseTwitterFeedTask
@synthesize channel = _channel;

- (id)initWithChannel:(NMChannel *)chnObj {
	self = [super init];
	command = NMCommandParseTwitterFeed;
	self.channel = chnObj;
	return self;
}

- (void)dealloc {
	[_channel release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
//	TWRequest * twRequest = ;
	return nil;
}

@end
