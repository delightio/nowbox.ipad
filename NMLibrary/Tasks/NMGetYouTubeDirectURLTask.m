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
		self.errorInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:NMErrorNoData] forKey:@"error_code"];
		return;
	}
	if ( httpStatusCode >= 400 && httpStatusCode < 500 ) {
		// error in the youtube call
		// parse the XML document <code></code>, <internalReason></internalReason>
		NSString * xmlStr = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
		// look for <code> </code>
		NSRange beginRange = [xmlStr rangeOfString:@"<code>"];
		NSRange endRange = [xmlStr rangeOfString:@"</code>"];
		NSString * reason = [xmlStr substringWithRange:NSMakeRange(beginRange.location + beginRange.length, endRange.location - beginRange.location - beginRange.length)];
		if ( reason ) {
			self.errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:reason, @"reason", [NSNumber numberWithInteger:NMErrorYouTubeAPIError], @"error_code", nil];
		} else {
			self.errorInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:NMErrorYouTubeAPIError] forKey:@"error_code"];
		}
		encountersErrorDuringProcessing = YES;
		return;
	}
	NSDictionary * dict = [buffer objectFromJSONData];
	
	NSArray * mediaContents = [dict valueForKeyPath:@"entry.media$group.media$content"];
	if ( mediaContents == nil || [mediaContents count] == 0 ) {
		// no data
		encountersErrorDuringProcessing = YES;
		self.errorInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:NMErrorNoSupportedVideoFormat] forKey:@"error_code"];
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
		self.errorInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:NMErrorNoSupportedVideoFormat] forKey:@"error_code"];
		return;
	}
	
	if ( directSDURLString == nil ) {
		self.directSDURLString = mp4URLString;
	}
	if ( directURLString == nil ) {
		self.directURLString = directSDURLString;
	}

#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"resolved URL for %@: %@", self.targetID, [directURLString length] ? @"Y" : @"N");
#endif
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	if ( encountersErrorDuringProcessing ) {
#ifdef DEBUG_PLAYBACK_NETWORK_CALL
		NSLog(@"direct URL resolution failed: %@", video.title);
#endif
		video.nm_direct_url = nil;
		video.nm_direct_sd_url = nil;
		video.nm_error = [self.errorInfo objectForKey:@"error_code"];
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
