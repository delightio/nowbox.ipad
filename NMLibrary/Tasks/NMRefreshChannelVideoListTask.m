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
#import "NMVideoDetail.h"
#import "NMDataController.h"
#import "NMTaskQueueController.h"
#import "NMDataController.h"
#import "NMGetChannelVideoListTask.h"

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

- (id)initWithChannel:(NMChannel *)aChn {
	self = [super init];
	command = NMCommandGetChannelVideoList;
	self.channel = aChn;
	self.channelName = aChn.title;
	self.urlString = aChn.resource_uri;
	numberOfVideoRequested = 5;
	return self;
}

- (void)dealloc {
	[channel release];
	[parsedDetailObjects release];
	[urlString release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSString * urlStr = [NSString stringWithFormat:@"%@/videos?limit=%d&user_id=%d", urlString, numberOfVideoRequested, NM_USER_ACCOUNT_ID];
//	NSString * urlStr = @"http://boogie.local/pipely/test_videos.json";

#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"Get Channel Video List (refresh): %@", urlStr);
#endif
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	
	return request;
}

- (void)processDownloadedDataInBuffer {
	// parse JSON
	if ( [buffer length] == 0 ) return;
	NSArray * chVideos = [buffer objectFromJSONData];
	parsedObjects = [[NSMutableArray alloc] initWithCapacity:[chVideos count]];
	parsedDetailObjects = [[NSMutableArray alloc] initWithCapacity:[chVideos count]];
	NSMutableDictionary * mdict;
	NSDate * timestamp = [NSDate date];
	NSInteger idx = 0;
	NSDictionary * dict;
	for (NSDictionary * parentDict in chVideos) {
		for (NSString * theKey in parentDict) {
			dict = [parentDict objectForKey:theKey];
			mdict = [NMGetChannelVideoListTask normalizeVideoDictionary:dict];
			[mdict setObject:timestamp forKey:@"nm_fetch_timestamp"];
			[mdict setObject:[NSNumber numberWithInteger:idx++] forKey:@"nm_sort_order"];
			[parsedObjects addObject:mdict];
			[parsedDetailObjects addObject:[NMGetChannelVideoListTask normalizeDetailDictionary:dict]];
		}
	}
	
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	BOOL pbSafe = [delegate task:self shouldBeginPlaybackSafeUpdateForChannel:channel];
	NSDictionary * dict;
	NMVideo * vidObj;
	NMVideoDetail * dtlObj;
	numberOfVideoAdded = 0;
	NSUInteger vidCount = 0;
	if ( pbSafe ) {
		// user is currently viewing this channel
		[delegate taskBeginPlaybackSafeUpdate:self];
		// currently playing video in the channel
		NMVideo * curVideo = [delegate currentVideoForTask:self];
		[ctrl deleteVideoInChannel:channel afterVideo:curVideo];
		// insert new item
		for (dict in parsedObjects) {
			if ( [curVideo.nm_id isEqualToNumber:[dict objectForKey:@"nm_id"]] ) {
				vidCount++;
				continue;
			}
			vidObj = [ctrl insertNewVideo];
			[vidObj setValuesForKeysWithDictionary:dict];
			// channel
			vidObj.channel = channel;
			[channel addVideosObject:vidObj];
			// video detail
			dtlObj = [ctrl insertNewVideoDetail];
			dict = [parsedDetailObjects objectAtIndex:vidCount];
			[dtlObj setValuesForKeysWithDictionary:dict];
			dtlObj.video = vidObj;
			vidObj.detail = dtlObj;

			numberOfVideoAdded++;
			vidCount++;
		}
		[delegate taskBeginPlaybackSafeUpdate:self];
	} else {
		// the user is not playing the video in the channel requesting for new video list
		// just delete everything in that channel and show the new list of video
		[ctrl deleteManagedObjects:channel.videos];
		for (dict in parsedObjects) {
			vidObj = [ctrl insertNewVideo];
			[vidObj setValuesForKeysWithDictionary:dict];
			// channel
			vidObj.channel = channel;
			[channel addVideosObject:vidObj];
			// video detail
			dtlObj = [ctrl insertNewVideoDetail];
			dict = [parsedDetailObjects objectAtIndex:vidCount];
			[dtlObj setValuesForKeysWithDictionary:dict];
			dtlObj.video = vidObj;
			vidObj.detail = dtlObj;
			
			vidCount++;
		}
		numberOfVideoAdded = [parsedObjects count];
	}
#ifdef DEBUG_VIDEO_LIST_REFRESH
	NSLog(@"video list added (refresh) - %@ %d", channelName, numberOfVideoAdded);
#endif
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
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:numberOfVideoAdded], @"num_video_added", [NSNumber numberWithUnsignedInteger:numberOfVideoRequested], @"num_video_requested", channel, @"channel", nil];
}

@end
