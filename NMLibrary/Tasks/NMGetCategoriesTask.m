//
//  NMGetCategoriesTask.m
//  ipad
//
//  Created by Bill So on 8/8/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "NMGetCategoriesTask.h"

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

- (NSMutableURLRequest *)URLRequest {
	NSString * urlStr = [NSString stringWithFormat:@"http://%@/categories?type=featured&user_id=%d", NM_BASE_URL, NM_USER_ACCOUNT_ID];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	return request;
}

- (void)processDownloadedDataInBuffer {
	// parse the "categories" JSON
	if ( [buffer length] == 0 ) return;
	NSArray * catAy = [buffer objectFromJSONData];
	
	if ( [catAy count] == 0 ) return;
	
	parsedObjects = [[NSMutableArray alloc] initWithCapacity:[catAy count]];
	NSMutableDictionary * nomCatDict;
	for (NSDictionary * cDict in catAy) {
		nomCatDict = [NSMutableDictionary dictionaryWithCapacity:3];
		[nomCatDict setObject:[cDict objectForKey:@"id"] forKey:@"nm_id"];
		[nomCatDict setObject:[cDict objectForKey:@"title"] forKey:@"title"];
	}
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	// what is the replacement strategy?
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
