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

#define NM_NUMBER_OF_VIDEOS_PER_PAGE	5

NSString * const NMWillGetChannelVideoListNotification = @"NMWillGetChannelVideoListNotification";
NSString * const NMDidGetChannelVideoListNotification = @"NMDidGetChannelVideoListNotification";
NSString * const NMDidFailGetChannelVideoListNotification = @"NMDidFailGetChannelVideoListNotification";
NSString * const NMDidCancelGetChannelVideListNotification = @"NMDidCancelGetChannelVideListNotification";

NSString * const NMWillGetNewVideoForChannelNotification = @"NMWillGetNewVideoForChannelNotification";
NSString * const NMDidGetNewVideoForChannelNotification = @"NMDidGetNewVideoForChannelNotification";
NSString * const NMDidFailGetNewVideoForChannelNotification = @"NMDidFailGetNewVideoForChannelNotification";
NSString * const NMDidCancelGetNewVideoForChannelNotification = @"NMDidCancelGetNewVideoForChannelNotification";

NSString * const NMWillGetOlderVideoForChannelNotification = @"NMWillGetOlderVideoForChannelNotification";
NSString * const NMDidGetOlderVideoForChannelNotification = @"NMDidGetOldVideoForChannelNotification";
NSString * const NMDidFailGetOlderVideoForChannelNotification = @"NMDidFailGetOlderVideoForChannelNotification";
NSString * const NMDidCancelGetOlderVideoForChannelNotification = @"NMDidCancelGetOlderVideoForChannelNotification";

NSPredicate * outdatedVideoPredicateTempate_ = nil;

static NSArray * sharedVideoDirectJSONKeys = nil;

@implementation NMGetChannelVideoListTask
@synthesize channel, channelName;
@synthesize newChannel, urlString;
@synthesize currentPage, numberOfVideoAdded;
@synthesize videoID;

+ (NSArray *)directJSONKeys {
	if ( sharedVideoDirectJSONKeys == nil ) {
		sharedVideoDirectJSONKeys = [[NSArray alloc] initWithObjects:@"title", @"duration", @"source", @"external_id", @"view_count", nil];
	}
	
	return sharedVideoDirectJSONKeys;
}

+ (NSPredicate *)outdatedVideoPredicateTempate {
	if ( outdatedVideoPredicateTempate_ == nil ) {
		outdatedVideoPredicateTempate_ = [[NSPredicate predicateWithFormat:@"!vid IN $NM_VIDEO_ID_LIST"] retain];
	}
	return outdatedVideoPredicateTempate_;
}

+ (NSMutableDictionary *)normalizeVideoDictionary:(NSDictionary *)dict {
	NSMutableDictionary * mdict = [NSMutableDictionary dictionaryWithCapacity:10];
	NSArray * allKeys = [NMGetChannelVideoListTask directJSONKeys];
	for (NSString * theKey in allKeys) {
		[mdict setObject:[dict objectForKey:theKey] forKey:theKey];
	}
	[mdict setObject:[dict objectForKey:@"id"] forKey:@"nm_id"];
	[mdict setObject:NM_SESSION_ID forKey:@"nm_session_id"];
	[mdict setObject:[NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"published_at"] floatValue]] forKey:@"published_at"];
	NSString * thumbURL = [dict objectForKey:@"thumbnail_uri"];
	if ( thumbURL == nil || [thumbURL isEqualToString:@""] ) {
		[mdict setObject:[NSNull null] forKey:@"thumbnail_uri"];
	} else {
		[mdict setObject:thumbURL forKey:@"thumbnail_uri"];
	}
	return mdict;
}

