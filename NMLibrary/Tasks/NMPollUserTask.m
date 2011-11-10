//
//  NMPollUserTask.m
//  ipad
//
//  Created by Bill So on 10/17/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMPollUserTask.h"
#import "NMChannel.h"

NSString * const NMWillPollUserNotification = @"NMWillPollUserNotification";
NSString * const NMDidPollUserNotification = @"NMDidPollUserNotification";
NSString * const NMDidFailPollUserNotification = @"NMDidFailPollUserNotification";

@implementation NMPollUserTask
@synthesize channel, datePopulated;

- (id)initWithChannel:(NMChannel *)chnObj {
	self = [super init];
	self.targetID = [NSNumber numberWithInteger:NM_USER_ACCOUNT_ID];
	command = NMCommandPollUser;
	return self;
}

- (void)dealloc {
	[datePopulated release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSString * urlStr = [NSString stringWithFormat:@"http://%@/users/%d", NM_BASE_URL, NM_USER_ACCOUNT_ID];
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
	float unixPopTime = [[dict objectForKey:@"populated_at"] floatValue];
	if ( unixPopTime != 0.0f ) {
		// there's no more need to poll server on this task.
		self.datePopulated = [NSDate dateWithTimeIntervalSince1970:unixPopTime];
	}
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	channel.populated_at = datePopulated;
	return YES;
}

- (NSString *)willLoadNotificationName {
	return NMWillPollUserNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidPollUserNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailPollUserNotification;
}

- (NSDictionary *)userInfo {
	return [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:accountSynced] forKey:@"youtube_synced"];
}

@end
