//
//  NMSignOutUserTask.m
//  ipad
//
//  Created by Bill So on 10/16/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMSignOutUserTask.h"
#import "NMDataController.h"

NSString * const NMWillSignOutUserNotification = @"NMWillSignOutUserNotification";
NSString * const NMDidSignOutUserNotification = @"NMDidSignOutUserNotification";
NSString * const NMDidFailSignOutUserNotification = @"NMDidFailSignOutUserNotification";

@implementation NMSignOutUserTask

- (id)initWithCommand:(NMCommand)aCmd {
	self = [super init];
	command = aCmd;
	return self;
}

- (NSMutableURLRequest *)URLRequest {
	NSString * srv = nil;
	switch (command) {
		case NMCommandDeauthoriseFaceBookAccount:
			srv = @"facebook";
			break;
			
		case NMCommandDeauthoriseTwitterAccount:
			srv = @"twitter";
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
	NSString * str = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
	NSLog(@"%@", str);
}

- (NSString *)willLoadNotificationName {
	return NMWillSignOutUserNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidSignOutUserNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailSignOutUserNotification;
}

@end
