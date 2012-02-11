//
//  NMGetChannelVideosTask.m
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMGetChannelVideoListTask.h"
#import "NMChannel.h"
#import "NMSubscription.h"
#import "NMVideo.h"
#import "NMVideoDetail.h"
#import "NMConcreteVideo.h"
#import "NMAuthor.h"
#import "NMDataController.h"
#import "NMTaskQueueController.h"

#define NM_NUMBER_OF_VIDEOS_PER_PAGE_IPAD 5
#define NM_NUMBER_OF_VIDEOS_PER_PAGE_IPHONE 12
#define NM_NUMBER_OF_VIDEOS_PER_PAGE	(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? NM_NUMBER_OF_VIDEOS_PER_PAGE_IPAD : NM_NUMBER_OF_VIDEOS_PER_PAGE_IPHONE)

NSString * const NMWillGetChannelVideListNotification = @"NMWillGetChannelVideListNotification";
NSString * const NMDidGetChannelVideoListNotification = @"NMDidGetChannelVideoListNotification";
NSString * const NMDidFailGetChannelVideoListNotification = @"NMDidFailGetChannelVideoListNotification";
NSString * const NMDidCancelGetChannelVideListNotification = @"NMDidCancelGetChannelVideListNotification";


NSPredicate * outdatedVideoPredicateTempate_ = nil;

static NSArray * sharedVideoDirectJSONKeys = nil;

@implementation NMGetChannelVideoListTask
@synthesize channel, channelName;
@synthesize newChannel, urlString;
@synthesize currentPage, numberOfVideoAdded;

