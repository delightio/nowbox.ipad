//
//  NMCheckUpdateTask.m
//  ipad
//
//  Created by Bill So on 10/31/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMCheckUpdateTask.h"

NSString * const NMWillCheckUpdateNotification = @"NMWillCheckUpdateNotification";
NSString * const NMDidCheckUpdateNotification = @"NMDidCheckUpdateNotification";
NSString * const NMDidFailCheckUpdateNotification = @"NMDidFailCheckUpdateNotification";

@implementation NMCheckUpdateTask

- (NSMutableURLRequest *)URLRequest {
	return [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/", NM_BASE_URL]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
}

- (NSString *)willLoadNotificationName {
	return NMWillCheckUpdateNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidCheckUpdateNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailCheckUpdateNotification;
}

@end
