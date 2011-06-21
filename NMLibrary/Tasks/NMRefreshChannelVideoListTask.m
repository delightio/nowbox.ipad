//
//  NMGetChannelVideosTask.m
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMRefreshChannelVideoListTask.h"
#import "NMChannel.h"
#import "NMVideo.h"
#import "NMDataController.h"
#import "NMTaskQueueController.h"
#import "NMDataController.h"

NSString * const NMWillRefreshChannelVideListNotification = @"NMWillRefreshChannelVideListNotification";
NSString * const NMDidRefreshChannelVideoListNotification = @"NMDidRefreshChannelVideoListNotification";
NSString * const NMDidFailRefreshChannelVideoListNotification = @"NMDidFailRefreshChannelVideoListNotification";

NSPredicate * refreshOutdatedVideoPredicateTempate_ = nil;

@implementation NMRefreshChannelVideoListTask
@synthesize channel;
@synthesize newChannel, urlString;
@synthesize numberOfVideoRequested;
@synthesize delegate;

+ (NSPredicate *)outdatedVideoPredicateTempate {
	if ( refreshOutdatedVideoPredicateTempate_ == nil ) {
		refreshOutdatedVideoPredicateTempate_ = [[NSPredicate predicateWithFormat:@"!vid IN $NM_VIDEO_ID_LIST"] retain];
	}
	return refreshOutdatedVideoPredicateTempate_;
}

+ (NSMutableDictionary *)normalizeVideoDictionary:(NSDictionary *)dict {
	NSMutableDictionary * mdict = [NSMutableDictionary dictionaryWithCapacity:10];
	[mdict setObject:[dict objectForKey:@"author_username"] forKey:@"author_username"];
	[mdict setObject:[dict objectForKey:@"author_profile_link"] forKey:@"author_profile_link"];
	[mdict setObject:[dict objectForKey:@"description"] forKey:@"nm_description"];
	[mdict setObject:[dict objectForKey:@"title"] forKey:@"title"];
	[mdict setObject:[dict objectForKey:@"duration"] forKey:@"duration"];
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
	[urlString release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSString * urlStr = [NSString stringWithFormat:@"%@/videos?target=mobile&limit=%d", urlString, numberOfVideoRequested];
//	NSString * urlStr = @"http://boogie.local/pipely/test_videos.json";

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
		mdict = [NMRefreshChannelVideoListTask normalizeVideoDictionary:dict];
		[mdict setObject:timestamp forKey:@"nm_fetch_timestamp"];
		[mdict setObject:[NSNumber numberWithInteger:idx++] forKey:@"nm_sort_order"];
		[parsedObjects addObject:mdict];
	}
	
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	BOOL pbSafe = [delegate task:self shouldBeginPlaybackSafeUpdateForChannel:channel];
	NSDictionary * dict;
	NMVideo * vidObj;
	numberOfVideoAdded = 0;
	if ( pbSafe ) {
		NSLog(@"Begin safe update");
		// user is currently viewing this channel
		[delegate taskBeginPlaybackSafeUpdate:self];
		// currently playing video in the channel
		NMVideo * curVideo = [delegate currentVideoForTask:self];
		[ctrl deleteVideoInChannel:channel afterVideo:curVideo];
		// insert new item
		for (dict in parsedObjects) {
			if ( [curVideo.vid isEqualToNumber:[dict objectForKey:@"vid"]] ) continue;
			NSLog(@"add video - %@", [dict objectForKey:@"title"]);
			vidObj = [ctrl insertNewVideo];
			[vidObj setValuesForKeysWithDictionary:dict];
			vidObj.channel = channel;
			[channel addVideosObject:vidObj];
			numberOfVideoAdded++;
		}
		[delegate taskBeginPlaybackSafeUpdate:self];
		NSLog(@"end safe update");
	} else {
		// the user is not playing the video in the channel requesting for new video list
		// just delete everything in that channel and show the new list of video
		[ctrl deleteManagedObjects:channel.videos];
		for (dict in parsedObjects) {
			vidObj = [ctrl insertNewVideo];
			[vidObj setValuesForKeysWithDictionary:dict];
			vidObj.channel = channel;
			[channel addVideosObject:vidObj];
		}
		numberOfVideoAdded = [parsedObjects count];
	}
}

- (NSString *)willLoadNotificationName {
	return NMWillRefreshChannelVideListNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidRefreshChannelVideoListNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailRefreshChannelVideoListNotification;
}

- (NSDictionary *)userInfo {
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:numberOfVideoAdded], @"num_video_added", [NSNumber numberWithUnsignedInteger:numberOfVideoRequested], @"num_video_requested", nil];
}

@end
