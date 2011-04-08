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

@implementation NMGetChannelsTask

@synthesize liveChannel;

- (id)init {
	self = [super init];
	command = NMCommandGetChannels;
	channelJSONKeys = [[NSArray alloc] initWithObjects:@"channel_name", @"count", @"reason", @"thumbnail", @"channel_type", @"channel_url", @"title", nil];
	return self;
}

- (void)dealloc {
	[liveChannel release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
#ifdef NOWMOV_USE_BETA_SITE
	NSString * urlStr = @"http://beta.nowmov.com/channel/listings/recommended";
#else
	NSString * urlStr = @"http://nowmov.com/channel/listings/?as_user_screenname=dapunster&target=mobile";
#endif
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	
	return request;
}

- (void)processDownloadedDataInBuffer {
	// parse JSON
	if ( [buffer length] == 0 ) return;
	NSString * str = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
	NSArray * theChs = [str objectFromJSONString];
	[str release];
	
	parsedObjects = [[NSMutableArray alloc] init];
	NSDictionary * cDict, * fvDict;
	NSMutableDictionary * pDict;
	NSString * theKey;
	for (cDict in theChs) {
		pDict = [NSMutableDictionary dictionary];
		for (theKey in channelJSONKeys) {
			[pDict setObject:[cDict objectForKey:theKey] forKey:theKey];
		}
		[pDict setObject:[cDict objectForKey:@"description"] forKey:@"nm_description"];
		
		fvDict = [cDict objectForKey:@"first_video"];
		if ( fvDict ) {
			[pDict setObject:[NMGetChannelVideoListTask normalizeVideoDictionary:fvDict] forKey:@"first_video"];
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
	NSMutableArray * foundAy = [NSMutableArray array];
//	NMTaskQueueController * queueCtrl = [NMTaskQueueController sharedTaskQueueController];
	for (dict in parsedObjects) {
		chnObj = (NMChannel *)[fetchedChannels objectForKey:[dict objectForKey:@"channel_name"]];
		if ( chnObj ) {
			[foundAy addObject:chnObj.channel_name];
			// remove all existing videos
			[ctrl deleteAllVideos];
		} else {
			// create a new channel object
			chnObj = [ctrl insertNewChannel];
		}
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
	}
	// remove channel no longer here
	NSArray * allKeys = [fetchedChannels allKeys];
	NSArray * untouchedKeys = [allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"!SELF IN %@", foundAy]];
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

- (NSDictionary *)userInfo {
	if ( liveChannel ) {
		return [NSDictionary dictionaryWithObject:liveChannel forKey:@"live_channel"];
	}
	return nil;
}

@end
