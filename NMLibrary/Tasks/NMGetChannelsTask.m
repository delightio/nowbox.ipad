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

NSString * const NMWillGetChannelWithIDNotification = @"NMWillGetChannelWithIDNotification";
NSString * const NMDidGetChannelWithIDNotification = @"NMDidGetChannelWithIDNotification";
NSString * const NMDidFailGetChannelWithIDNotification = @"NMDidFailGetChannelWithIDNotification";

NSString * const NMWillGetChannelsForCategoryNotification = @"NMWillGetChannelsForCategoryNotification";
NSString * const NMDidGetChannelsForCategoryNotification = @"NMDidGetChannelsForCategoryNotification";
NSString * const NMDidFailGetChannelsForCategoryNotification = @"NMDidFailGetChannelsForCategoryNotification";

NSString * const NMWillSearchChannelsNotification = @"NMWillSearchChannelsNotification";
NSString * const NMDidSearchChannelsNotification = @"NMDidSearchChannelsNotification";
NSString * const NMDidFailSearchChannelsNotification = @"NMDidFailSearchChannelsNotification";

NSString * const NMWillGetFeaturedChannelsForCategories = @"NMWillGetFeaturedChannelsForCategories";
NSString * const NMDidGetFeaturedChannelsForCategories = @"NMDidGetFeaturedChannelsForCategories";
NSString * const NMDidFailGetFeaturedChannelsForCategories = @"NMDidFailGetFeaturedChannelsForCategories";

NSString * const NMWillCompareSubscribedChannelsNotification = @"NMWillCompareSubscribedChannelsNotification";
NSString * const NMDidCompareSubscribedChannelsNotification = @"NMDidCompareSubscribedChannelsNotification";
NSString * const NMDidFailCompareSubscribedChannelsNotification = @"NMDidFailCompareSubscribedChannelsNotification";

@implementation NMGetChannelsTask

//@synthesize trendingChannel;
@synthesize searchWord;
@synthesize category;

