//
//  NMGetChannelDetailTask.m
//  ipad
//
//  Created by Bill So on 8/31/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMGetChannelDetailTask.h"
#import "NMDataController.h"
#import "NMChannel.h"
#import "NMChannelDetail.h"
#import "NMPreviewThumbnail.h"

NSString * const NMWillGetChannelDetailNotification = @"NMWillGetChannelDetailNotification";
NSString * const NMDidGetChannelDetailNotification = @"NMDidGetChannelDetailNotification";
NSString * const NMDidFailGetChannelDetailNotification = @"NMDidFailGetChannelDetailNotification";

@implementation NMGetChannelDetailTask
@synthesize channel;

- (id)initWithChannel:(NMChannel *)chn {
	self = [super init];
	command = NMCommandGetChannelDetail;
	self.targetID = chn.nm_id;
	self.channel = chn;
	return self;
}

- (void)dealloc {
	[channel release];
	[videoThumbnailURIs release];
	[channelDescription release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSString * urlStr = [NSString stringWithFormat:@"http://%@/channels/%d?user_id=%d&inline_videos=5", NM_BASE_URL, NM_USER_ACCOUNT_ID];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	return request;
}

- (void)processDownloadedDataInBuffer {
	if ( [buffer length] == 0 ) return;
	
	NSDictionary * chnDict = [buffer objectFromJSONData];
	
	// extract description attribute from channel
	channelDescription = [chnDict objectForKey:@"description"];
	if ( [channelDescription length] ) {
		[channelDescription retain];
	} else {
		channelDescription = nil;
	}
	// get all video thumbnails
	NSArray * theVideos = [chnDict objectForKey:@"videos"];
	NSString * theKey;
	NSDictionary * vdoDict;
	videoThumbnailURIs = [[NSMutableArray alloc] initWithCapacity:5];
	for (NSDictionary * rootVdoDict in theVideos) {
		for (theKey in rootVdoDict) {	// root attribute cleanser
			vdoDict = [rootVdoDict objectForKey:theKey];
			// get the thumbnail
			[videoThumbnailURIs addObject:[vdoDict objectForKey:@"thumbnail_uri"]];
		}
	}
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	// create the channel
	// create the Preview MO
}

- (NSString *)willLoadNotificationName {
	return NMWillGetChannelDetailNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidGetChannelDetailNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailGetChannelDetailNotification;
}

- (NSDictionary *)userInfo {
	return [NSDictionary dictionaryWithObject:channel forKey:@"channel"];
}

@end
