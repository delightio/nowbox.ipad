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

- (id)initWithChannel:(NMChannel *)chnObj account:(ACAccount *)anAccount {
	self = [super init];
	command = NMCommandParseTwitterFeed;
	self.channel = chnObj;
	self.account = anAccount;
	return self;
}

- (void)dealloc {
	[_channel release];
	[super dealloc];
}

- (NSURLRequest *)URLRequest {
	NSDictionary * params = nil;
	if ( _sinceID ) {
		params = [NSDictionary dictionaryWithObjectsAndKeys:@"40", @"count", [NSNumber numberWithInteger:_page], @"page", _sinceID, @"since_id", nil];
	} else {
		params = [NSDictionary dictionaryWithObjectsAndKeys:@"40", @"count", [NSNumber numberWithInteger:_page], @"page", nil];
	}
	TWRequest * twitRequest	= [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.twitter.com/1/statuses/friends_timeline.json"] parameters:params requestMethod:TWRequestMethodGET];
	NSURLRequest * req = [twitRequest signedURLRequest];
	[twitRequest release];
	return req;
}

- (void)processDownloadedDataInBuffer {
	if ( [buffer length] == 0 ) return;
	id obj = [buffer objectFromJSONData];
	NSLog(@"%@", obj);
}

@end
