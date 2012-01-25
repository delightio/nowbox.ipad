//
//  NMParseTwitterFeedTask.m
//  ipad
//
//  Created by Bill So on 1/23/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMParseTwitterFeedTask.h"

@implementation NMParseTwitterFeedTask
@synthesize channel = _channel;
@synthesize account = _account;
@synthesize page = _page;
@synthesize sinceID = _sinceID;

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
	NSDictionary * params = [NSDictionary dictionaryWithObjectsAndKeys:@"1", @"include_rts", @"200", @"count", [NSNumber numberWithInteger:_page], @"page", @"since_id", nil];
	TWRequest * twitRequest	= [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.twitter.com/1/statuses/user_timeline.json"] parameters:params requestMethod:TWRequestMethodGET];
	return nil;
}

@end
