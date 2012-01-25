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
@synthesize versionDictionary;

- (id)initWithDeviceType:(NSString *)devType {
	self = [super init];
	
	command = NMCommandCheckUpdate;
	deviceType = [devType retain];
	
	return self;
}

- (void)dealloc {
	[deviceType release];
	[versionDictionary release];
	[super dealloc];
}

- (NSURLRequest *)URLRequest {
	NSString * urlStr = [NSString stringWithFormat:@"http://%@/info?device=%@", NM_BASE_URL, deviceType];
	return [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
}

- (void)processDownloadedDataInBuffer {
	if ( [buffer length] == 0 ) return;
	self.versionDictionary = [buffer objectFromJSONData];
}

- (NSDictionary *)userInfo {
	return versionDictionary;
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
