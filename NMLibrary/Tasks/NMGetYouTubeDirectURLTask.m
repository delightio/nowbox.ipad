//
//  NMGetYouTubeDirectURLTask.m
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMGetYouTubeDirectURLTask.h"
#import "NMVideo.h"

static NSString * const NMYouTubeUserAgent = @"Apple iPad v5.0 YouTube v1.0.0.9A5288d";
static NSString * const NMYouTubeMobileBrowserAgent = @"Mozilla/5.0 (iPad; CPU OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3";

NSString * const NMWillGetYouTubeDirectURLNotification = @"NMWillGetYouTubeDirectURLNotification";
NSString * const NMDidGetYouTubeDirectURLNotification = @"NMDidGetYouTubeDirectURLNotification";
NSString * const NMDidFailGetYouTubeDirectURLNotification = @"NMDidFailGetYouTubeDirectURLNotification";

static NSNumberFormatter * viewCountFormatter = nil;
static NSDateFormatter * timeCreatedFormatter = nil;

@implementation NMGetYouTubeDirectURLTask

@synthesize video, externalID;
@synthesize directSDURLString, directURLString;

+ (id)dateFromTimeCreatedString:(NSString *)dateStr {
	if ( dateStr == nil || [dateStr length] == 0 ) return [NSNull null];
	if ( timeCreatedFormatter == nil ) {
		timeCreatedFormatter = [[NSDateFormatter alloc] init];
		[timeCreatedFormatter setDateFormat:@"MMM dd, yyyy"];
		[timeCreatedFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
	}
	return [timeCreatedFormatter dateFromString:dateStr];
}

+ (id)numberFromViewCountString:(NSString *)cntStr {
	if ( cntStr == nil || [cntStr length] == 0 ) return [NSNull null];
	if ( viewCountFormatter == nil ) {
		viewCountFormatter = [[NSNumberFormatter alloc] init];
		[viewCountFormatter setPositiveFormat:@"#,###"];
		[viewCountFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease]];
	}
	return [viewCountFormatter numberFromString:cntStr];
}

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
	NSString * urlStr;
	NSMutableURLRequest * theRequest;
	urlStr = [NSString stringWithFormat:@"http://m.youtube.com/watch?ajax=1&layout=tablet&tsp=1&v=%@", externalID];
	theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
	[theRequest setValue:@"*/*" forHTTPHeaderField:@"Accept"];
	[theRequest setValue:@"en-us" forHTTPHeaderField:@"Accept-Language"];
	[theRequest setValue:NMYouTubeMobileBrowserAgent forHTTPHeaderField:@"User-Agent"];
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
	NSString * resultString = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
	// remove odd begin pattern in the JSON source from YouTube
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
			self.errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:[ay objectAtIndex:0], @"reason", [NSNumber numberWithInteger:NMErrorYouTubeAPIError], @"error_code", video, @"target_object", nil];
		}
		return;
	}
	NSDictionary * contentDict = [dict objectForKey:@"content"];
	if ( contentDict == nil || [contentDict count] == 0) {
		encountersErrorDuringProcessing = YES;
		self.errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"No video content", @"reason", [NSNumber numberWithInteger:NMErrorNoData], @"error_code", video, @"target_object", nil];
		return;
	}
	if ( command == NMCommandGetYouTubeDirectURLAndInfo ) {
		// create video and author
		// save extra informaiton
		NSDictionary * srcVdoDict = [contentDict objectForKey:@"video"];
		NSMutableDictionary * theVdoDict = [NSMutableDictionary dictionaryWithCapacity:4];
		[theVdoDict setObject:[srcVdoDict objectForKey:@"length_seconds"] forKey:@"duration"];
		[theVdoDict setObject:[NMGetYouTubeDirectURLTask dateFromTimeCreatedString:[srcVdoDict objectForKey:@"time_created_text"]] forKey:@"published_at"];
		[theVdoDict setObject:[NMGetYouTubeDirectURLTask numberFromViewCountString:[srcVdoDict objectForKey:@"view_count"]] forKey:@"view_count"];
		[theVdoDict setObject:[srcVdoDict objectForKey:@"thumbnail_for_watch"] forKey:@"thumbnail_uri"];
	}
	self.directURLString = [contentDict valueForKeyPath:@"video.hq_stream_url"];
	self.directSDURLString = [contentDict valueForKeyPath:@"video.stream_url"];
	NSUInteger dlen, dsdlen;
	dlen = [directURLString length];
	dsdlen = [directSDURLString length];
	NSString * urlStr = directURLString;
	if ( dlen == 0 && dsdlen == 0 ) {
		// error - we can't find the direct URL to video
		encountersErrorDuringProcessing = YES;
		self.errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Cannot locate any video stream", @"reason", [NSNumber numberWithInteger:NMErrorNoSupportedVideoFormat], @"error_code", video, @"target_object", nil];
	} else if ( dlen == 0 && dsdlen ) {
		self.directURLString = directSDURLString;
		urlStr = directSDURLString;
	} else if ( dlen && dsdlen == 0 ) {
		self.directSDURLString = directURLString;
	}
	// parse with regular expressing
	if ( dlen || dsdlen ) {
		NSError *error = nil;
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(?<=expire\\=)\\d+" options:NSRegularExpressionCaseInsensitive error:&error];
		NSRange rng = [regex rangeOfFirstMatchInString:urlStr options:0 range:NSMakeRange(0, [urlStr length])];
		if ( rng.location != NSNotFound ) {
			// we have the expiry timestamp
			expiryTime = (NSUInteger)[[urlStr substringWithRange:rng] integerValue];
		}
	}

#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"resolved URL for %@: %@", self.targetID, [directURLString length] ? @"Y" : [NSString stringWithFormat:@"N - %d", encountersErrorDuringProcessing]);
	if ( [directURLString length] == 0 ) {
		NSLog(@"video is f up");
	}
#endif
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	if ( command == NMCommandGetYouTubeDirectURLAndInfo ) {
		// 
	}
	if ( encountersErrorDuringProcessing ) {
		NSLog(@"direct URL resolution failed: %@", video.title);
		video.nm_direct_url = nil;
		video.nm_direct_sd_url = nil;
		video.nm_error = [self.errorInfo objectForKey:@"error_code"];
		video.nm_playback_status = NMVideoQueueStatusError;
	} else {
		video.nm_direct_url = directURLString;
		video.nm_direct_sd_url = directSDURLString;
		video.nm_direct_url_expiry = expiryTime;
		video.nm_playback_status = NMVideoQueueStatusDirectURLReady;
	}
	return NO;
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
	if ( encountersErrorDuringProcessing ) {
		return errorInfo;
	}
	return directURLString ? [NSDictionary dictionaryWithObjectsAndKeys:video, @"target_object", nil] : nil;
}

@end
