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

- (id)init {
	self = [super init];
	command = NMCommandGetAllChannels;
	channelJSONKeys = [[NSArray alloc] initWithObjects:@"title", @"resource_uri", nil];
	return self;
}

- (id)initGetFriendChannels {
	self = [self init];
	command = NMCommandGetFriendChannels;
	return self;
}

- (id)initGetTopicChannels {
	self = [self init];
	command = NMCommandGetTopicChannels;
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
			urlStr = [NSString stringWithFormat:@"http://%@/channels?user_id=%d&query=%@", NM_BASE_URL, NM_USER_ACCOUNT_ID, searchWord];
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
	NSString * theKey;
	NSString * thumbURL;
	NSString * chnType;
	channelIndexSet = [[NSMutableIndexSet alloc] init];
	NSNumber * idNum;
	NSInteger i = 0;
	NSNumber * subscribedNum = nil;
	if ( command == NMCommandGetSubscribedChannels ) {
		subscribedNum = [NSNumber numberWithBool:YES];
	}
	for (cDict in theChs) {
		for (NSString * rKey in cDict) {				// attribute key cleanser
			chnCtnDict = [cDict objectForKey:rKey];
			pDict = [NSMutableDictionary dictionary];
			for (theKey in channelJSONKeys) {
				[pDict setObject:[chnCtnDict objectForKey:theKey] forKey:theKey];
			}
			chnType = [chnCtnDict objectForKey:@"type"];
			if ( [chnType isEqualToString:@"User"] ) {
				[pDict setObject:[NSNumber numberWithInteger:NMChannelUserType] forKey:@"type"];
			} else if ( [chnType isEqualToString:@"Account::Youtube"] ) {
				[pDict setObject:[NSNumber numberWithInteger:NMChannelYoutubeType] forKey:@"type"];
			} else if ( [chnType isEqualToString:@"Account::Vimeo"] ) {
				[pDict setObject:[NSNumber numberWithInteger:NMChannelVimeoType] forKey:@"type"];
			} else {
				[pDict setObject:[NSNumber numberWithInteger:NMChannelUnknownType] forKey:@"type"];
			}
			thumbURL = [chnCtnDict objectForKey:@"thumbnail_uri"];
			if ( thumbURL == nil || [thumbURL isEqualToString:@""] ) {
				[pDict setObject:[NSNull null] forKey:@"thumbnail_uri"];
			} else {
				[pDict setObject:thumbURL forKey:@"thumbnail_uri"];
			}
			idNum = [chnCtnDict objectForKey:@"id"];
			[pDict setObject:idNum forKey:@"nm_id"];
			[pDict setObject:[NSNumber numberWithInteger:i++] forKey:@"nm_sort_order"];
			if ( command == NMCommandGetSubscribedChannels ) {
				[pDict setObject:subscribedNum forKey:@"nm_subscribed"];
			}
			//[pDict setObject:[chnCtnDict objectForKey:@"category_ids"] forKey:@"category_ids"];
			
			[channelIndexSet addIndex:[idNum unsignedIntegerValue]];
			[parsedObjectDictionary setObject:pDict forKey:idNum];
		}
	}
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
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
				}
				// add the search category
				[ctrl.internalSearchCategory addChannelsObject:chnObj];
				//[chnObj addCategoriesObject:ctrl.internalSearchCategory];
			}
			return;		// return this function
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

- (NSDictionary *)userInfo {
	switch (command) {
		case NMCommandSearchChannels:
		{
			break;
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
