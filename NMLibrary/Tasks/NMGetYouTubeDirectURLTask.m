//
//  NMGetYouTubeDirectURLTask.m
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMGetYouTubeDirectURLTask.h"
#import "NMVideo.h"

static NSString * const NMYoutubeUserAgent = @"Mozilla/5.0 (iPad; U; CPU OS 4_2_1 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8C148 Safari/6533.18.5";

NSString * const NMWillGetYouTubeDirectURLNotification = @"NMWillGetYouTubeDirectURLNotification";
NSString * const NMDidGetYouTubeDirectURLNotification = @"NMDidGetYouTubeDirectURLNotification";
NSString * const NMDidFailGetYouTubeDirectURLNotification = @"NMDidFailGetYouTubeDirectURLNotification";

@implementation NMGetYouTubeDirectURLTask

@synthesize video, externalID, directURLString;

- (id)initWithVideo:(NMVideo *)vdo {
	self = [super init];
	
	command = NMCommandGetYouTubeDirectURL;
	self.video = vdo;
	self.externalID = vdo.external_id;
	
	return self;
}

- (void)dealloc {
	[video release];
	[externalID release];
	[directURLString release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSString * urlStr = [NSString stringWithFormat:@"http://m.youtube.com/watch?v=%@&xl=xl_blazer&ajax=1&tsp=1&tspv=v2&xl=xl_blazer", externalID];
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"%@", urlStr);
#endif
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	[request setValue:NMYoutubeUserAgent forHTTPHeaderField:@"User-Agent"];
	
	return request;
}

- (void)processDownloadedDataInBuffer {
	if ( [buffer length] == 0 ) {
		// the buffer is empty which should not happen
		encountersErrorDuringProcessing = YES;
		return;
	}
	NSString * resultString = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
	// remove odd begin pattern in the JSON source from Youtube
	NSString * cleanResultStr =[resultString stringByReplacingOccurrencesOfString:@")]}'" withString:@"" options:0 range:NSMakeRange(0, 5)];
	[resultString release];
	
	// get the JSON object
	NSDictionary * dict = [cleanResultStr objectFromJSONString];
	// check if there's error
	if ( ![dict isKindOfClass:[NSDictionary class]] ) {
		encountersErrorDuringProcessing = YES;
		return;
	}
	if ( [[dict objectForKey:@"result"] isEqualToString:@"error"] ) {
		encountersErrorDuringProcessing = YES;
		NSArray * ay = [dict objectForKey:@"errors"];
		if ( [ay count] ) {
			NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:[ay objectAtIndex:0], @"error", [NSNumber numberWithInteger:NMVideoDirectURLResolutionError], @"errorNum", video, @"target_object", nil];
			parsedObjects = [[NSArray alloc] initWithObjects:dict, nil];
		}
		return;
	}
	NSDictionary * contentDict = [dict objectForKey:@"content"];
	if ( contentDict == nil || [contentDict count] == 0) {
		encountersErrorDuringProcessing = YES;
		parsedObjects = [[NSArray alloc] initWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"No video content", @"error", [NSNumber numberWithInteger:NMVideoDirectURLResolutionError], @"errorNum", video, @"target_object", nil], nil];
		return;
	}
//	self.directURLString = [contentDict valueForKeyPath:@"video.hq_stream_url"];
	self.directURLString = [contentDict valueForKeyPath:@"video.stream_url"];
	if ( directURLString == nil ) {
		// error - we can't find the direct URL to video
		encountersErrorDuringProcessing = YES;
		NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:@"Cannot locate HQ video stream", @"error", [NSNumber numberWithInteger:NMVideoDirectURLResolutionError], @"errorNum", video, @"target_object", nil];
		parsedObjects = [[NSArray alloc] initWithObjects:dict, nil];
	} /*else {
		NSLog(@"resolved URL: %@", self.externalID);
	}*/
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	video.nm_direct_url = directURLString;
}

- (NSString *)willLoadNotificationName {
	return NMWillGetYouTubeDirectURLNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidGetYouTubeDirectURLNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailGetYouTubeDirectURLNotification;
}

- (NSDictionary *)userInfo {
	return directURLString ? [NSDictionary dictionaryWithObjectsAndKeys:video, @"target_object", nil] : nil;
}

@end
