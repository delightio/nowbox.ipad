//
//  NMGetChannelsTask.m
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMGetChannelsTask.h"
#import "NMGetChannelVideoListTask.h"
#import "NMChannel.h"
#import "NMVideo.h"
#import "NMCategory.h"
#import "NMDataController.h"
#import "NMTaskQueueController.h"


NSString * const NMWillGetChannelsNotification = @"NMWillGetChannelsNotification";
NSString * const NMDidGetChannelsNotification = @"NMDidGetChannelsNotification";
NSString * const NMDidFailGetChannelsNotification = @"NMDidFailGetChannelsNotification";

NSString * const NMWillGetChannelsForCategoryNotification = @"NMWillGetChannelsForCategoryNotification";
NSString * const NMDidGetChannelsForCategoryNotification = @"NMDidGetChannelsForCategoryNotification";
NSString * const NMDidFailGetChannelsForCategoryNotification = @"NMDidFailGetChannelsForCategoryNotification";

NSString * const NMWillSearchChannelsNotification = @"NMWillSearchChannelsNotification";
NSString * const NMDidSearchChannelsNotification = @"NMDidSearchChannelsNotification";
NSString * const NMDidFailSearchChannelsNotification = @"NMDidFailSearchChannelsNotification";

@implementation NMGetChannelsTask

@synthesize trendingChannel;
@synthesize searchWord;
@synthesize category;

+ (NSMutableDictionary *)normalizeChannelDictionary:(NSDictionary *)chnCtnDict {
	NSMutableDictionary * pDict = [NSMutableDictionary dictionaryWithCapacity:8];
	[pDict setObject:[chnCtnDict objectForKey:@"title"] forKey:@"title"];
	[pDict setObject:[chnCtnDict objectForKey:@"resource_uri"] forKey:@"resource_uri"];
	[pDict setObject:[chnCtnDict objectForKey:@"video_count"] forKey:@"video_count"];
	NSString * chnType = [[chnCtnDict objectForKey:@"type"] lowercaseString];
	if ( [chnType isEqualToString:@"user"] ) {
		[pDict setObject:[NSNumber numberWithInteger:NMChannelUserType] forKey:@"type"];
	} else if ( [chnType isEqualToString:@"account::youtube"] ) {
		[pDict setObject:[NSNumber numberWithInteger:NMChannelYoutubeType] forKey:@"type"];
	} else if ( [chnType isEqualToString:@"account::vimeo"] ) {
		[pDict setObject:[NSNumber numberWithInteger:NMChannelVimeoType] forKey:@"type"];
	} else if ( [chnType isEqualToString:@"keyword"] ) {
		[pDict setObject:[NSNumber numberWithInteger:NMChannelKeywordType] forKey:@"type"];
	} else if ( [chnType isEqualToString:@"facebookstream"] ) {
		[pDict setObject:[NSNumber numberWithInteger:NMChannelUserFacebookType] forKey:@"type"];
	} else if ( [chnType isEqualToString:@"twitterstream"] ) {
		[pDict setObject:[NSNumber numberWithInteger:NMChannelUserTwitterType] forKey:@"type"];
	} else {
		[pDict setObject:[NSNumber numberWithInteger:NMChannelUnknownType] forKey:@"type"];
	}
	NSString * thumbURL = [chnCtnDict objectForKey:@"thumbnail_uri"];
	if ( thumbURL == nil || [thumbURL isEqual:@""] ) {
		[pDict setObject:[NSNull null] forKey:@"thumbnail_uri"];
	} else {
		[pDict setObject:thumbURL forKey:@"thumbnail_uri"];
	}
	[pDict setObject:[chnCtnDict objectForKey:@"id"] forKey:@"nm_id"];
	
	return pDict;
}

- (id)init {
	self = [super init];
	command = NMCommandGetAllChannels;
	channelJSONKeys = [[NSArray alloc] initWithObjects:@"title", @"resource_uri", nil];
	return self;
}

- (id)initGetDefaultChannels {
	self = [self init];
	command = NMCommandGetSubscribedChannels;
	return self;
}

- (id)initGetChannelForCategory:(NMCategory *)aCat {
	self = [self init];
	command = NMCommandGetChannelsForCategory;
	self.targetID = aCat.nm_id;
	self.category = aCat;
	return self;
}

- (id)initSearchChannelWithKeyword:(NSString *)str {
	self = [self init];
	command = NMCommandSearchChannels;
	self.searchWord = str;
	return self;
}

