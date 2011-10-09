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
static NSString * const NMYoutubeMobileBrowserAgent = @"Mozilla/5.0 (iPad; CPU OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3";

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
	NSString * urlStr;
	NSMutableURLRequest * theRequest;
	if ( NM_YOUTUBE_MOBILE_BROWSER_RESOLUTION ) {
		urlStr = [NSString stringWithFormat:@"http://m.youtube.com/watch?ajax=1&layout=tablet&tsp=1&v=%@", externalID];
		theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
		[theRequest setValue:@"*/*" forHTTPHeaderField:@"Accept"];
		[theRequest setValue:@"en-us" forHTTPHeaderField:@"Accept-Language"];
		[theRequest setValue:NMYoutubeMobileBrowserAgent forHTTPHeaderField:@"User-Agent"];
	} else {
		urlStr = [NSString stringWithFormat:@"http://gdata.youtube.com/feeds/api/videos/%@?alt=json&format=2,3,8,9", externalID];
		theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
		
		[theRequest setValue:NMYoutubeUserAgent forHTTPHeaderField:@"User-Agent"];
		[theRequest setValue:@"*/*" forHTTPHeaderField:@"Accept"];
		[theRequest setValue:@"en-us,en;q=0.5" forHTTPHeaderField:@"Accept-Language"];
		[theRequest setValue:@"2" forHTTPHeaderField:@"GData-Version"];
		[theRequest setValue:@"ytapi-apple-ipad" forHTTPHeaderField:@"X-GData-Client"];
		// iPad 2 - iOS 5 beta 7
		[theRequest setValue:@"AIwbFAQnQEpiZxQ0Payjh_yBYxYpu1_blFsXxw4CuiDFAFczVD-1N2Ibmo6k-8zezbXMO36Dt6Y1lUmeAtA21Hd1vIcywt9l4M4rEfe7xA-nGB4ASOC8T_-2IO6yUs3hMJXjKwdtlrOy2-WBbSq50MYSZaq3D3FIsnlo04fSlooMK0PxhCckM1k" forHTTPHeaderField:@"X-YouTube-DeviceAuthToken"];
	}
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
	if ( NM_YOUTUBE_MOBILE_BROWSER_RESOLUTION ) {
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
		self.directURLString = [contentDict valueForKeyPath:@"video.hq_stream_url"];
		self.directSDURLString = [contentDict valueForKeyPath:@"video.stream_url"];
		if ( directURLString == nil && directSDURLString == nil ) {
			// error - we can't find the direct URL to video
			encountersErrorDuringProcessing = YES;
			self.errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Cannot locate any video stream", @"reason", [NSNumber numberWithInteger:NMErrorNoSupportedVideoFormat], @"error_code", video, @"target_object", nil];
		} else if ( directURLString == nil && directSDURLString ) {
			self.directURLString = directSDURLString;
		}
	} else {
		if ( httpStatusCode >= 400 && httpStatusCode < 500 ) {
			// error in the youtube call
			// parse the XML document <code></code>, <internalReason></internalReason>
			NSString * xmlStr = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
			// look for <code> </code>
			NSRange beginRange = [xmlStr rangeOfString:@"<code>"];
			NSRange endRange = [xmlStr rangeOfString:@"</code>"];
			NSString * reason = nil;
			if ( !beginRange.location == NSNotFound && !endRange.location == NSNotFound ) {
				reason = [xmlStr substringWithRange:NSMakeRange(beginRange.location + beginRange.length, endRange.location - beginRange.location - beginRange.length)];
			}
			if ( reason ) {
				self.errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:video, @"target_object", reason, @"reason", [NSNumber numberWithInteger:NMErrorYouTubeAPIError], @"error_code", nil];
			} else if ( [xmlStr rangeOfString:@"Device token expired"].location != NSNotFound ) {
				self.errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:video, @"target_object", [NSNumber numberWithInteger:NMErrorDeviceTokenExpired], @"error_code", @"Device token expired", @"reason", nil];
			} else {
				self.errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:video, @"target_object", [NSNumber numberWithInteger:NMErrorYouTubeAPIError], @"error_code", nil];
			}
			encountersErrorDuringProcessing = YES;
			return;
		}
		NSDictionary * dict = [buffer objectFromJSONData];
		
		NSArray * mediaContents = [dict valueForKeyPath:@"entry.media$group.media$content"];
		if ( mediaContents == nil || [mediaContents count] == 0 ) {
			// no data
			encountersErrorDuringProcessing = YES;
			NSDictionary * ytStateDict = [dict valueForKeyPath:@"entry.app$control.yt$state"];
			if ( ytStateDict ) {
				self.errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:video, @"target_object", [NSNumber numberWithInteger:NMErrorYouTubeAPIError], @"error_code", [ytStateDict objectForKey:@"reasonCode"], @"reason", nil];
			} else {
				self.errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:video, @"target_object", [NSNumber numberWithInteger:NMErrorNoSupportedVideoFormat], @"error_code", nil];
			}
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
			self.errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:video, @"target_object", [NSNumber numberWithInteger:NMErrorNoSupportedVideoFormat], @"error_code", nil];
			return;
		}
		
		if ( directSDURLString == nil ) {
			self.directSDURLString = mp4URLString;
		}
		if ( directURLString == nil ) {
			self.directURLString = directSDURLString;
		}
	}

#ifdef DEBUG_PLAYBACK_NETWORK_CALL
	NSLog(@"resolved URL for %@: %@", self.targetID, [directURLString length] ? @"Y" : @"N");
#endif
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
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
