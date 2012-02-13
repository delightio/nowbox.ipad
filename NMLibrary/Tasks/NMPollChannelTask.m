//
//  NMPollChannelTask.m
//  ipad
//
//  Created by Bill So on 10/17/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMPollChannelTask.h"
#import "NMChannel.h"
#import "NMSubscription.h"

NSString * const NMWillPollChannelNotification = @"NMWillPollChannelNotification";
NSString * const NMDidPollChannelNotification = @"NMDidPollChannelNotification";
NSString * const NMDidFailPollChannelNotification = @"NMDidFailPollChannelNotification";

@implementation NMPollChannelTask
@synthesize channel, populatedTime = _populatedTime;

- (id)initWithChannel:(NMChannel *)chnObj {
	self = [super init];
	self.channel = chnObj;
	self.targetID = chnObj.nm_id;
	command = NMCommandPollChannel;
	return self;
}

- (void)dealloc {
	[channel release];
	[_populatedTime release];
	[super dealloc];
}

- (NSURLRequest *)URLRequest {
	NSString * urlStr = [NSString stringWithFormat:@"http://%@/channels/%@?user_id=%d", NM_BASE_URL, targetID, NM_USER_ACCOUNT_ID];
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"Poll Channel: %@", urlStr);
#endif
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
#ifndef DEBUG_DO_NOT_SEND_API_TOKEN
	[request addValue:NM_USER_TOKEN forHTTPHeaderField:NMAuthTokenHeaderKey];
#endif
	return request;
}

- (void)processDownloadedDataInBuffer {
	// we are only interested in the "populated_at" value
	if ( [buffer length] == 0 ) return;
	NSDictionary * dict = [buffer objectFromJSONData];
	self.populatedTime = [dict objectForKey:@"populated_at"];
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	channel.populated_at = self.populatedTime;
	return YES;
}

- (NSString *)willLoadNotificationName {
	return NMWillPollChannelNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidPollChannelNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailPollChannelNotification;
}

- (NSDictionary *)userInfo {
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:(_populatedTime != nil)], @"populated", channel, @"channel", nil];
}

@end
