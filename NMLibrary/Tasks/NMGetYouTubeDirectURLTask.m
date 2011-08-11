//
//  NMGetYouTubeDirectURLTask.m
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMGetYouTubeDirectURLTask.h"
#import "NMVideo.h"

static NSString * const NMYoutubeUserAgent = @"Apple iPad v5.0 YouTube v1.0.0.9A5288d";

NSString * const NMWillGetYouTubeDirectURLNotification = @"NMWillGetYouTubeDirectURLNotification";
NSString * const NMDidGetYouTubeDirectURLNotification = @"NMDidGetYouTubeDirectURLNotification";
NSString * const NMDidFailGetYouTubeDirectURLNotification = @"NMDidFailGetYouTubeDirectURLNotification";

@implementation NMGetYouTubeDirectURLTask

@synthesize video, externalID;
@synthesize directSDURLString, directURLString;

- (id)initWithVideo:(NMVideo *)vdo {
	self = [super init];
	
	command = NMCommandGetYouTubeDirectURL;
	self.video = vdo;
	self.externalID = vdo.external_id;
	self.targetID = vdo.nm_id;
	// the task saveProcessedDataInController: method will still be executed when there's resolution error
	executeSaveActionOnError = YES;
	
	return self;
}

- (void)dealloc {
	[video release];
	[externalID release];
	[directURLString release];
	[directSDURLString release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSString * urlStr = [NSString stringWithFormat:@"http://gdata.youtube.com/feeds/api/videos/%@?alt=json&format=2,3,8,9", externalID];
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"%@", urlStr);
#endif
	NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
	
	[theRequest setValue:NMYoutubeUserAgent forHTTPHeaderField:@"User-Agent"];
	[theRequest setValue:@"*/*" forHTTPHeaderField:@"Accept"];
	[theRequest setValue:@"en-us,en;q=0.5" forHTTPHeaderField:@"Accept-Language"];
	[theRequest setValue:@"2" forHTTPHeaderField:@"GData-Version"];
	[theRequest setValue:@"ytapi-apple-ipad" forHTTPHeaderField:@"X-GData-Client"];
	[theRequest setValue:@"AIwbFASGaas2duSR08SqNNVkr8eQczFrT1oqHFMIZqnY67XXoDLeb12oUUV20bKALZJMqHCY-rGSOxbrkDdfgxX-cQ3dpWD7uTZfUk_TWxEIBmoXSd2Z_C7o-jzntFuWUnHfickQfiOIXErVr_4MqQ9Eoqlu0t2aY9f74A-nWYhQ54bOpyc9StM" forHTTPHeaderField:@"X-YouTube-DeviceAuthToken"];
	[theRequest setValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];

	return theRequest;
}

- (void)processDownloadedDataInBuffer {
	if ( [buffer length] == 0 ) {
		// the buffer is empty which should not happen
		encountersErrorDuringProcessing = YES;
		return;
	}
	NSDictionary * dict = [buffer objectFromJSONData];
	
	NSArray * mediaContents = [dict valueForKeyPath:@"entry.media$group.media$content"];
	if ( mediaContents == nil || [mediaContents count] == 0 ) {
		// no data
		encountersErrorDuringProcessing = YES;
		return;
	}
	// get the MP4 link
	NSString * mp4URLString = nil;
	NSInteger ytFormat = 0;
	for (NSDictionary * vdoDict in mediaContents) {
		if ( [[vdoDict objectForKey:@"type"] isEqual:@"video/mp4"] ) {
			ytFormat = [[vdoDict objectForKey:@"yt$format"] integerValue];
			switch (ytFormat) {
				case 3:
					self.directSDURLString = [vdoDict objectForKey:@"url"];
					break;
				case 8:
					self.directURLString = [vdoDict objectForKey:@"url"];
					break;
				default:
					mp4URLString = [vdoDict objectForKey:@"url"];
					break;
			}
		}
	}
	
	if ( ytFormat == 0 ) {
		// can't find the MP4 URL
		encountersErrorDuringProcessing = YES;
	}
	
	if ( directSDURLString == nil ) {
		self.directSDURLString = mp4URLString;
	}
	if ( directURLString == nil ) {
		self.directURLString = directSDURLString;
	}

#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"resolved URL for %@: %@", self.targetID, directURLString);
#endif
}
/*
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
			parsedObjects = [[NSMutableArray alloc] initWithObjects:dict, nil];
		}
		return;
	}
	NSDictionary * contentDict = [dict objectForKey:@"content"];
	if ( contentDict == nil || [contentDict count] == 0) {
		encountersErrorDuringProcessing = YES;
		parsedObjects = [[NSMutableArray alloc] initWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"No video content", @"error", [NSNumber numberWithInteger:NMVideoDirectURLResolutionError], @"errorNum", video, @"target_object", nil], nil];
		return;
	}
	self.directURLString = [contentDict valueForKeyPath:@"video.hq_stream_url"];
	self.directSDURLString = [contentDict valueForKeyPath:@"video.stream_url"];
	if ( directURLString == nil && directSDURLString == nil ) {
		// error - we can't find the direct URL to video
		encountersErrorDuringProcessing = YES;
		NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:@"Cannot locate HQ video stream", @"error", [NSNumber numberWithInteger:NMVideoDirectURLResolutionError], @"errorNum", video, @"target_object", nil];
		parsedObjects = [[NSMutableArray alloc] initWithObjects:dict, nil];
	} else if ( directURLString == nil && directSDURLString ) {
		self.directURLString = directSDURLString;
	}
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	else {
		NSLog(@"resolved URL: %@", self.targetID);
	}
#endif
}
*/
- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	if ( encountersErrorDuringProcessing ) {
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
		NSLog(@"direct URL resolution failed: %@", video.title);
#endif
		video.nm_direct_url = nil;
		video.nm_direct_sd_url = nil;
		video.nm_error = [self.errorInfo objectForKey:@"errorNum"];
		video.nm_playback_status = NMVideoQueueStatusError;
	} else {
		video.nm_direct_url = directURLString;
		video.nm_direct_sd_url = directSDURLString;
	}
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
