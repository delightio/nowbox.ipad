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

- (id)initWithChannel:(NMChannel *)aChn {
	self = [super init];
	command = NMCommandGetChannelVideoList;
	self.channel = aChn;
	self.channelName = aChn.channel_name;
	return self;
}

- (NSMutableURLRequest *)URLRequest {
#ifdef NOWMOV_USE_BETA_SITE
	NSString * urlStr = [NSString stringWithFormat:@"http://beta.nowmov.com/%@/videos?target=mobile", channelName];
#else
	NSString * urlStr = [NSString stringWithFormat:@"http://nowmov.com/%@/videos?target=mobile", channelName];
#endif
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	
	return request;
}

- (void)processDownloadedDataInBuffer {
	// parse JSON
	if ( [buffer length] == 0 ) return;
	parsedObjects = [[buffer objectFromJSONData] retain];
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	if ( newChannel ) {
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
		for (vidObj in channel.videos) {
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
