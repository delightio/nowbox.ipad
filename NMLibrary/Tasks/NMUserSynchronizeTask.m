//
//  NMUserSynchronizeTask.m
//  ipad
//
//  Created by Bill So on 11/16/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMUserSynchronizeTask.h"

NSString * const NMWillSynchronizeUserNotification = @"NMWillSynchronizeUserNotification";
NSString * const NMDidSynchronizeUserNotification = @"NMDidSynchronizeUserNotification";
NSString * const NMDidFailSynchronizeUserNotification = @"NMDidFailSynchronizeUserNotification";

@implementation NMUserSynchronizeTask

- (id)init {
	self = [super init];
	self.targetID = [NSNumber numberWithInteger:NM_USER_ACCOUNT_ID];
	command = NMCommandUserSynchronize;
	return self;
}

- (NSURLRequest *)URLRequest {
	NSString * urlStr = [NSString stringWithFormat:@"http://%@/users/%d/synchronize", NM_BASE_URL, NM_USER_ACCOUNT_ID];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	[request setHTTPMethod:@"POST"];
#ifndef DEBUG_DO_NOT_SEND_API_TOKEN
	[request addValue:NM_USER_TOKEN forHTTPHeaderField:NMAuthTokenHeaderKey];
#endif
	return request;
}

- (void)processDownloadedDataInBuffer {
	if ( [buffer length] == 0 ) {
		encountersErrorDuringProcessing = YES;
		return;
	}
	// results the same User JSON as get user
	NSDictionary * userDict = [buffer objectFromJSONData];
	// get the synchronized_at attribute
	NSArray * acAy = [userDict objectForKey:@"accounts"];
	if ( acAy ) {
		NSString * providerStr = nil;
		for (NSDictionary * acDict in acAy) {
			providerStr = [acDict objectForKey:@"provider"];
			if ( [providerStr isEqualToString:@"youtube"] || [providerStr isEqualToString:@"you_tube"] ) {
				NM_USER_YOUTUBE_SYNC_SERVER_TIME = [[acDict objectForKey:@"synchronized_at"] unsignedIntegerValue];
			}
		}
	}
}

- (NSString *)willLoadNotificationName {
	return NMWillSynchronizeUserNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidSynchronizeUserNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailSynchronizeUserNotification;
}

@end
