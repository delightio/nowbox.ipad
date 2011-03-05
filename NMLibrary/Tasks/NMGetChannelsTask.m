//
//  NMGetChannelsTask.m
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMGetChannelsTask.h"
#import "JSONKit.h"


NSString * const NMWillGetChannelsNotification = @"NMWillGetChannelsNotification";
NSString * const NMDidGetChannelsNotification = @"NMDidGetChannelsNotification";

@implementation NMGetChannelsTask

- (id)init {
	self = [super init];
	command = NMCommandGetChannels;
	return self;
}

- (NSMutableURLRequest *)URLRequest {
	NSString * urlStr = @"http://nowmov.com/channel/listings/recommended";
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	
	return request;
}

- (id)processDownloadedDataInBuffer {
	// parse JSON
	if ( [buffer length] == 0 ) return nil;
	NSString * str = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
	NSDictionary * dict = [str objectFromJSONString];
	
	if ( [self checkDictionaryContainsError:dict] ) {
		return parsedObjects;
	}
	
	NSArray * theChs = [dict objectForKey:@"channel_list"];
	parsedObjects = [[NSMutableArray alloc] init];
	NSDictionary * cDict;
	NSMutableDictionary * pDict;
	for (cDict in theChs) {
		pDict = [NSMutableDictionary dictionaryWithDictionary:cDict];
		[pDict setObject:[cDict objectForKey:@"description"] forKey:@"nm_description"];
		[parsedObjects addObject:pDict];
	}
	
	return parsedObjects;
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	// save the data into core data
	
}

- (NSString *)willLoadNotificationName {
	return NMWillGetChannelsNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidGetChannelsNotification;
}

@end