- (void)dealloc {
	[channelJSONKeys release];
	[trendingChannel release];
	[category release];
	[searchWord release];
	[channelIndexSet release];
	[parsedObjectDictionary release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSString * urlStr;
	NSTimeInterval t = NM_URL_REQUEST_TIMEOUT;
	switch (command) {
		case NMCommandGetSubscribedChannels:
			urlStr = [NSString stringWithFormat:@"http://%@/channels?user_id=%d", NM_BASE_URL, NM_USER_ACCOUNT_ID];
			break;
		case NMCommandGetChannelsForCategory:
			urlStr = [NSString stringWithFormat:@"http://%@/categories/%@/channels?user_id=%d&type=featured", NM_BASE_URL, targetID, NM_USER_ACCOUNT_ID];
			break;
		case NMCommandSearchChannels:
			urlStr = [NSString stringWithFormat:@"http://%@/channels?user_id=%d&query=%@", NM_BASE_URL, NM_USER_ACCOUNT_ID, [searchWord stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			break;
		default:
			break;
	}

#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"Get Channels: %@", urlStr);
#endif
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:t];
	return request;
}

- (void)processDownloadedDataInBuffer {
	// parse JSON
	if ( [buffer length] == 0 ) {
		return;
	}
	NSString * str = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
	NSArray * theChs = [str objectFromJSONString];
	[str release];
	
	parsedObjectDictionary = [[NSMutableDictionary alloc] initWithCapacity:[theChs count]];
	NSDictionary * cDict, * chnCtnDict;
	NSMutableDictionary * pDict;
	channelIndexSet = [[NSMutableIndexSet alloc] init];
	NSNumber * idNum;
	NSInteger i = 0;
	NSNumber * subscribedNum = nil;
	BOOL containsKeywordChannel = NO;
	if ( command == NMCommandGetSubscribedChannels ) {
		subscribedNum = [NSNumber numberWithBool:YES];
	}
	for (cDict in theChs) {
		for (NSString * rKey in cDict) {				// attribute key cleanser
			chnCtnDict = [cDict objectForKey:rKey];
			idNum = [chnCtnDict objectForKey:@"id"];
			pDict = [NMGetChannelsTask normalizeChannelDictionary:chnCtnDict];
			switch (command) {
				case NMCommandGetSubscribedChannels:
#ifdef DEBUG_CHANNEL
					[pDict setObject:[NSNumber numberWithInteger:++i] forKey:@"nm_sort_order"];
#else
					[pDict setObject:[NSNumber numberWithInteger:++i] forKey:@"nm_subscribed"];
#endif
					break;
					
				case NMCommandSearchChannels:
					// check if keyword channel exists
					if ( [[pDict objectForKey:@"title"] isEqualToString:searchWord] ) {
						containsKeywordChannel = YES;
					}
					[pDict setObject:[NSNumber numberWithInteger:++i] forKey:@"nm_sort_order"];
					break;
					
				default:
					[pDict setObject:[NSNumber numberWithInteger:++i] forKey:@"nm_sort_order"];
					break;
			}
			
			[channelIndexSet addIndex:[idNum unsignedIntegerValue]];
			[parsedObjectDictionary setObject:pDict forKey:idNum];
		}
	}
#ifdef DEBUG_CHANNEL
	// create test channel
	[channelIndexSet addIndex:999999];
	pDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Test Channel", @"title", @"https://project.headnix.com/pipely/channel.json", @"resource_uri", [NSNumber numberWithInteger:NMChannelKeywordType], @"type", [NSNull null], @"thumbnail_uri", [NSNumber numberWithInteger:999999], @"nm_id", [NSNumber numberWithInteger:++i], @"nm_subscribed", nil];
	[parsedObjectDictionary setObject:pDict forKey:[NSNumber numberWithInteger:999999]];
#endif
	if ( command == NMCommandSearchChannels && !containsKeywordChannel ) {
		// create a fake keyword channel
		NSNumber * zeroNum = [NSNumber numberWithInteger:0];
		NSDictionary * fakeDict = [NSDictionary dictionaryWithObjectsAndKeys:
								   zeroNum, @"nm_id", 
								   [NSNumber numberWithInteger:NMChannelKeywordType], @"type",
								   searchWord, @"title",
								   @"http://nowbox.com/images/icons/tag.png", @"thumbnail_uri",
								   zeroNum, @"video_count",
								   @"", @"resource_uri",
								   [NSNumber numberWithInteger:++i], @"nm_sort_order", nil];
		[parsedObjectDictionary setObject:fakeDict forKey:zeroNum];
		[channelIndexSet addIndex:0];
	}
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	id<NSFastEnumeration> theChannelPool = nil;
	switch (command) {
		case NMCommandGetChannelsForCategory:
			// if getting channel for a category, check if the category contains the channel
			theChannelPool = category.channels;
			break;
		case NMCommandGetSubscribedChannels:
			// if getting subscribed channel, compare with all existing subscribed channels
			theChannelPool = ctrl.subscribedChannels;
			break;
		case NMCommandSearchChannels:
		{
			// different handling from other case. Search result is managed by view controller. Always append info
			NSMutableDictionary * chnDict;
			NMChannel * chnObj;
			for (NSNumber * theKey in parsedObjectDictionary) {
				chnDict = [parsedObjectDictionary objectForKey:theKey];
				// check if the channel exist
				chnObj = [ctrl channelForID:theKey];
				if ( chnObj == nil ) {
					// create the channel
					chnObj = [ctrl insertNewChannelForID:theKey];
					[chnObj setValuesForKeysWithDictionary:chnDict];
					// there's no need to set relationship with the existing channel objects.
				} else if ( [chnObj.nm_id integerValue] == 0 ) {
					// this is a placeholder channel, update it's content
					[chnObj setValuesForKeysWithDictionary:chnDict];
				}
				// add the search category
				[ctrl.internalSearchCategory addChannelsObject:chnObj];
				//[chnObj addCategoriesObject:ctrl.internalSearchCategory];
			}
			return NO;		// return this function
		}
		default:
			break;
	}
	
	NSUInteger cid;
	NSMutableArray * objectsToDelete = nil;
	NMChannel * chnObj;
	NSDictionary * chnDict;
	// update / delete existing channel
	for (chnObj in theChannelPool) {
		cid = [chnObj.nm_id unsignedIntegerValue];
		if ( [channelIndexSet containsIndex:cid] ) {
			chnDict = [parsedObjectDictionary objectForKey:chnObj.nm_id];
			// the channel exists, update its sort order
			chnObj.nm_sort_order = [chnDict objectForKey:@"nm_sort_order"];
			[channelIndexSet removeIndex:cid];
		} else {
			if ( objectsToDelete == nil ) objectsToDelete = [NSMutableArray arrayWithCapacity:4];
			[objectsToDelete addObject:chnObj];
		}
	}
	// delete objects
	if ( objectsToDelete ) [ctrl batchDeleteChannels:objectsToDelete];
	if ( [channelIndexSet count] ) {
		// add the remaining channals
		[channelIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			// check if the channel exists among all stored
			NSNumber * idNum = [NSNumber numberWithUnsignedInteger:idx];
			// search the channel object. The channel may exist in another category. So, need to search if it already exists in the current database.
			NMChannel * chn = [ctrl channelForID:idNum];
			NSMutableDictionary * chnDict = [parsedObjectDictionary objectForKey:idNum];
			if ( chn == nil ) {
				// create the new object
				chn = [ctrl insertNewChannelForID:[chnDict objectForKey:@"nm_id"]];
				[chn setValuesForKeysWithDictionary:chnDict];
			} else {
				// the channel already exists, just update the sort order.
				chnObj.nm_sort_order = [chnDict objectForKey:@"nm_sort_order"];
				//TODO: to be more correct, sort order should be stored in the relationship object cos the order of a channel can be different in different category
			}
			// add the channel to the relationship.
			switch (command) {
				case NMCommandGetChannelsForCategory:
					[chn addCategoriesObject:category];
					//[category addChannelsObject:chn];
					break;
				case NMCommandGetSubscribedChannels:
					[ctrl.internalSubscribedChannelsCategory addChannelsObject:chn];
					//[chn addCategoriesObject:ctrl.internalSubscribedChannelsCategory];
					break;
				default:
					break;
			}
		}];
	}
	return YES;
}

- (NSString *)willLoadNotificationName {
	switch (command) {
		case NMCommandSearchChannels:
			return NMWillSearchChannelsNotification;
		case NMCommandGetChannelsForCategory:
			return NMWillGetChannelsForCategoryNotification;
		default:
			return NMWillGetChannelsNotification;
	}
}

- (NSString *)didLoadNotificationName {
	switch (command) {
		case NMCommandSearchChannels:
			return NMDidSearchChannelsNotification;
		case NMCommandGetChannelsForCategory:
			return NMDidGetChannelsForCategoryNotification;
		default:
			return NMDidGetChannelsNotification;
	}
}

- (NSString *)didFailNotificationName {
	switch (command) {
		case NMCommandSearchChannels:
			return NMDidFailSearchChannelsNotification;
		case NMCommandGetChannelsForCategory:
			return NMDidFailGetChannelsForCategoryNotification;
		default:
			return NMDidFailGetChannelsNotification;
	}
}

- (NSDictionary *)failUserInfo {
	if ( command == NMCommandSearchChannels ) {
		return [NSDictionary dictionaryWithObject:searchWord forKey:@"keyword"];
	}
	return nil;
}

- (NSDictionary *)userInfo {
	switch (command) {
		case NMCommandSearchChannels:
		{
			return [NSDictionary dictionaryWithObject:searchWord forKey:@"keyword"];
		}
		case NMCommandGetChannelsForCategory:
		{
			return [NSDictionary dictionaryWithObjectsAndKeys:category, @"category", nil];
		}
		default:
		{
			if ( trendingChannel ) {
				return [NSDictionary dictionaryWithObjectsAndKeys:trendingChannel, @"live_channel", [NSNumber numberWithInteger:command], @"type", nil];
			} else {
				return [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:command] forKey:@"type"];
			}
		}
	}
	return nil;
}

@end
