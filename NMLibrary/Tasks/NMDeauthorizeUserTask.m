//
//  NMDeauthorizeUserTask.m
//  ipad
//
//  Created by Bill So on 10/16/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMDeauthorizeUserTask.h"
#import "NMDataController.h"
#import "NMCreateUserTask.h"

NSString * const NMWillDeauthorizeUserNotification = @"NMWillDeauthorizeUserNotification";
NSString * const NMDidDeauthorizeUserNotification = @"NMDidDeauthorizeUserNotification";
NSString * const NMDidFailDeauthorizeUserNotification = @"NMDidFailDeauthorizeUserNotification";

@implementation NMDeauthorizeUserTask
@synthesize userDictionary;

- (id)initForYouTube {
	self = [super init];
	command = NMCommandDeauthorizeYoutubeUser;
	return self;
}

- (void)dealloc {
	[userDictionary release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSString * srv = nil;
	switch (command) {
		case NMCommandDeauthorizeYoutubeUser:
			srv = @"you_tube";
			break;
						
		default:
			break;
	}
	NSString * urlStr = [NSString stringWithFormat:@"http://%@/auth/%@/deauthorize?user_id=%d", NM_BASE_URL_TOKEN, srv, NM_USER_ACCOUNT_ID];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
#ifndef DEBUG_DO_NOT_SEND_API_TOKEN
	[request addValue:NM_USER_TOKEN forHTTPHeaderField:NMAuthTokenHeaderKey];
#endif
	[request setHTTPMethod:@"POST"];
	return request;
}

- (void)processDownloadedDataInBuffer {
	if ( [buffer length] == 0 ) {
		return;
	}
	self.userDictionary = [buffer objectFromJSONData];
	// update user info as if the user has just been created.
	if ( NM_USER_YOUTUBE_USER_NAME ) {
		[NM_USER_YOUTUBE_USER_NAME release];
		NM_USER_YOUTUBE_USER_NAME = nil;
	}
	NM_USER_YOUTUBE_SYNC_ACTIVE = NO;
	NM_USER_YOUTUBE_LAST_SYNC = 0;
	encountersErrorDuringProcessing = [NMCreateUserTask updateAppUserInfo:userDictionary] == 0;
}

- (NSString *)willLoadNotificationName {
	return NMWillDeauthorizeUserNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidDeauthorizeUserNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailDeauthorizeUserNotification;
}

@end
