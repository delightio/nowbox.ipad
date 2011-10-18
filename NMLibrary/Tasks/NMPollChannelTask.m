//
//  NMPollChannelTask.m
//  ipad
//
//  Created by Bill So on 10/17/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMPollChannelTask.h"
#import "NMChannel.h"

NSString * const NMWillPollChannelNotification = @"NMWillPollChannelNotification";
NSString * const NMDidPollChannelNotification = @"NMDidPollChannelNotification";
NSString * const NMDidFailPollChannelNotification = @"NMDidFailPollChannelNotification";

@implementation NMPollChannelTask
@synthesize channel;

- (id)initWithChannel:(NMChannel *)chnObj {
	self = [super init];
	self.channel = chnObj;
	command = NMCommandPollChannel;
	return self;
}

- (void)dealloc {
	[channel release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSString * urlStr = [NSString stringWithFormat:@"http://%@/channels/%@?user_id=%d", NM_BASE_URL, targetID, NM_USER_ACCOUNT_ID];
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"Poll Channel: %@", urlStr);
#endif
	return [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
}

- (void)processDownloadedDataInBuffer {
	// we are only interested in the "populated_at" value
	if ( [buffer length] == 0 ) return;
	NSDictionary * dict = [buffer objectFromJSONData];
	if ( [[dict objectForKey:@"populated__at"] integerValue] == 0 ) {
		// the channel has never been populated yet. Still need to poll the server
		populated = NO;
	} else {
		// there's no more need to poll server on this task.
		populated = YES;
	}
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	return NO;
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
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:populated], @"populated", channel, @"channel", nil];
}

@end
