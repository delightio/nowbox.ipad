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
		outdatedVideoPredicateTempate_ = [[NSPredicate predicateWithFormat:@"!vid IN $NM_VIDEO_ID_LIST"] retain];
	}
	return outdatedVideoPredicateTempate_;
}

+ (NSMutableDictionary *)normalizeVideoDictionary:(NSDictionary *)dict {
	NSMutableDictionary * mdict = [NSMutableDictionary dictionaryWithCapacity:10];
	[mdict setObject:[dict objectForKey:@"author_username"] forKey:@"author_username"];
	[mdict setObject:[dict objectForKey:@"author_profile_link"] forKey:@"author_profile_link"];
	[mdict setObject:[dict objectForKey:@"description"] forKey:@"nm_description"];
	[mdict setObject:[dict objectForKey:@"title"] forKey:@"title"];
	[mdict setObject:[dict objectForKey:@"vid"] forKey:@"vid"];
	[mdict setObject:[dict objectForKey:@"service_name"] forKey:@"service_name"];
	[mdict setObject:[dict objectForKey:@"service_external_id"] forKey:@"service_external_id"];
	[mdict setObject:[dict objectForKey:@"total_mentions"] forKey:@"total_mentions"];
	[mdict setObject:[dict objectForKey:@"reason_included"] forKey:@"reason_included"];
	[mdict setObject:[NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"created_at"] floatValue]] forKey:@"created_at"];
	return mdict;
}

- (id)initWithChannel:(NMChannel *)aChn {
	self = [super init];
	command = NMCommandGetChannelVideoList;
	self.channel = aChn;
	self.channelName = aChn.channel_name;
	return self;
}

- (void)dealloc {
	[channel release];
	[channelName release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
#ifdef NOWMOV_USE_BETA_SITE
	NSString * urlStr = [NSString stringWithFormat:@"http://beta.nowmov.com/live/videos?target=mobile", channelName];
#else
	NSString * urlStr = [NSString stringWithFormat:@"http://nowmov.com/%@/videos?target=mobile", channelName];
#endif
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	
	return request;
}

- (void)processDownloadedDataInBuffer {
	// parse JSON
	if ( [buffer length] == 0 ) return;
	NSArray * chVideos = [buffer objectFromJSONData];
	parsedObjects = [[NSMutableArray alloc] initWithCapacity:[chVideos count]];
	NSMutableDictionary * mdict;
	for (NSDictionary * dict in chVideos) {
		mdict = [NMGetChannelVideoListTask normalizeVideoDictionary:dict];
		[parsedObjects addObject:mdict];
	}
	
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
//	if ( newChannel ) {
		// update existing video
		// remove ALL old videos not in the list
		
		// prepare the array of ID
		NSMutableArray * ay = [NSMutableArray array];
		NSDictionary * dict;
		for (dict in parsedObjects) {
			[ay addObject:[dict objectForKey:@"vid"]];
		}
		
		// delete outdated video
		NSSet * outdatedVidSet = [channel.videos filteredSetUsingPredicate:[[NMGetChannelVideoListTask outdatedVideoPredicateTempate] predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:ay forKey:@"NM_VIDEO_ID_LIST"]]];
		[ctrl deleteManagedObjects:outdatedVidSet];
		
		// get the array of remaining videos ID
		NMVideo * vidObj;
		NSMutableDictionary * overlappingVidIDDict = [NSMutableDictionary dictionary];
		for (vidObj in ctrl.sortedVideoList) {
			[overlappingVidIDDict setObject:vidObj forKey:vidObj.vid];
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
			vidObj.channel = channel;
			[channel addVideosObject:vidObj];
			idx++;
		}
	ctrl.sortedVideoList = nil;
		
//	} else {
		// this is an existing channel. We should append new videos and update the order. No need to remove old videos
//	}
}

- (NSString *)willLoadNotificationName {
	return NMWillGetChannelVideListNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidGetChannelVideoListNotification;
}

@end
