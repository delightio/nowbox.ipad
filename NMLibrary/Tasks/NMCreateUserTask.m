//
//  NMCreateUserTask.m
//  ipad
//
//  Created by Bill So on 7/9/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMCreateUserTask.h"

NSString * const NMWillCreateUserNotification = @"NMWillCreateUserNotification";
NSString * const NMDidCreateUserNotification = @"NMDidCreateUserNotification";
NSString * const NMDidFailCreateUserNotification = @"NMDidFailCreateUserNotification";

@implementation NMCreateUserTask

- (id)init {
	self = [super init];
	command = NMCommandCreateUser;
	return self;
}

- (NSMutableURLRequest *)URLRequest {
	// get current local
	NSLog(@"timezone: %@", [[NSTimeZone systemTimeZone] name]);
	NSString * urlStr = [NSString stringWithFormat:@"http://%@/users?locale=%@", NM_BASE_URL, [[NSLocale currentLocale] localeIdentifier]];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	[request setHTTPMethod:@"POST"];
	return request;
}

- (void)processDownloadedDataInBuffer {
	if ( [buffer length] == 0 ) {
		encountersErrorDuringProcessing = YES;
		return;
	}
	// parse the returned JSON object
	NSDictionary * theDict = [buffer objectFromJSONData];
	NSInteger uid = [[theDict objectForKey:@"id"] integerValue];
	if ( uid ) {
		//TODO: save the data to Keychain
		
		// update global variable
		NM_USER_ACCOUNT_ID = uid;
		NM_USER_WATCH_LATER_CHANNEL_ID = [[theDict objectForKey:@"queue_channel_id"] integerValue];
		NM_USER_FAVORITES_CHANNEL_ID = [[theDict objectForKey:@"favorite_channel_id"] integerValue];
		NM_USER_HISTORY_CHANNEL_ID = [[theDict objectForKey:@"history_channel_id"] integerValue];
	} else {
		encountersErrorDuringProcessing = YES;
	}
}

//- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
//	// nth to do
//}

- (NSString *)willLoadNotificationName {
	return NMWillCreateUserNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidCreateUserNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailCreateUserNotification;
}

@end