+ (NSMutableDictionary *)normalizeDetailDictionary:(NSDictionary *)dict {
	NSMutableDictionary * mdict = [NSMutableDictionary dictionaryWithCapacity:4];
	[mdict setObject:[dict valueForKeyPath:@"author.id"] forKey:@"author_id"];
	[mdict setObject:[dict valueForKeyPath:@"author.username"] forKey:@"author_username"];
	[mdict setObject:[dict valueForKeyPath:@"author.profile_uri"] forKey:@"author_profile_uri"];
	[mdict setObject:[dict objectForKey:@"description"] forKey:@"nm_description"];
	// author thumbnail
	NSString * thumbURL = [dict valueForKeyPath:@"author.thumbnail_uri"];
	if ( thumbURL == nil || [thumbURL isEqual:@""] ) {
		[mdict setObject:[NSNull null] forKey:@"author_thumbnail_uri"];
	} else {
		[mdict setObject:thumbURL forKey:@"author_thumbnail_uri"];
	}
	return mdict;
}

//- (id)initWithChannel:(NMChannel *)aChn {
//	self = [super init];
//	command = NMCommandGetChannelVideoList;
//	self.channel = aChn;
//	self.channelName = aChn.title;
//	self.targetID = aChn.nm_id;
//	self.urlString = aChn.resource_uri;
//	totalNumberOfRows = 0;
//	return self;
//}

- (id)initGetMoreVideoForChannel:(NMChannel *)aChn {
	self = [super init];
	command = NMCommandGetMoreVideoForChannel;
	self.channel = aChn;
	self.channelName = aChn.title;
	self.targetID = aChn.nm_id;
	self.urlString = aChn.resource_uri;
	// only get the first page for now
//	currentPage = [aChn.nm_current_page integerValue];
	totalNumberOfRows = 0;
	return self;
}

- (id)initGetNewerVideoForChannel:(NMChannel *)aChn since:(NSString *)aSinceID {
	self = [super init];
	command = NMCommandGetNewerVideoForChannel;
	self.channel = aChn;
	self.channelName = aChn.title;
	self.targetID = aChn.nm_id;
	self.urlString = aChn.resource_uri;
	self.videoID = aSinceID;
	totalNumberOfRows = 0;
	return self;
}

- (id)initGetOlderVideoForChannel:(NMChannel *)aChn after:(NSString *)aMaxID {
	self = [super init];
	command = NMCommandGetOlderVideoForChannel;
	self.channel = aChn;
	self.channelName = aChn.title;
	self.targetID = aChn.nm_id;
	self.urlString = aChn.resource_uri;
	self.videoID = aMaxID;
	totalNumberOfRows = 0;
	return self;
}

