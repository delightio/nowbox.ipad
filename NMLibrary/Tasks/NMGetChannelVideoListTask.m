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

NSPredicate * outdatedVideoPredicateTempate_ = nil;

@implementation NMGetChannelVideoListTask
@synthesize channel, channelName, newChannel;

+ (NSPredicate *)outdatedVideoPredicateTempate {
	if ( outdatedVideoPredicateTempate_ == nil ) {
		outdatedVideoPredicateTempate_ = [[NSPredicate predicateWithFormat:@"!nm_id IN $NM_VIDEO_ID_LIST"] retain];
	}
	return outdatedVideoPredicateTempate_;
}

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
	[str release];
	
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
		// date
		//TODO: make sure timezone is set correctly. timestamp from server is pacific time
		[pDict setObject:[NSDate dateWithTimeIntervalSince1970:[[cDict objectForKey:@"created_at"] floatValue]] forKey:@"created_at"];
		//TODO: remove once JSON format bug is fixed
		[pDict setObject:[NSNumber numberWithInteger:[[cDict objectForKey:@"total_mentions"] integerValue]] forKey:@"total_mentions"];
		[parsedObjects addObject:pDict];
	}
	
	return parsedObjects;
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	if ( newChannel ) {
		// update existing video
		// remove ALL old videos not in the list
		
		// prepare the array of ID
		NSMutableArray * ay = [NSMutableArray array];
		NSDictionary * dict;
		for (dict in parsedObjects) {
			[ay addObject:[dict objectForKey:@"nm_id"]];
		}
		
		// delete outdated video
		NSSet * outdatedVidSet = [channel.videos filteredSetUsingPredicate:[[NMGetChannelVideoListTask outdatedVideoPredicateTempate] predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:ay forKey:@"NM_VIDEO_ID_LIST"]]];
		[ctrl deleteManagedObjects:outdatedVidSet];
		
		// get the array of remaining videos ID
		NMVideo * vidObj;
		NSMutableDictionary * overlappingVidIDDict = [NSMutableDictionary dictionary];
		for (vidObj in channel.videos) {
			[overlappingVidIDDict setObject:vidObj forKey:vidObj.nm_id];
		}
		
		NSNumber * vidID;
		NSUInteger idx = 0;
		for (vidID in ay) {
			vidObj = [overlappingVidIDDict objectForKey:vidID];
			if ( vidObj == nil ) {
				// create a new video
				vidObj = [ctrl insertNewVideo];
			}
			[vidObj setValuesForKeysWithDictionary:[parsedObjects objectAtIndex:idx]];
			vidObj.nm_sort_order = [NSNumber numberWithInteger:idx];
			// associate data objects
			[vidObj addChannelsObject:channel];
			[channel addVideosObject:vidObj];
			idx++;
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