+ (NSMutableDictionary *)normalizeChannelDictionary:(NSDictionary *)chnCtnDict {
	NSMutableDictionary * pDict = [NSMutableDictionary dictionaryWithCapacity:8];
	[pDict setObject:[chnCtnDict objectForKey:@"title"] forKey:@"title"];
	[pDict setObject:[chnCtnDict objectForKey:@"resource_uri"] forKey:@"resource_uri"];
	[pDict setObject:[chnCtnDict objectForKey:@"video_count"] forKey:@"video_count"];
	[pDict setObject:[chnCtnDict objectForKey:@"subscriber_count"] forKey:@"subscriber_count"];
	[pDict setObject:[NSDate dateWithTimeIntervalSince1970:[[chnCtnDict objectForKey:@"populated_at"] floatValue]] forKey:@"populated_at"];
	NSString * chnType = [[chnCtnDict objectForKey:@"type"] lowercaseString];
	if ( [chnType isEqualToString:@"user"] ) {
		[pDict setObject:[NSNumber numberWithInteger:NMChannelUserType] forKey:@"type"];
	} else if ( [chnType isEqualToString:@"account::youtube"] ) {
		[pDict setObject:[NSNumber numberWithInteger:NMChannelYouTubeType] forKey:@"type"];
	} else if ( [chnType isEqualToString:@"account::vimeo"] ) {
		[pDict setObject:[NSNumber numberWithInteger:NMChannelVimeoType] forKey:@"type"];
	} else if ( [chnType isEqualToString:@"keyword"] ) {
		[pDict setObject:[NSNumber numberWithInteger:NMChannelKeywordType] forKey:@"type"];
	} else if ( [chnType isEqualToString:@"facebookstream"] ) {
#ifdef DEBUG_FORCE_IGNORE_POPULATE_AT
		[pDict setObject:[NSDate dateWithTimeIntervalSince1970:0.0f] forKey:@"populated_at"];
#endif
		[pDict setObject:[NSNumber numberWithInteger:NMChannelUserFacebookType] forKey:@"type"];
	} else if ( [chnType isEqualToString:@"twitterstream"] ) {
#ifdef DEBUG_FORCE_IGNORE_POPULATE_AT
		[pDict setObject:[NSDate dateWithTimeIntervalSince1970:0.0f] forKey:@"populated_at"];
#endif
		[pDict setObject:[NSNumber numberWithInteger:NMChannelUserTwitterType] forKey:@"type"];
	} else if ( [chnType isEqualToString:@"trending"] ) {
		[pDict setObject:[NSNumber numberWithInt:NMChannelTrendingType] forKey:@"type"];
	} else {
		[pDict setObject:[NSNumber numberWithInteger:NMChannelUnknownType] forKey:@"type"];
	}
	NSArray * catIDAy = [chnCtnDict objectForKey:@"category_ids"];
	if ( catIDAy ) {
		[pDict setObject:catIDAy forKey:@"category_ids"];
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
	static NSUInteger localIncrementCount = 0;
	self = [self init];
	command = NMCommandSearchChannels;
	self.targetID = [NSNumber numberWithUnsignedInteger:++localIncrementCount];
	self.searchWord = str;
	return self;
}

- (id)initGetFeaturedChannelsForCategories:(NSArray *)catArray {
	self = [self init];
	command = NMCommandGetFeaturedChannelsForCategories;
	categoryIDs = [[NSMutableArray alloc] initWithCapacity:[catArray count]];
	for ( NMCategory * catObj in catArray) {
		[categoryIDs addObject:catObj.nm_id];
	}
	return self;
}

- (id)initGetChannelWithID:(NSInteger)chnID {
	self = [self init];
	command = NMCommandGetChannelWithID;
	self.targetID = [NSNumber numberWithInteger:chnID];
	return self;
}

- (id)initCompareSubscribedChannels {
	self = [self init];
	command = NMCommandCompareSubscribedChannels;
	return self;
}

- (void)dealloc {
	[channelJSONKeys release];
//	[trendingChannel release];
	[category release];
	[searchWord release];
	[channelIndexSet release];
	[parsedObjectDictionary release];
	[categoryIDs release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSString * urlStr = nil;
	NSTimeInterval t = NM_URL_REQUEST_TIMEOUT;
	switch (command) {
		case NMCommandGetSubscribedChannels:
		case NMCommandCompareSubscribedChannels:
			urlStr = [NSString stringWithFormat:@"http://%@/channels?user_id=%d", NM_BASE_URL, NM_USER_ACCOUNT_ID];
			break;
		case NMCommandGetChannelsForCategory:
			urlStr = [NSString stringWithFormat:@"http://%@/categories/%@/channels?user_id=%d&type=featured", NM_BASE_URL, targetID, NM_USER_ACCOUNT_ID];
			break;
		case NMCommandSearchChannels:
			urlStr = [NSString stringWithFormat:@"http://%@/channels?user_id=%d&query=%@", NM_BASE_URL, NM_USER_ACCOUNT_ID, [searchWord stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			break;
		case NMCommandGetChannelWithID:
			urlStr = [NSString stringWithFormat:@"http://%@/channels/%@?user_id=%d", NM_BASE_URL, targetID, NM_USER_ACCOUNT_ID];
			break;
		case NMCommandGetFeaturedChannelsForCategories:
			urlStr = [NSString stringWithFormat:@"http://%@/channels?category_ids=%@&type=featured", NM_BASE_URL, [categoryIDs componentsJoinedByString:@","], NM_USER_ACCOUNT_ID];
			break;
		default:
			break;
	}

#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"Get Channels: %@", urlStr);
#endif
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:t];
#ifndef DEBUG_DO_NOT_SEND_API_TOKEN
	[request addValue:NM_USER_TOKEN forHTTPHeaderField:NMAuthTokenHeaderKey];
#endif
	return request;
}

- (void)processDownloadedDataInBuffer {
	// parse JSON
	if ( [buffer length] == 0 ) {
		return;
	}
	id parsedJSONObj = [buffer objectFromJSONData];
	NSArray * theChs;
	if ( command == NMCommandGetChannelWithID ) {
		theChs = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:parsedJSONObj forKey:@"account"]];
	} else {
		theChs = parsedJSONObj;
	}
	
	parsedObjectDictionary = [[NSMutableDictionary alloc] initWithCapacity:[theChs count]];
	NSDictionary * cDict, * chnCtnDict;
	NSMutableDictionary * pDict;
	channelIndexSet = [[NSMutableIndexSet alloc] init];
	NSNumber * idNum;
	NSInteger i = 0;
	BOOL containsKeywordChannel = NO;
	if ( command == NMCommandGetChannelWithID ) {
		
	}
	for (cDict in theChs) {
		for (NSString * rKey in cDict) {				// attribute key cleanser
			chnCtnDict = [cDict objectForKey:rKey];
			idNum = [chnCtnDict objectForKey:@"id"];
			pDict = [NMGetChannelsTask normalizeChannelDictionary:chnCtnDict];
			switch (command) {
				case NMCommandGetSubscribedChannels:
				case NMCommandGetChannelWithID:
				case NMCommandCompareSubscribedChannels:
#ifdef DEBUG_CHANNEL
					[pDict setObject:[NSNumber numberWithInteger:++i] forKey:@"nm_sort_order"];
#else
					[pDict setObject:[NSNumber numberWithInteger:++i] forKey:@"nm_subscribed"];
#endif
					[pDict removeObjectForKey:@"category_ids"];
					break;
					
				case NMCommandSearchChannels:
					// check if keyword channel exists
					if ( [[pDict objectForKey:@"title"] caseInsensitiveCompare:searchWord] == NSOrderedSame ) {
						containsKeywordChannel = YES;
					}
					[pDict removeObjectForKey:@"category_ids"];
					[pDict setObject:[NSNumber numberWithInteger:++i] forKey:@"nm_sort_order"];
					break;
					
				case NMCommandGetChannelsForCategory:
					[pDict setObject:[NSNumber numberWithInteger:++i] forKey:@"nm_sort_order"];
					[pDict removeObjectForKey:@"category_ids"];
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
			numberOfRowsFromServer = [parsedObjectDictionary count];
			theChannelPool = category.channels;
			category.nm_last_refresh = [NSDate date];
			break;
		case NMCommandGetSubscribedChannels:
			// if getting subscribed channel, compare with all existing subscribed channels
			numberOfRowsFromServer = [parsedObjectDictionary count];
			theChannelPool = ctrl.subscribedChannels;
			break;
		case NMCommandGetFeaturedChannelsForCategories:
		{
			// different handling from other case. Search result is managed by view controller. Always append info
			NSMutableDictionary * chnDict;
			NMChannel * chnObj;
			NSArray * catIDAy;
			NMCategory * catObj;
			// reuse the var for storing downloaded channels
			[categoryIDs removeAllObjects];
			for (NSNumber * theKey in parsedObjectDictionary) {
				chnDict = [parsedObjectDictionary objectForKey:theKey];
				// check if the channel exist
				chnObj = [ctrl channelForID:theKey];
				catIDAy = [[chnDict objectForKey:@"category_ids"] retain];
				[chnDict removeObjectForKey:@"category_ids"];
				if ( chnObj == nil ) {
					// create the channel
					chnObj = [ctrl insertNewChannelForID:theKey];
					[chnObj setValuesForKeysWithDictionary:chnDict];
					if ( [catIDAy count] ) {
                        for (NSNumber *categoryId in catIDAy) {
                            catObj = [ctrl categoryForID:categoryId];
                            [catObj addChannelsObject:chnObj];                            
                        }
					}
					// there's no need to set relationship with the existing channel objects.
				} else if ( [chnObj.nm_id integerValue] == 0 ) {
					// this is a placeholder channel, update it's content
					[chnObj setValuesForKeysWithDictionary:chnDict];
				}
				[catIDAy release];
				// add the search category
				[categoryIDs addObject:chnObj];
			}
			return NO;		// return this function
		}
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
	
	if ( numberOfRowsFromServer == 0 ) {
		// there's no data channel from the server
		return NO;
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
			if ( command == NMCommandGetSubscribedChannels ) {
				chnObj.nm_subscribed = [chnDict objectForKey:@"nm_subscribed"];
			}
			[channelIndexSet removeIndex:cid];
		} else {
			if ( objectsToDelete == nil ) objectsToDelete = [NSMutableArray arrayWithCapacity:4];
			[objectsToDelete addObject:chnObj];
		}
	}
	// delete objects
	if ( objectsToDelete ) {
		numberOfRowsDeleted = [objectsToDelete count];
		[ctrl bulkMarkChannelsDeleteStatus:objectsToDelete];
	}
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
				// hide new user channels. they will appear again when, later, the "get channel video" task finds videos in them.
				if ( [chn.type integerValue] == NMChannelUserType ) {
					chn.nm_hidden = [NSNumber numberWithBool:YES];
				}
				if ( command == NMCommandCompareSubscribedChannels ) {
					// assign the new channel to YouTube group
					[ctrl.internalYouTubeCategory addChannelsObject:chn];
					numberOfRowsAdded++;
				}
			} else {
				// the channel already exists, just update the sort order.
				[chn setValuesForKeysWithDictionary:chnDict];
//				if ( [chnObj.nm_hidden boolValue] ) {
//					// update the channel info if the channel is hidden
//					[chn setValuesForKeysWithDictionary:chnDict];
//				}
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
		case NMCommandGetChannelWithID:
			return NMWillGetChannelWithIDNotification;
		case NMCommandGetFeaturedChannelsForCategories:
			return NMWillGetFeaturedCategoriesNotification;
		case NMCommandCompareSubscribedChannels:
			return NMWillCompareSubscribedChannelsNotification;
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
		case NMCommandGetChannelWithID:
			return NMDidGetChannelWithIDNotification;
		case NMCommandGetFeaturedChannelsForCategories:
			return NMDidGetFeaturedChannelsForCategories;
		case NMCommandCompareSubscribedChannels:
			return NMDidCompareSubscribedChannelsNotification;
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
		case NMCommandGetChannelWithID:
			return NMDidFailGetChannelWithIDNotification;
		case NMCommandGetFeaturedChannelsForCategories:
			return NMDidFailGetFeaturedCategoriesNotification;
		case NMCommandCompareSubscribedChannels:
			return NMDidFailCompareSubscribedChannelsNotification;
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
		case NMCommandGetFeaturedChannelsForCategories:
		{
			return [NSDictionary dictionaryWithObject:categoryIDs forKey:@"channels"];
		}
		case NMCommandGetSubscribedChannels:
		{
			return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:numberOfRowsAdded], @"num_channel_added", [NSNumber numberWithUnsignedInteger:numberOfRowsDeleted], @"num_channel_deleted", [NSNumber numberWithUnsignedInteger:numberOfRowsFromServer], @"total_channel", nil];
		}
		default:
			break;
	}
	return nil;
}

@end
