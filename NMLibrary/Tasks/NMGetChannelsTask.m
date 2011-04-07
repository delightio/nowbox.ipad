//
//  NMGetChannelsTask.m
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMGetChannelsTask.h"
#import "NMChannel.h"
#import "NMDataController.h"
#import "NMTaskQueueController.h"


NSString * const NMWillGetChannelsNotification = @"NMWillGetChannelsNotification";
NSString * const NMDidGetChannelsNotification = @"NMDidGetChannelsNotification";

@implementation NMGetChannelsTask

- (id)init {
	self = [super init];
	command = NMCommandGetChannels;
	channelJSONKeys = [[NSArray alloc] initWithObjects:@"channel_name", @"count", @"reason", @"thumbnail", nil];
	return self;
}

- (NSMutableURLRequest *)URLRequest {
#ifdef NOWMOV_USE_BETA_SITE
	NSString * urlStr = @"http://beta.nowmov.com/channel/listings/recommended";
#else
	NSString * urlStr = @"http://nowmov.com/channel/listings/recommended";
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
	NSDictionary * cDict;
	NSMutableDictionary * pDict;
	NSString * theKey;
	for (cDict in theChs) {
		pDict = [NSMutableDictionary dictionary];
		for (theKey in channelJSONKeys) {
			[pDict setObject:[cDict objectForKey:theKey] forKey:theKey];
		}
		[pDict setObject:[cDict objectForKey:@"description"] forKey:@"nm_description"];
		[pDict setObject:[cDict objectForKey:@"first_video"] forKey:@"first_video"];
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
	NSDictionary * vidDict;
	NSMutableArray * foundAy = [NSMutableArray array];
//	NMTaskQueueController * queueCtrl = [NMTaskQueueController sharedTaskQueueController];
	for (dict in parsedObjects) {
		chnObj = (NMChannel *)[fetchedChannels objectForKey:[dict objectForKey:@"channel_name"]];
		if ( chnObj ) {
			[foundAy addObject:chnObj.channel_name];
		} else {
			// create a new channel object
			chnObj = [ctrl insertNewChannel];
			vidDict = [[dict objectForKey:@"first_video"] retain];
			[dict removeObjectForKey:@"first_video"];
			
			// set value
			[chnObj setValuesForKeysWithDictionary:dict];
			// insert the video
			[vidDict release];
			// if it's a new channel, we should get the list of video
			//TODO: uncomment this
			//[queueCtrl issueGetVideoListForChannel:chnObj isNew:YES];
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

@end
