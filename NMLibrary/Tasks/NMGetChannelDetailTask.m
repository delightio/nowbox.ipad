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
#import "NMDataController.h"

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
	[previewArray release];
	[channelDescription release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSString * urlStr = [NSString stringWithFormat:@"http://%@/channels/%@?user_id=%d&inline_videos=5", NM_BASE_URL, targetID, NM_USER_ACCOUNT_ID];
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"Get Channel Detail: %@", urlStr);
#endif
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
	NSInteger i = 0;
	previewArray = [[NSMutableArray alloc] initWithCapacity:5];
	for (NSDictionary * rootVdoDict in theVideos) {
		for (theKey in rootVdoDict) {	// root attribute cleanser
			vdoDict = [rootVdoDict objectForKey:theKey];
			// get the thumbnail
			[previewArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
									 [vdoDict objectForKey:@"thumbnail_uri"], @"thumbnail_uri", 
									 [vdoDict objectForKey:@"external_id"], @"external_id", 
									 [NSNumber numberWithInteger:i++], @"nm_sort_order", 
									 [vdoDict objectForKey:@"id"], @"nm_id", 
									 [vdoDict objectForKey:@"title"], @"title",
									 [vdoDict objectForKey:@"duration"], @"duration",
									 [vdoDict objectForKey:@"view_count"], @"view_count",
									 [NSDate dateWithTimeIntervalSince1970:[[vdoDict objectForKey:@"published_at"] floatValue]], @"published_at",
									 nil]];
		}
	}
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	// create the Channel Detail MO
	if ( channel.detail == nil ) {
		channel.detail = [ctrl insertNewChannelDetail];
	}
	channel.detail.nm_description = channelDescription;
	if ( channel.previewThumbnails ) {
		[ctrl deleteManagedObjects:channel.previewThumbnails];
	}
	// create the Preview MO
	NMPreviewThumbnail * thumbObj;
	for (NSDictionary * theDict in previewArray) {
		thumbObj = [ctrl insertNewPreviewThumbnail];
		[thumbObj setValuesForKeysWithDictionary:theDict];
		thumbObj.channel = channel;
	}
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
