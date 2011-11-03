//
//  NMGetCategoriesTask.m
//  ipad
//
//  Created by Bill So on 8/8/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "NMGetCategoriesTask.h"
#import "NMDataController.h"
#import "NMCategory.h"

NSString * const NMWillGetFeaturedCategoriesNotification = @"NMWillGetFeaturedCategoriesNotification";
NSString * const NMDidGetFeaturedCategoriesNotification = @"NMDidGetFeaturedCategoriesNotification";
NSString * const NMDidFailGetFeaturedCategoriesNotification = @"NMDidFailGetFeaturedCategoriesNotification";

@implementation NMGetCategoriesTask

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
		command = NMCommandGetFeaturedCategories;
    }
    
    return self;
}

- (void)dealloc {
	[serverCategoryIDIndexSet release];
	[categoryDictionary release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSString * urlStr = nil;
	if ( NM_USER_ACCOUNT_ID ) {
		urlStr = [NSString stringWithFormat:@"http://%@/categories?type=featured&user_id=%d", NM_BASE_URL, NM_USER_ACCOUNT_ID];
	} else {
		urlStr = [NSString stringWithFormat:@"http://%@/categories?type=featured", NM_BASE_URL];
	}
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	return request;
}

- (void)processDownloadedDataInBuffer {
	// parse the "categories" JSON
	if ( [buffer length] == 0 ) return;
	NSArray * catAy = [buffer objectFromJSONData];
	
	if ( [catAy count] == 0 ) return;
	
	categoryDictionary = [[NSMutableDictionary alloc] initWithCapacity:[catAy count]];
	serverCategoryIDIndexSet = [[NSMutableIndexSet alloc] init];
	NSMutableDictionary * nomCatDict;
	NSDictionary * contentDict;
	NSNumber * catNum = nil;
	NSInteger i = 0;
	for (NSDictionary * cDict in catAy) {
		for (NSString * rKey in cDict) {			// attribute key cleanser
			contentDict = [cDict objectForKey:rKey];
			nomCatDict = [NSMutableDictionary dictionaryWithCapacity:3];
			catNum = [contentDict objectForKey:@"id"];
			[nomCatDict setObject:catNum forKey:@"nm_id"];
			[nomCatDict setObject:[NSNumber numberWithInteger:i++] forKey:@"nm_sort_order"];
			[nomCatDict setObject:[contentDict objectForKey:@"title"] forKey:@"title"];
			[serverCategoryIDIndexSet addIndex:[catNum unsignedIntegerValue]];
			[categoryDictionary setObject:nomCatDict forKey:catNum];
		}
	}
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	// get all categories in core data
	// check if the local cache complies with the new set from server
	NSArray * allCategories = ctrl.categories;
	NSMutableArray * objectsToDelete = nil;
	NSDictionary * catDict;
	NSUInteger cid;
	NMCategory * cat;
	for (cat in allCategories) {
		cid = [cat.nm_id unsignedIntegerValue];
		if ( [serverCategoryIDIndexSet containsIndex:cid] ) {
			// the category already exists
			catDict = [categoryDictionary objectForKey:cat.nm_id];
			// only update the sorting order
			cat.nm_sort_order = [catDict objectForKey:@"nm_sort_order"];
			cat.title = [catDict objectForKey:@"title"];
			[serverCategoryIDIndexSet removeIndex:cid];
		} else {
			// remove the item
			if ( objectsToDelete == nil ) objectsToDelete = [NSMutableArray arrayWithCapacity:4];
			[objectsToDelete addObject:cat];
		}
	}
	// delete objects
	if ( objectsToDelete ) [ctrl batchDeleteCategories:objectsToDelete];
	// handle the remaining index
	[serverCategoryIDIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		NSDictionary * dict = [categoryDictionary objectForKey:[NSNumber numberWithInteger:idx]];
		NMCategory * cat = [ctrl insertNewCategoryForID:[dict objectForKey:@"nm_id"]];
		[cat setValuesForKeysWithDictionary:dict];
	}];
	return NO;
}

- (NSString *)willLoadNotificationName {
	return NMWillGetFeaturedCategoriesNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidGetFeaturedCategoriesNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailGetFeaturedCategoriesNotification;
}

@end