+ (NSArray *)directJSONKeys {
	if ( sharedVideoDirectJSONKeys == nil ) {
		sharedVideoDirectJSONKeys = [[NSArray alloc] initWithObjects:@"title", @"duration", @"external_id", @"view_count", nil];
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
	[mdict setObject:[NSNumber numberWithInteger:NMVideoSourceYouTube] forKey:@"source"];
	[mdict setObject:[dict objectForKey:@"id"] forKey:@"nm_id"];
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
	[mdict setObject:[dict objectForKey:@"description"] forKey:@"nm_description"];
	return mdict;
}

+ (NSMutableDictionary *)normalizeAuthorDictionary:(NSDictionary *)dict {
	NSMutableDictionary * mdict = [NSMutableDictionary dictionaryWithCapacity:4];
	[mdict setObject:[dict valueForKeyPath:@"author.id"] forKey:@"nm_id"];
	[mdict setObject:[dict valueForKeyPath:@"author.username"] forKey:@"username"];
	[mdict setObject:[dict valueForKeyPath:@"author.profile_uri"] forKey:@"profile_uri"];
	// author thumbnail
	NSString * thumbURL = [dict valueForKeyPath:@"author.thumbnail_uri"];
	if ( thumbURL == nil || [thumbURL isEqual:@""] ) {
		[mdict setObject:[NSNull null] forKey:@"thumbnail_uri"];
	} else {
		[mdict setObject:thumbURL forKey:@"thumbnail_uri"];
	}
	return mdict;
}

- (id)initGetMoreVideoForChannel:(NMChannel *)aChn {
	self = [super init];
	command = NMCommandGetMoreVideoForChannel;
	self.channel = aChn;
	self.channelName = aChn.title;
	self.targetID = aChn.nm_id;
	self.urlString = aChn.resource_uri;
	currentPage = [aChn.subscription.nm_current_page integerValue];
	return self;
}

- (void)dealloc {
	[channelName release];
	[channel release];
	[parsedDetailObjects release];
	[parsedAuthorObjects release];
	[authorMOCache release];
	[authorCache release];
	[urlString release];
	[super dealloc];
}

- (NSURLRequest *)URLRequest {
	NSString * urlStr = nil;
#ifdef DEBUG_CHANNEL
	if ( [targetID integerValue] == 999999 ) {
		urlStr = urlString;
	} else {
		urlStr = [NSString stringWithFormat:@"%@/videos?page=%d&limit=%d&user_id=%d", urlString, currentPage + 1, NM_NUMBER_OF_VIDEOS_PER_PAGE, NM_USER_ACCOUNT_ID];
	}
#else
	urlStr = [NSString stringWithFormat:@"%@/videos?page=%d&limit=%d&user_id=%d", urlString, currentPage + 1, NM_NUMBER_OF_VIDEOS_PER_PAGE, NM_USER_ACCOUNT_ID];
#endif

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
	parsedAuthorObjects = [[NSMutableArray alloc] initWithCapacity:numberOfRowsFromServer];
	authorCache = [[NSMutableDictionary alloc] initWithCapacity:4];
	NSMutableDictionary * mdict;
//	NSInteger idx = 0;
	NSDictionary * dict;
	NSDictionary * authorDict;
	NSNumber * authorID;
	for (NSDictionary * parentDict in chVideos) {
		for (NSString * theKey in parentDict) {
			dict = [parentDict objectForKey:theKey];
			mdict = [NMGetChannelVideoListTask normalizeVideoDictionary:dict];
			[parsedObjects addObject:mdict];
			[parsedDetailObjects addObject:[NMGetChannelVideoListTask normalizeDetailDictionary:dict]];
			authorID = [dict valueForKeyPath:@"author.id"];
			[parsedAuthorObjects addObject:authorID];
			authorDict = [authorCache objectForKey:authorID];
			if ( authorDict == nil ) {
				// parse the complete author info
				[authorCache setObject:[NMGetChannelVideoListTask normalizeAuthorDictionary:dict] forKey:authorID];
			}
		}
	}
	
}

//- (void)insertAllVideosInController:(NMDataController *)ctrl {
//	NSMutableDictionary * dict;
//	NMConcreteVideo * realVidObj;
//	NMVideoDetail * dtlObj;
//	NMVideo * infoObj;
//	NSUInteger vidCount = 0;
//	NSInteger theOrder = [ctrl maxVideoSortOrderInChannel:channel sessionOnly:YES] + 1;
//	for (dict in parsedObjects) {
//		realVidObj = [ctrl insertNewConcreteVideo];
//		[realVidObj setValuesForKeysWithDictionary:dict];
//		if ( isFavoriteChannel ) {
//			realVidObj.nm_favorite = (NSNumber *)kCFBooleanTrue;
//		}
//		if ( isWatchLaterChannel ) {
//			realVidObj.nm_watch_later = (NSNumber *)kCFBooleanTrue;
//		}
//		// channel-video
//		infoObj = [ctrl insertNewVideo];
//		infoObj.channel = channel;
//		infoObj.video = realVidObj;
//		infoObj.nm_session_id = NM_SESSION_ID;
//		infoObj.nm_sort_order = [NSNumber numberWithInteger:theOrder++];
//		// video detail
//		dtlObj = [ctrl insertNewVideoDetail];
//		dict = [parsedDetailObjects objectAtIndex:vidCount];
//		[dtlObj setValuesForKeysWithDictionary:dict];
//		dtlObj.video = realVidObj;
//		
//		vidCount++;
//	}
//	channel.nm_hidden = [NSNumber numberWithBool:NO];
//	numberOfVideoAdded = [parsedObjects count];
//	totalNumberOfRows = numberOfVideoAdded + [channel.videos count];
//}

- (NMAuthor *)prepareAuthorWithID:(NSNumber *)authID info:(NSDictionary *)authDict controller:(NMDataController *)ctrl {
	NMAuthor * theAuthor = [authorMOCache objectForKey:authID];
	if ( theAuthor == nil ) {
		// can't find it in local cache
		theAuthor = [ctrl authorForID:authID orName:[authDict objectForKey:@"username"]];
		if ( theAuthor == nil ) {
			// the author does NOT exist. create a new author
			theAuthor = [ctrl insertNewAuthor];
			[theAuthor setValuesForKeysWithDictionary:authDict];
		} else if ( theAuthor.nm_id == nil ) theAuthor.nm_id = authID;
		// add author object to the cache
		[authorMOCache setObject:theAuthor forKey:authID];
	}
	return theAuthor;
}

- (void)insertOnlyNewVideosInController:(NMDataController *)ctrl {
	NSMutableDictionary * dict;
	NMConcreteVideo * realVidObj;
	NMVideoDetail * dtlObj;
	NMVideo * infoObj;
//	NSUInteger idx = [channel.videos count];
	NSUInteger vidCount = 0;
	// insert video but do not insert duplicate item
	numberOfVideoAdded = 0;
	NSInteger theOrder = [ctrl maxVideoSortOrderInChannel:channel sessionOnly:YES] + 1;
	NSNumber * yesNum = (NSNumber *)kCFBooleanTrue;
	authorMOCache = [[NSMutableDictionary alloc] initWithCapacity:4];
	NMAuthor * theAuthor;
	NSNumber * authID;

	for (dict in parsedObjects) {
		switch ( [ctrl videoExistsWithID:[dict objectForKey:@"nm_id"] orExternalID:[dict objectForKey:@"external_id"] channel:channel targetVideo:&realVidObj] ) {
			case NMVideoDoesNotExist:
				// create video and concrete video
				numberOfVideoAdded++;
				realVidObj = [ctrl insertNewConcreteVideo];
				[realVidObj setValuesForKeysWithDictionary:dict];
				if ( isFavoriteChannel ) {
					realVidObj.nm_favorite = yesNum;
				}
				if ( isWatchLaterChannel ) {
					realVidObj.nm_watch_later = yesNum;
				}
				// channel-video
				infoObj = [ctrl insertNewVideo];
				infoObj.channel = channel;
				infoObj.video = realVidObj;
				infoObj.nm_session_id = NM_SESSION_ID;
				infoObj.nm_sort_order = [NSNumber numberWithInteger:theOrder++];
				// video detail
				dtlObj = [ctrl insertNewVideoDetail];
				dict = [parsedDetailObjects objectAtIndex:vidCount];
				[dtlObj setValuesForKeysWithDictionary:dict];
				dtlObj.video = realVidObj;
				// hook up with author
				authID = [parsedAuthorObjects objectAtIndex:vidCount];
				theAuthor = [self prepareAuthorWithID:authID info:[authorCache objectForKey:authID] controller:ctrl];
				realVidObj.author = theAuthor;
				break;
				
			case NMVideoExistsButNotInChannel:
				// create video object only
				numberOfVideoAdded++;
				if ( isFavoriteChannel ) {
					realVidObj.nm_favorite = yesNum;
				}
				if ( isWatchLaterChannel ) {
					realVidObj.nm_watch_later = yesNum;
				}
				// channel-video
				infoObj = [ctrl insertNewVideo];
				infoObj.channel = channel;
				infoObj.video = realVidObj;
				infoObj.nm_session_id = NM_SESSION_ID;
				infoObj.nm_sort_order = [NSNumber numberWithInteger:theOrder++];
				break;
				
			default:
				// just update the view count
				realVidObj.view_count = [dict objectForKey:@"view_count"];
				break;
		}
		vidCount++;
	}
//	totalNumberOfRows = numberOfVideoAdded + idx;
	if ( numberOfVideoAdded ) {
		channel.subscription.nm_hidden = [NSNumber numberWithBool:NO];
	}
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	if ( numberOfRowsFromServer ) {
		isFavoriteChannel = [ctrl.favoriteVideoChannel isEqual:channel];
		isWatchLaterChannel = [ctrl.myQueueChannel isEqual:channel];
		[self insertOnlyNewVideosInController:ctrl];
		// update the page number
		if ( numberOfRowsFromServer == NM_NUMBER_OF_VIDEOS_PER_PAGE ) {
			channel.subscription.nm_current_page = [NSNumber numberWithInteger:currentPage + 1];
		}
	}
//	NSInteger chnID = [targetID integerValue];
//	if ( chnID == NM_USER_TWITTER_CHANNEL_ID || chnID == NM_USER_FACEBOOK_CHANNEL_ID ) {
//		// check if we need to show/hide the stream channel
//		if ( ![ctrl channelContainsVideo:channel] ) {
//			// the channel is empty after update
//			if ( ![channel.nm_hidden boolValue] ) {
//				channel.nm_hidden = [NSNumber numberWithBool:YES];
//			}
//		} else if ( [channel.nm_hidden boolValue] ) {
//			channel.nm_hidden = [NSNumber numberWithBool:NO];
//		}
//	}
#ifdef DEBUG_VIDEO_LIST_REFRESH
	NSLog(@"video list added - %@ %d", channelName, numberOfVideoAdded);
#endif
	// update last refreshed time stamp
	channel.subscription.nm_video_last_refresh = [NSDate date];
	return numberOfVideoAdded > 0;
}

- (NSString *)willLoadNotificationName {
	return NMWillGetChannelVideListNotification;
}

- (NSString *)didLoadNotificationName {
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"Did get video - %@", channelName);
#endif
	return NMDidGetChannelVideoListNotification;
}

- (NSString *)didFailNotificationName {
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"Did fail getting video - %@", channelName);
#endif
	return NMDidFailGetChannelVideoListNotification;
}

- (NSString *)didCancelNotificationName {
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"Did cancel getting video - %@", channelName);
#endif
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
