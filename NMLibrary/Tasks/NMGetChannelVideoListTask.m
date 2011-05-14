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
#import "NMTaskQueueController.h"

NSString * const NMWillGetChannelVideListNotification = @"NMWillGetChannelVideListNotification";
NSString * const NMDidGetChannelVideoListNotification = @"NMDidGetChannelVideoListNotification";
NSString * const NMDidFailGetChannelVideoListNotification = @"NMDidFailGetChannelVideoListNotification";

NSPredicate * outdatedVideoPredicateTempate_ = nil;

@implementation NMGetChannelVideoListTask
@synthesize channel, channelName;
@synthesize newChannel, urlString;
@synthesize numberOfVideoRequested;
@synthesize delegate;

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
	[mdict setObject:[dict objectForKey:@"thumbnail"] forKey:@"thumbnail"];
	[mdict setObject:[NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"created_at"] floatValue]] forKey:@"created_at"];
	return mdict;
}

- (id)initWithChannel:(NMChannel *)aChn {
	self = [super init];
	command = NMCommandGetChannelVideoList;
	self.channel = aChn;
	self.channelName = aChn.channel_name;
	self.urlString = aChn.channel_url;
	numberOfVideoRequested = 5;
	return self;
}

- (void)dealloc {
	[channel release];
	[channelName release];
	[urlString release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSString * urlStr = [NSString stringWithFormat:@"%@/videos?target=mobile&limit=%d", urlString, numberOfVideoRequested];

#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"Get Channel Video List: %@", urlStr);
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
	NSDate * timestamp = [NSDate date];
	NSInteger idx = 0;
	for (NSDictionary * dict in chVideos) {
		mdict = [NMGetChannelVideoListTask normalizeVideoDictionary:dict];
		[mdict setObject:timestamp forKey:@"nm_fetch_timestamp"];
		[mdict setObject:[NSNumber numberWithInteger:idx++] forKey:@"nm_sort_order"];
		[parsedObjects addObject:mdict];
	}
	
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	// add all video from server for now
	NSDictionary * dict;
	NMVideo * vidObj;
	NSUInteger idx = [channel.videos count];
	// insert video but do not insert duplicate item
	if ( idx ) {
		NSMutableIndexSet * idIndexSet = [NSMutableIndexSet indexSet];
		for (vidObj in channel.videos) {
			[idIndexSet addIndex:[vidObj.vid unsignedIntegerValue]];
		}
		numberOfVideoAdded = 0;
		for (dict in parsedObjects) {
			if ( ![idIndexSet containsIndex:[[dict objectForKey:@"vid"] unsignedIntegerValue]] ) {
				numberOfVideoAdded++;
				vidObj = [ctrl insertNewVideo];
				[vidObj setValuesForKeysWithDictionary:dict];
				vidObj.channel = channel;
				[channel addVideosObject:vidObj];
			}
		}
	} else {
		for (dict in parsedObjects) {
			vidObj = [ctrl insertNewVideo];
			[vidObj setValuesForKeysWithDictionary:dict];
			vidObj.channel = channel;
			[channel addVideosObject:vidObj];
		}
	}
}

- (NSString *)willLoadNotificationName {
	return NMWillGetChannelVideListNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidGetChannelVideoListNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailGetChannelVideoListNotification;
}

- (NSDictionary *)userInfo {
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:numberOfVideoAdded], @"num_video_added", [NSNumber numberWithUnsignedInteger:numberOfVideoRequested], @"num_video_requested", nil];
}

@end
