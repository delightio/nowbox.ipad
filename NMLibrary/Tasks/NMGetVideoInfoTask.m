//
//  NMGetVideoInfoTask.m
//  Nowmov
//
//  Created by Bill So on 10/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMGetVideoInfoTask.h"
#import "NMDataController.h"
#import "NMVideo.h"
#import "NMChannel.h"

NSString * const NMWillGetVideoInfoNotification = @"NMWillGetVideoInfoNotification";
NSString * const NMDidGetVideoInfoNotification = @"NMDidGetVideoInfoNotification";


@implementation NMGetVideoInfoTask

@synthesize video;

- (id)initWithVideo:(NMVideo *)aVideo {
	self = [super init];
	command = NMCommandGetVideoInfo;
	self.video = aVideo;
	self.channelName = aVideo.channel.channel_name;
	videoID = [aVideo.vid integerValue];
	return self;
}

- (void)dealloc {
	[infoDictionary release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
#ifdef NOWMOV_USE_BETA_SITE
	NSString * urlStr = [NSString stringWithFormat:@"http://beta.nowmov.com/%@/%d/info", channelName, videoID];
#else
	NSString * urlStr = [NSString stringWithFormat:@"http://nowmov.com/%@/%d/info", channelName, videoID];
#endif
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	
	return request;
}

- (void)processDownloadedDataInBuffer {
	if ( [buffer length] == 0 ) return;
	NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithDictionary:[buffer objectFromJSONData]];
	// date
	//TODO: make sure timezone is set correctly. timestamp from server is pacific time
	[dict setObject:[NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"created_at"] floatValue]] forKey:@"created_at"];
	[dict setObject:[dict objectForKey:@"description"] forKey:@"nm_description"];
	[dict removeObjectForKey:@"description"];
	infoDictionary = [dict retain];
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	[video setValuesForKeysWithDictionary:infoDictionary];
}

- (NSString *)willLoadNotificationName {
	return NMWillGetVideoInfoNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidGetVideoInfoNotification;
}

- (NSDictionary *)userInfo {
	return [NSDictionary dictionaryWithObject:video forKey:@"target_object"];
}

@end