- (void)dealloc {
	[channelName release];
	[channel release];
	[parsedDetailObjects release];
	[urlString release];
	[videoID release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSString * urlStr = nil;
	switch (command) {
		case NMCommandGetMoreVideoForChannel:
			urlStr = [NSString stringWithFormat:@"%@/videos?limit=%d&user_id=%d&include_viewed=1", urlString, NM_NUMBER_OF_VIDEOS_PER_PAGE, NM_USER_ACCOUNT_ID];
			break;
		case NMCommandGetNewerVideoForChannel:
			urlStr = [NSString stringWithFormat:@"%@/videos?since_id=%@&limit=%d&user_id=%d&include_viewed=1", urlString, videoID, NM_NUMBER_OF_VIDEOS_PER_PAGE, NM_USER_ACCOUNT_ID];
			break;
		case NMCommandGetOlderVideoForChannel:
			urlStr = [NSString stringWithFormat:@"%@/videos?max_id=%@&limit=%d&user_id=%d&include_viewed=1", urlString, videoID, NM_NUMBER_OF_VIDEOS_PER_PAGE, NM_USER_ACCOUNT_ID];
			break;
			
		default:
			break;
	}

#ifdef DEBUG_VIDEO_LIST_REFRESH
	NSLog(@"Get Channel Video List: %@ %@", urlStr, channelName);
#endif
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
#ifndef DEBUG_DO_NOT_SEND_API_TOKEN
	[request addValue:NM_USER_TOKEN forHTTPHeaderField:NMAuthTokenHeaderKey];
#endif
	return request;
}

- (void)processDownloadedDataInBuffer {
	// parse JSON
	if ( [buffer length] == 0 ) return;
	NSArray * chVideos = [buffer objectFromJSONData];
	numberOfRowsFromServer = [chVideos count];
	parsedObjects = [[NSMutableArray alloc] initWithCapacity:numberOfRowsFromServer];
	parsedDetailObjects = [[NSMutableArray alloc] initWithCapacity:numberOfRowsFromServer];
	NSMutableDictionary * mdict;
//	NSInteger idx = 0;
	NSDictionary * dict;
	for (NSDictionary * parentDict in chVideos) {
		for (NSString * theKey in parentDict) {
			dict = [parentDict objectForKey:theKey];
			mdict = [NMGetChannelVideoListTask normalizeVideoDictionary:dict];
//			[mdict setObject:[NSNumber numberWithInteger:idx++] forKey:@"nm_sort_order"];
			[mdict setObject:NM_SESSION_ID forKey:@"nm_session_id"];
			[parsedObjects addObject:mdict];
			[parsedDetailObjects addObject:[NMGetChannelVideoListTask normalizeDetailDictionary:dict]];
		}
	}
	
}

- (void)insertAllVideosInController:(NMDataController *)ctrl {
	NSMutableDictionary * dict;
	NMVideo * vidObj;
	NMVideoDetail * dtlObj;
	NSUInteger vidCount = 0;
	NSInteger theOrder = [ctrl maxVideoSortOrderInChannel:channel sessionOnly:YES] + 1;
	NSNumber * yesNum = [NSNumber numberWithBool:YES];
	for (dict in parsedObjects) {
		vidObj = [ctrl insertNewVideo];
		[dict setObject:[NSNumber numberWithInteger:theOrder++] forKey:@"nm_sort_order"];
		[vidObj setValuesForKeysWithDictionary:dict];
		if ( isFavoriteChannel ) {
			vidObj.nm_favorite = yesNum;
		}
		if ( isWatchLaterChannel ) {
			vidObj.nm_watch_later = yesNum;
		}
		// channel
		vidObj.channel = channel;
		// video detail
		dtlObj = [ctrl insertNewVideoDetail];
		dict = [parsedDetailObjects objectAtIndex:vidCount];
		[dtlObj setValuesForKeysWithDictionary:dict];
		dtlObj.video = vidObj;
		
		vidCount++;
	}
	channel.nm_hidden = [NSNumber numberWithBool:NO];
	numberOfVideoAdded = [parsedObjects count];
	totalNumberOfRows = numberOfVideoAdded + [channel.videos count];
}

- (void)insertOnlyNewVideosInController:(NMDataController *)ctrl {
	NSMutableDictionary * dict;
	NMVideo * vidObj;
	NMVideoDetail * dtlObj;
	NSUInteger idx = [channel.videos count];
	NSUInteger vidCount = 0;
	// insert video but do not insert duplicate item
	if ( idx ) {
		NSMutableIndexSet * idIndexSet = [NSMutableIndexSet indexSet];
		NSSet * theVideos = channel.videos;
		for (vidObj in theVideos) {
			[idIndexSet addIndex:[vidObj.nm_id unsignedIntegerValue]];
		}
		numberOfVideoAdded = 0;
		NSInteger theOrder = [ctrl maxVideoSortOrderInChannel:channel sessionOnly:YES] + 1;
		NSNumber * yesNum = [NSNumber numberWithBool:YES];
		for (dict in parsedObjects) {
			if ( ![idIndexSet containsIndex:[[dict objectForKey:@"nm_id"] unsignedIntegerValue]] ) {
				numberOfVideoAdded++;
				vidObj = [ctrl insertNewVideo];
				[dict setObject:[NSNumber numberWithInteger:theOrder++] forKey:@"nm_sort_order"];
				[vidObj setValuesForKeysWithDictionary:dict];
				if ( isFavoriteChannel ) {
					vidObj.nm_favorite = yesNum;
				}
				if ( isWatchLaterChannel ) {
					vidObj.nm_watch_later = yesNum;
				}
				// channel
				vidObj.channel = channel;
				//[channel addVideosObject:vidObj];
				// video detail
				dtlObj = [ctrl insertNewVideoDetail];
				dict = [parsedDetailObjects objectAtIndex:vidCount];
				[dtlObj setValuesForKeysWithDictionary:dict];
				dtlObj.video = vidObj;
				//vidObj.detail = dtlObj;
			} else {
				// update the view count
				vidObj.view_count = [dict objectForKey:@"view_count"];
				// do NOT update the session ID
			}
			vidCount++;
		}
		totalNumberOfRows = numberOfVideoAdded + idx;
		if ( numberOfVideoAdded ) {
			channel.nm_hidden = [NSNumber numberWithBool:NO];
		}
	} else {
		[self insertAllVideosInController:ctrl];
	}
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	if ( numberOfRowsFromServer ) {
		isFavoriteChannel = [ctrl.favoriteVideoChannel isEqual:channel];
		isWatchLaterChannel = [ctrl.myQueueChannel isEqual:channel];
		[self insertOnlyNewVideosInController:ctrl];
		// update the page number
//		if ( numberOfRowsFromServer == NM_NUMBER_OF_VIDEOS_PER_PAGE ) {
//			channel.nm_current_page = [NSNumber numberWithInteger:currentPage + 1];
//		}
	}
#ifdef DEBUG_VIDEO_LIST_REFRESH
	NSLog(@"video list added - %@ %d", channelName, numberOfVideoAdded);
#endif
	// update last refreshed time stamp
	channel.nm_video_last_refresh = [NSDate date];
	return numberOfVideoAdded > 0;
}

- (NSString *)willLoadNotificationName {
	switch (command) {
		case NMCommandGetMoreVideoForChannel:
			return NMWillGetChannelVideoListNotification;
			
		case NMCommandGetNewerVideoForChannel:
			return NMWillGetNewVideoForChannelNotification;
			
		case NMCommandGetOlderVideoForChannel:
			return NMWillGetOlderVideoForChannelNotification;
			
		default:
			break;
	}
	return NMWillGetChannelVideoListNotification;
}

- (NSString *)didLoadNotificationName {
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"Did get video - %@", channelName);
#endif
	switch (command) {
		case NMCommandGetMoreVideoForChannel:
			return NMDidGetChannelVideoListNotification;

		case NMCommandGetNewerVideoForChannel:
			return NMDidGetNewVideoForChannelNotification;

		case NMCommandGetOlderVideoForChannel:
			return NMDidGetOlderVideoForChannelNotification;
			
		default:
			break;
	}
	return NMDidGetChannelVideoListNotification;
}

