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
#import "NMVideoDetail.h"
#import "NMDataController.h"
#import "NMTaskQueueController.h"

NSString * const NMWillGetChannelVideListNotification = @"NMWillGetChannelVideListNotification";
NSString * const NMDidGetChannelVideoListNotification = @"NMDidGetChannelVideoListNotification";
NSString * const NMDidFailGetChannelVideoListNotification = @"NMDidFailGetChannelVideoListNotification";

NSPredicate * outdatedVideoPredicateTempate_ = nil;

@implementation NMGetChannelVideoListTask
@synthesize channel;
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
	[mdict setObject:[dict objectForKey:@"title"] forKey:@"title"];
	[mdict setObject:[dict objectForKey:@"duration"] forKey:@"duration"];
	[mdict setObject:[dict objectForKey:@"nm_id"] forKey:@"id"];
	[mdict setObject:[dict objectForKey:@"source"] forKey:@"source"];
	[mdict setObject:[dict objectForKey:@"external_id"] forKey:@"external_id"];
	[mdict setObject:[dict objectForKey:@"reason_included"] forKey:@"reason_included"];
	[mdict setObject:[dict objectForKey:@"thumbnail_uri"] forKey:@"thumbnail_uri"];
	[mdict setObject:[NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"published_at"] floatValue]] forKey:@"published_at"];
	return mdict;
}

+ (NSMutableDictionary *)normalizeDetailDictionary:(NSDictionary *)dict {
	NSMutableDictionary * mdict = [NSMutableDictionary dictionaryWithCapacity:4];
	[mdict setObject:[dict valueForKeyPath:@"author.username"] forKey:@"author_username"];
	[mdict setObject:[dict valueForKeyPath:@"author.profile_uri"] forKey:@"author_profile_uri"];
	[mdict setObject:[dict objectForKey:@"description"] forKey:@"nm_description"];
	return mdict;
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
	// add all video from server for now
	NSDictionary * dict;
	NMVideo * vidObj;
	NMVideoDetail * dtlObj;
	NSUInteger idx = [channel.videos count];
	NSUInteger vidCount = 0;
	// insert video but do not insert duplicate item
	if ( idx ) {
		NSMutableIndexSet * idIndexSet = [NSMutableIndexSet indexSet];
		for (vidObj in channel.videos) {
			[idIndexSet addIndex:[vidObj.nm_id unsignedIntegerValue]];
		}
		numberOfVideoAdded = 0;
		for (dict in parsedObjects) {
			if ( ![idIndexSet containsIndex:[[dict objectForKey:@"nm_id"] unsignedIntegerValue]] ) {
				numberOfVideoAdded++;
				vidObj = [ctrl insertNewVideo];
				[vidObj setValuesForKeysWithDictionary:dict];
				vidObj.channel = channel;
				[channel addVideosObject:vidObj];
				dtlObj = [ctrl insertNewVideoDetail];
				dict = [parsedDetailObjects objectAtIndex:vidCount];
				[dtlObj setValuesForKeysWithDictionary:dict];
				dtlObj.video = vidObj;
				vidObj.detail = dtlObj;
			}
			vidCount++;
		}
	} else {
		for (dict in parsedObjects) {
			vidObj = [ctrl insertNewVideo];
			[vidObj setValuesForKeysWithDictionary:dict];
			vidObj.channel = channel;
			[channel addVideosObject:vidObj];
			dtlObj = [ctrl insertNewVideoDetail];
			dict = [parsedDetailObjects objectAtIndex:vidCount];
			[dtlObj setValuesForKeysWithDictionary:dict];
			dtlObj.video = vidObj;
			vidObj.detail = dtlObj;
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
