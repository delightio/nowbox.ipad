//
//  NMGetChannelsTask.m
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMGetChannelsTask.h"
#import "NMGetChannelVideoListTask.h"
#import "NMChannel.h"
#import "NMVideo.h"
#import "NMDataController.h"
#import "NMTaskQueueController.h"


NSString * const NMWillGetChannelsNotification = @"NMWillGetChannelsNotification";
NSString * const NMDidGetChannelsNotification = @"NMDidGetChannelsNotification";
NSString * const NMDidFailGetChannelNotification = @"NMDidFailGetChannelNotification";

@implementation NMGetChannelsTask

@synthesize liveChannel;

- (id)init {
	self = [super init];
	command = NMCommandGetAllChannels;
	channelJSONKeys = [[NSArray alloc] initWithObjects:@"channel_name", @"count", @"reason", @"thumbnail", @"channel_type", @"channel_url", @"title", nil];
	return self;
}

- (id)initGetFriendChannels {
	self = [self init];
	command = NMCommandGetFriendChannels;
	return self;
}

- (id)initGetTopicChannels {
	self = [self init];
	command = NMCommandGetTopicChannels;
	return self;
}

- (id)initGetTrendingChannels {
	self = [self init];
	command = NMCommandGetTrendingChannels;
	return self;
}

- (void)dealloc {
	[channelJSONKeys release];
	[liveChannel release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSString * urlStr;
	switch (command) {
		case NMCommandGetFriendChannels:
			urlStr = @"http://nowmov.com/channel/listings/friends?as_user_screenname=dapunster&target=mobile";
			break;
		case NMCommandGetTopicChannels:
			urlStr = @"http://nowmov.com/channel/listings/topics?as_user_screenname=dapunster&target=mobile";
			break;
		case NMCommandGetTrendingChannels:
			urlStr = @"http://nowmov.com/channel/listings/trending?as_user_screenname=dapunster&target=mobile";
			break;
			
		default:
			urlStr = @"http://nowmov.com/channel/listings/all?as_user_screenname=dapunster&target=mobile";
			break;
	}

	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	return request;
}

- (void)processDownloadedDataInBuffer {
	// parse JSON
	if ( [buffer length] == 0 ) {
		return;
	}
	NSString * str = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
	NSArray * theChs = [str objectFromJSONString];
	[str release];
	
	parsedObjects = [[NSMutableArray alloc] init];
	NSDictionary * cDict, * fvDict;
	NSMutableDictionary * pDict;
	NSString * theKey;
	for (cDict in theChs) {
		if ( [cDict objectForKey:@"first_video"] == nil ) continue;
		pDict = [NSMutableDictionary dictionary];
		for (theKey in channelJSONKeys) {
			[pDict setObject:[cDict objectForKey:theKey] forKey:theKey];
		}
		[pDict setObject:[cDict objectForKey:@"description"] forKey:@"nm_description"];
		
		fvDict = [cDict objectForKey:@"first_video"];
		if ( fvDict ) {
			NSMutableDictionary * theVidDict = [NMGetChannelVideoListTask normalizeVideoDictionary:fvDict];
			[pDict setObject:theVidDict forKey:@"first_video"];
//			[fvDict setObject:[NSNumber numberWithUnsignedInteger:0] forKey:@"nm_sort_order"];
			[theVidDict setObject:[NSDate date] forKey:@"nm_fetch_timestamp"];
		}
		[parsedObjects addObject:pDict];
	}
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	// save the data into core data
	NSMutableArray * ay = [NSMutableArray array];
	NSMutableDictionary * dict;
	// prepare channel names for batch fetch request
	for (dict in parsedObjects) {
		[ay addObject:[dict objectForKey:@"channel_name"]];
	}
	NSDictionary * fetchedChannels = [ctrl fetchChannelsForNames:ay];
	// save channel with new data
	NMChannel * chnObj;
	NMVideo * vidObj;
	NSDictionary * vidDict;
	NSMutableSet * foundSet = [NSMutableSet set];
//	NMTaskQueueController * queueCtrl = [NMTaskQueueController sharedTaskQueueController];
	NSInteger idx = 0;
	for (dict in parsedObjects) {
		chnObj = (NMChannel *)[fetchedChannels objectForKey:[dict objectForKey:@"channel_name"]];
		if ( chnObj ) {
			[foundSet addObject:chnObj.channel_name];
			// check if the channel is playing
			// remove all existing videos
			//[ctrl deleteVideoInChannel:chnObj];
		} else {
			// create a new channel object
			chnObj = [ctrl insertNewChannel];
		}
		chnObj.nm_sort_order = [NSNumber numberWithInteger:idx];
		vidDict = [[dict objectForKey:@"first_video"] retain];
		[dict removeObjectForKey:@"first_video"];
		// set channel value
		[chnObj setValuesForKeysWithDictionary:dict];
		// insert the video
		vidObj = [ctrl insertNewVideo];
		[vidObj setValuesForKeysWithDictionary:vidDict];
		[chnObj addVideosObject:vidObj];
		vidObj.channel = chnObj;
		[vidDict release];
		// this will insert the first 
		if ( [chnObj.channel_name isEqualToString:@"live"] ) {
			self.liveChannel = chnObj;
		}
		idx++;
	}
	// remove channel no longer here
	NSArray * allKeys = [fetchedChannels allKeys];
	NSArray * untouchedKeys = [allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"!SELF IN %@", foundSet]];
	if ( [untouchedKeys count] ) {
		[ctrl deleteManagedObjects:untouchedKeys];
	}
}

- (NSString *)willLoadNotificationName {
	return NMWillGetChannelsNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidGetChannelsNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailGetChannelNotification;
}

- (NSDictionary *)userInfo {
	if ( liveChannel ) {
		return [NSDictionary dictionaryWithObjectsAndKeys:liveChannel, @"live_channel", [NSNumber numberWithInteger:command], @"channel_type", nil];
	} else {
		return [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:command] forKey:@"channel_type"];
	}
	return nil;
}

@end
