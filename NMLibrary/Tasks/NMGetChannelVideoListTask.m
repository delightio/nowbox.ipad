//
//  NMGetChannelVideosTask.m
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMGetChannelVideoListTask.h"
#import "NMChannel.h"
#import "NMVideo.h"
#import "NMDataController.h"

NSString * const NMWillGetChannelVideListNotification = @"NMWillGetChannelVideListNotification";
NSString * const NMDidGetChannelVideoListNotification = @"NMDidGetChannelVideoListNotification";

NSPredicate * existingVideoPredicateTempate = nil;

@implementation NMGetChannelVideoListTask
@synthesize channel, channelName, newChannel;

+ (NSPredicate *)

- (id)initWithChannel:(NMChannel *)aChn {
	self = [super init];
	command = NMCommandGetChannelVideoList;
	self.channel = aChn;
	self.channelName = aChn.channel_name;
	return self;
}

- (NSMutableURLRequest *)URLRequest {
	NSString * urlStr = [NSString stringWithFormat:@"http://nowmov.com/%@/videos", channelName];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	
	return request;
}

- (id)processDownloadedDataInBuffer {
	// parse JSON
	if ( [buffer length] == 0 ) return nil;
	NSString * str = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
	NSDictionary * dict = [str objectFromJSONString];
	
	if ( [self checkDictionaryContainsError:dict] ) {
		return parsedObjects;
	}
	
	NSArray * theVideos = [dict objectForKey:@"video_list"];
	parsedObjects = [[NSMutableArray alloc] init];
	NSDictionary * cDict;
	NSMutableDictionary * pDict;
	for (cDict in theVideos) {
		pDict = [NSMutableDictionary dictionaryWithDictionary:cDict];
		// normalized the key
		[pDict setObject:[cDict objectForKey:@"description"] forKey:@"nm_description"];
		[pDict removeObjectForKey:@"description"];
		[pDict setObject:[cDict objectForKey:@"id"] forKey:@"nm_id"];
		[pDict removeObjectForKey:@"id"];
		[parsedObjects addObject:pDict];
	}
	
	return parsedObjects;
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	if ( newChannel ) {
		// update existing video
		// remove ALL old videos not in the list
		// save the data into core data
		NSMutableArray * ay = [NSMutableArray array];
		NSDictionary * dict;
		// prepare channel names for batch fetch request
		for (dict in parsedObjects) {
			[ay addObject:[dict objectForKey:@"nm_id"]];
		}
		NSSet * vidSet = channel.videos;
		[vidSet filteredSetUsingPredicate:];
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
				[queueCtrl issueGetVideoListForChannel:chnObj isNew:YES];
			}
		}
		// remove channel no longer here
		NSArray * allKeys = [fetchedChannels allKeys];
		NSArray * untouchedKeys = [allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"!SELF IN %@", foundAy]];
		if ( [untouchedKeys count] ) {
			[ctrl deleteManagedObjects:untouchedKeys];
		}
	} else {
		// this is an existing channel. We should append new videos and update the order. No need to remove old videos
	}
}

- (NSString *)willLoadNotificationName {
	return NMWillGetChannelVideListNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidGetChannelVideoListNotification;
}

@end
