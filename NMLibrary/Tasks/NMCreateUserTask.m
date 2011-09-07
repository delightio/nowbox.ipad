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
	NSString * urlStr = [NSString stringWithFormat:@"http://%@/users", NM_BASE_URL];
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
		// save the data to Keychain
		
		// update global variable
		NM_USER_ACCOUNT_ID = uid;
	} else {
		encountersErrorDuringProcessing = YES;
	}
}

//- (void)saveProcessedDataInController:(NMDataController *)ctrl {
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
