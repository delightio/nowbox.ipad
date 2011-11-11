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
	NSString * urlStr = [NSString stringWithFormat:@"http://%@/auth/%@/deauthorize?user_id=%d", NM_BASE_URL, srv, NM_USER_ACCOUNT_ID];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	[request setHTTPMethod:@"POST"];
	return request;
}

- (void)processDownloadedDataInBuffer {
	if ( [buffer length] == 0 ) {
		return;
	}
	self.userDictionary = [buffer objectFromJSONData];
	// update user info as if the user has just been created.
	encountersErrorDuringProcessing = [NMCreateUserTask updateAppUserInfo:userDictionary] == 0;
	
	NSString * str = [[[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding] autorelease];
	NSLog(@"%@", str);
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