- (NSString *)didFailNotificationName {
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"Did fail getting video - %@", channelName);
#endif
	switch (command) {
		case NMCommandGetMoreVideoForChannel:
			return NMDidFailGetChannelVideoListNotification;
			
		case NMCommandGetNewerVideoForChannel:
			return NMDidFailGetNewVideoForChannelNotification;
			
		case NMCommandGetOlderVideoForChannel:
			return NMDidFailGetOlderVideoForChannelNotification;
			
		default:
			break;
	}
	return NMDidFailGetChannelVideoListNotification;
}

- (NSString *)didCancelNotificationName {
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"Did cancel getting video - %@", channelName);
#endif
	switch (command) {
		case NMCommandGetMoreVideoForChannel:
			return NMDidCancelGetChannelVideListNotification;
			
		case NMCommandGetNewerVideoForChannel:
			return NMDidCancelGetNewVideoForChannelNotification;
			
		case NMCommandGetOlderVideoForChannel:
			return NMDidCancelGetOlderVideoForChannelNotification;
			
		default:
			break;
	}
	return NMDidCancelGetChannelVideListNotification;
}

- (NSDictionary *)userInfo {
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:numberOfVideoAdded], @"num_video_added", [NSNumber numberWithUnsignedInteger:numberOfRowsFromServer], @"num_video_received", [NSNumber numberWithUnsignedInteger:NM_NUMBER_OF_VIDEOS_PER_PAGE], @"num_video_requested", channel, @"channel", nil];
}

- (NSDictionary *)failUserInfo {
	return [NSDictionary dictionaryWithObject:channel forKey:@"channel"];
}

- (NSDictionary *)cancelUserInfo {
	return [NSDictionary dictionaryWithObject:channel forKey:@"channel"];
}

@end
