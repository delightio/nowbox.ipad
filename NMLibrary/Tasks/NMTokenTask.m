//
//  NMTokenTask.m
//  ipad
//
//  Created by Bill So on 11/5/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMTokenTask.h"

NSString * const NMWillRequestTokenNotification = @"NMWillRequestTokenNotification";
NSString * const NMDidRequestTokenNotification = @"NMDidRequestTokenNotification";
NSString * const NMDidFailRequestTokenNotification = @"NMDidFailRequestTokenNotification";

@implementation NMTokenTask
@synthesize secret;

- (id)initGetToken {
	self = [super init];
	command = NMCommandGetToken;
	secret = @"j3sBP0aRG8neHoWe7MtLDp6aPQYQUQjhtIh9cVFjmiQPvdYFpWi2PbxVZrpwa7t1YrMzWtppR1crSyNV3w";
	return self;
}

//- (id)initTestToken {
//	self = [super init];
//	command = NMCommandTestToken;
//	return self;
//}

- (NSURLRequest *)URLRequest {
	NSString * urlStr = nil;
	NSMutableURLRequest * request = nil;
	switch (command) {
		case NMCommandGetToken:
			urlStr = [NSString stringWithFormat:@"https://%@/auth/request_token?secret=%@&user_id=%d", NM_BASE_URL_TOKEN, secret, NM_USER_ACCOUNT_ID];
			request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
			[request setHTTPMethod:@"POST"];
			break;
			
//		case NMCommandTestToken:
//			urlStr = [NSString stringWithFormat:@"http://%@/users/%d/auth_test", NM_BASE_URL, NM_USER_ACCOUNT_ID];
//			request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
//#ifndef DEBUG_DO_NOT_SEND_API_TOKEN
//			[request addValue:NM_USER_TOKEN forHTTPHeaderField:NMAuthTokenHeaderKey];
//#endif
//			break;
			
		default:
			break;
	}
	return request;
}

- (void)processDownloadedDataInBuffer {
	if ( [buffer length] == 0 ) return;
	
	switch (command) {
		case NMCommandGetToken:
		{
			NSDictionary * tkDict = [buffer objectFromJSONData];
			// store token and expiry date
			[NM_USER_TOKEN release]; NM_USER_TOKEN = nil;
			[NM_USER_TOKEN_EXPIRY_DATE release]; NM_USER_TOKEN_EXPIRY_DATE = nil;
			NM_USER_TOKEN = [[tkDict objectForKey:@"token"] retain];
			NM_USER_TOKEN_EXPIRY_DATE = [[NSDate dateWithTimeIntervalSince1970:[[tkDict objectForKey:@"expires_at"] floatValue]] retain];
			break;
		}
//		case NMCommandTestToken:
//		{
//			NSString * str = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
//			NSLog(@"Token test result: %@", str);
//			[str release];
//			break;
//		}
		default:
			break;
	}
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	return NO;
}

- (NSString *)willLoadNotificationName {
	return NMWillRequestTokenNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidRequestTokenNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailRequestTokenNotification;
}

@end
