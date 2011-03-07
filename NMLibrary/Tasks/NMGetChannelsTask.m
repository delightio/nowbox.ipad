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
	return self;
}

- (NSMutableURLRequest *)URLRequest {
	NSString * urlStr = @"http://nowmov.com/channel/listings/recommended";
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	
	return request;
}

- (id)processDownloadedDataInBuffer {
	// parse JSON
	if ( [buffer length] == 0 ) return nil;
	NSString * str = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
	NSDictionary * dict = [str objectFromJSONString];
	[str release];
	
	if ( [self checkDictionaryContainsError:dict] ) {
		return parsedObjects;
	}
	
	NSArray * theChs = [dict objectForKey:@"channel_list"];
	parsedObjects = [[NSMutableArray alloc] init];
	NSDictionary * cDict;
	NSMutableDictionary * pDict;
	for (cDict in theChs) {
		pDict = [NSMutableDictionary dictionaryWithDictionary:cDict];
		[pDict setObject:[cDict objectForKey:@"description"] forKey:@"nm_description"];
		[pDict removeObjectForKey:@"description"];
		[parsedObjects addObject:pDict];
	}
	
	return parsedObjects;
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	// save the data into core data
	NSMutableArray * ay = [NSMutableArray array];
	NSDictionary * dict;
	// prepare channel names for batch fetch request
	for (dict in parsedObjects) {
		[ay addObject:[dict objectForKey:@"channel_name"]];
	}
	NSDictionary * fetchedChannels = [ctrl fetchChannelsForNames:ay];
	// save channel with new data
	NMChannel * chnObj;
	NSMutableArray * foundAy = [NSMutableArray array];
	NMTaskQueueController * queueCtrl = [NMTaskQueueController sharedTaskQueueController];
	for (dict in parsedObjects) {
		chnObj = (NMChannel *)[fetchedChannels objectForKey:[dict objectForKey:@"channel_name"]];
		if ( chnObj ) {
			[foundAy addObject:chnObj.channel_name];
		} else {
			// create a new channel object
			chnObj = [ctrl insertNewChannel];
			// set value
			[chnObj setValuesForKeysWithDictionary:dict];
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
