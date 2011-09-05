//
//  NMCreateChannelTask.m
//  ipad
//
//  Created by Bill So on 5/9/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMCreateChannelTask.h"
#import "NMDataController.h"

NSString * const NMWillCreateChannelNotification = @"NMWillCreateChannelNotification";
NSString * const NMDidCreateChannelNotification = @"NMDidCreateChannelNotification";
NSString * const NMDidFailCreateChannelNotification = @"NMDidFailCreateChannelNotification";

@implementation NMCreateChannelTask
@synthesize keyword, channelDictionary;

- (id)initWithKeyword:(NSString *)str {
	self = [super init];
	command = NMCommandCreateKeywordChannel;
	self.keyword = str;
	return self;
}

- (void)dealloc {
	[keyword release];
	[channelDictionary release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSString * urlStr = [NSString stringWithFormat:@"http://%@/channels?user_id=%d&query=%@&type=yeyword", NM_BASE_URL, NM_USER_ACCOUNT_ID, [keyword stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	[request setHTTPMethod:@"POST"];
	return request;
}

- (void)processDownloadedDataInBuffer {
	if ( [buffer length] == 0 ) {
		return;
	}
	self.channelDictionary = [buffer objectFromJSONData];
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	// save the new channel
	NMChannel * chnObj = [ctrl insertNewChannelForID:[channelDictionary objectForKey:@""]];
	[chnObj setValuesForKeysWithDictionary:channelDictionary];
}

- (NSString *)willLoadNotificationName {
	return NMWillCreateChannelNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidCreateChannelNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailCreateChannelNotification;
}

@end
