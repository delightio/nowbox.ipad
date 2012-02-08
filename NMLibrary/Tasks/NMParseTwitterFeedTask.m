//
//  NMParseTwitterFeedTask.m
//  ipad
//
//  Created by Bill So on 1/23/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMParseTwitterFeedTask.h"

NSString * const NMWillParseTwitterFeedNotification = @"NMWillParseTwitterFeedNotification";
NSString * const NMDidParseTwitterFeedNotification = @"NMDidParseTwitterFeedNotification";
NSString * const NMDidFailParseTwitterFeedNotification = @"NMDidFailParseTwitterFeedNotification";

@implementation NMParseTwitterFeedTask
@synthesize channel = _channel;
@synthesize account = _account;
@synthesize page = _page;
@synthesize sinceID = _sinceID;

- (id)initWithChannel:(NMChannel *)chnObj account:(ACAccount *)acObj {
	self = [super init];
	command = NMCommandParseTwitterFeed;
	self.channel = chnObj;
	self.account = acObj;
	return self;
}

- (void)dealloc {
	[_channel release];
	[super dealloc];
}

- (NSURLRequest *)URLRequest {
	NSDictionary * params = nil;
	if ( _sinceID ) {
		params = [NSDictionary dictionaryWithObjectsAndKeys:@"40", @"count", [NSString stringWithFormat:@"%d", _page], @"page", _sinceID, @"since_id", @"1", @"include_entities", nil];
	} else {
		params = [NSDictionary dictionaryWithObjectsAndKeys:@"40", @"count", [NSString stringWithFormat:@"%d", _page], @"page", @"1", @"include_entities", nil];
	}
	TWRequest * twitRequest	= [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.twitter.com/1/statuses/friends_timeline.json"] parameters:params requestMethod:TWRequestMethodGET];
	twitRequest.account = _account;
	NSURLRequest * req = [twitRequest signedURLRequest];
	[twitRequest release];
	return req;
}

- (void)processDownloadedDataInBuffer {
	if ( [buffer length] == 0 ) return;
	id obj = [buffer objectFromJSONData];
	
	NSLog(@"%@", obj);
}

- (NSString *)willLoadNotificationName {
	return NMWillParseTwitterFeedNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidParseTwitterFeedNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailParseTwitterFeedNotification;
}

- (NSDictionary *)userInfo {
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:[parsedObjects count]], @"num_video_received", [NSNumber numberWithUnsignedInteger:[parsedObjects count]], @"num_video_added", _channel, @"channel", /*_nextPageURLString, @"next_url",*/ nil];
}

@end
