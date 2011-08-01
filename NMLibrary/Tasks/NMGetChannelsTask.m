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

@synthesize trendingChannel;

- (id)init {
	self = [super init];
	command = NMCommandGetAllChannels;
	channelJSONKeys = [[NSArray alloc] initWithObjects:@"title", @"type", @"resource_uri", @"category", nil];
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

- (id)initGetDefaultChannels {
	self = [self init];
	command = NMCommandGetDefaultChannels;
	return self;
}

- (void)dealloc {
	[channelJSONKeys release];
	[trendingChannel release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSString * urlStr;
	NSTimeInterval t = NM_URL_REQUEST_TIMEOUT;
	switch (command) {
		case NMCommandGetDefaultChannels:
			urlStr = [NSString stringWithFormat:@"http://%@/channels?user_id=%d", NM_BASE_URL, NM_USER_ACCOUNT_ID];
			break;
		default:
			break;
	}

	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:t];
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
	NSDictionary * cDict, * chnCtnDict;
	NSMutableDictionary * pDict;
	NSString * theKey;
	NSString * thumbURL;
	for (cDict in theChs) {
		for (NSString * rKey in cDict) {
			chnCtnDict = [cDict objectForKey:rKey];
			pDict = [NSMutableDictionary dictionary];
			for (theKey in channelJSONKeys) {
				[pDict setObject:[chnCtnDict objectForKey:theKey] forKey:theKey];
			}
			thumbURL = [chnCtnDict objectForKey:@"thumbnail_uri"];
			if ( thumbURL == nil || [thumbURL isEqualToString:@""] ) {
				[pDict setObject:[NSNull null] forKey:@"thumbnail_uri"];
			} else {
				[pDict setObject:thumbURL forKey:@"thumbnail_uri"];
			}
			[pDict setObject:[chnCtnDict objectForKey:@"id"] forKey:@"nm_id"];
			
			[parsedObjects addObject:pDict];
		}
	}
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	// save the data into core data
	NSMutableArray * ay = [NSMutableArray array];
	NSMutableDictionary * dict;
	// prepare channel names for batch fetch request
	for (dict in parsedObjects) {
		[ay addObject:[dict objectForKey:@"title"]];
	}
	NSDictionary * fetchedChannels = [ctrl fetchChannelsForNames:ay];
	// save channel with new data
	NMChannel * chnObj;
	NSMutableSet * foundSet = [NSMutableSet set];
//	NMTaskQueueController * queueCtrl = [NMTaskQueueController sharedTaskQueueController];
	NSInteger idx = 0;
	for (dict in parsedObjects) {
		chnObj = (NMChannel *)[fetchedChannels objectForKey:[dict objectForKey:@"title"]];
		if ( chnObj ) {
			[foundSet addObject:chnObj.title];
			// check if the channel is playing
			// remove all existing videos
			//[ctrl deleteVideoInChannel:chnObj];
		} else {
			// create a new channel object
			chnObj = [ctrl insertNewChannel];
		}
		chnObj.nm_sort_order = [NSNumber numberWithInteger:idx];
		// set channel value
		[chnObj setValuesForKeysWithDictionary:dict];
		// this will insert the first 
		if ( [chnObj.title isEqualToString:@"live"] ) {
			self.trendingChannel = chnObj;
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
	if ( trendingChannel ) {
		return [NSDictionary dictionaryWithObjectsAndKeys:trendingChannel, @"live_channel", [NSNumber numberWithInteger:command], @"type", nil];
	} else {
		return [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:command] forKey:@"type"];
	}
	return nil;
}

@end
