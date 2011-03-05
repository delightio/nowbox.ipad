//
//  NMGetChannelsTask.m
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMGetChannelsTask.h"
#import "JSONKit.h"


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
	if ( [buffer length] == 0 ) return;
	NSString * str = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
	NSDictionary * dict = [str objectFromJSONString];
	
	
	
	return nil;
}

@end
