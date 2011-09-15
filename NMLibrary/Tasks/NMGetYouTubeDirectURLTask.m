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
	// iPad 2 - iOS 5 beta 7
	[theRequest setValue:@"AIwbFAT0accx3e6XKYznJ2LT381D0m0Fa7TqecYLwbxO71jT6TSdtfWiY95oUVolh5eZnjxrbwv1zKP72bdcx6nLGxVReCnhollht3U7qTpaTBqK1UrsFOKAly82THFBjFkHQSAwolfuKHynjBGvnZMAD8Z8CWFs_muL1LvEfHgYglEhYiMbHJA" forHTTPHeaderField:@"X-YouTube-DeviceAuthToken"];
	// iPad 2 - iOS 5 beta 6
//	[theRequest setValue:@"AIwbFAQjxbfsHPW4wFXq838qenSQ6UwiR0Exv43nzSqVE47NxlgYNOTChJ1oSF7PIn0ACHcGtwR_AvuaQza6Dg69iMif8V8fd8iv2hve0SkTFSLHv8pDta3OnCXfC6R-9P-BVykR1bzG1s9DQ4qiNSxNaBhKftE9PtATiAJ_5HFa9gyRp0dF_SA" forHTTPHeaderField:@"X-YouTube-DeviceAuthToken"];
	// original in code base
//	[theRequest setValue:@"AIwbFASGaas2duSR08SqNNVkr8eQczFrT1oqHFMIZqnY67XXoDLeb12oUUV20bKALZJMqHCY-rGSOxbrkDdfgxX-cQ3dpWD7uTZfUk_TWxEIBmoXSd2Z_C7o-jzntFuWUnHfickQfiOIXErVr_4MqQ9Eoqlu0t2aY9f74A-nWYhQ54bOpyc9StM" forHTTPHeaderField:@"X-YouTube-DeviceAuthToken"];
	// iPad 1 - iOS 4
	// X-Youtube-Deviceauthtoken: AIwbFATQRBoJV9hoDwYIn39aWXnTrQ-AXtAUxv3Y5A1rUL5sQhC1ejd3TFkbAt54vH-doizadgX8EzEk9a8rsFM5cVBWal4CPpTMVs25fe4DbSOfyhZ3IyjCLE8lA0PUj26WRjz8A8cQHLuVIJrKrM6hn7O1e69u6ZwRiBAMuznVT6acCwP-Lcw\r\n
	// iPhone 4 - iOS 4
	// X-Youtube-Deviceauthtoken: AIwbFARWDLJN0LYiXyui9dq87-VqrwMUO2EdnIFBeYB8wNEykr9TWImjnGeI9UWb54FS1iNhxC_4jChJPekAi-Q94LB-jxDuVbnvlXa2EEvPaqN6dnwVH_d5jGY6Ea1uu6yDXnYDSCJgcH2a9pvNZcPrkUo83ZpcMdObCP_0kfzo62eO-LxfKvc\r\n
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
