//
//  NMGetYouTubeDirectURLTask.m
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMGetYouTubeDirectURLTask.h"
#import "NMDataController.h"
#import "NMChannel.h"
#import "NMSubscription.h"
#import "NMVideo.h"
#import "NMConcreteVideo.h"
#import "NMVideoDetail.h"
#import "NMAuthor.h"

static NSString * const NMYouTubeUserAgent = @"Apple iPad v5.0 YouTube v1.0.0.9A5288d";
static NSString * const NMYouTubeMobileBrowserAgent = @"Mozilla/5.0 (iPad; CPU OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3";

NSString * const NMWillGetYouTubeDirectURLNotification = @"NMWillGetYouTubeDirectURLNotification";
NSString * const NMDidGetYouTubeDirectURLNotification = @"NMDidGetYouTubeDirectURLNotification";
NSString * const NMDidFailGetYouTubeDirectURLNotification = @"NMDidFailGetYouTubeDirectURLNotification";

NSString * const NMWillImportYouTubeVideoNotification = @"NMWillImportYouTubeVideoNotification";
NSString * const NMDidImportYouTubeVideoNotification = @"NMDidImportYouTubeVideoNotification";
NSString * const NMDidFailImportYouTubeVideoNotification = @"NMDidFailImportYouTubeVideoNotification";

@implementation NMGetYouTubeDirectURLTask

@synthesize video, externalID;
@synthesize directSDURLString, directURLString;
@synthesize videoInfoDict, authorDict;
@synthesize concreteVideo;

- (id)dateFromTimeCreatedString:(NSString *)dateStr {
	if ( dateStr == nil || [dateStr length] == 0 ) return [NSNull null];
	if ( timeCreatedFormatter == nil ) {
		timeCreatedFormatter = [[NSDateFormatter alloc] init];
		[timeCreatedFormatter setDateFormat:@"MMM dd, yyyy"];
		[timeCreatedFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
	}
	return [timeCreatedFormatter dateFromString:dateStr];
}

- (id)numberFromViewCountString:(NSString *)cntStr {
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
	self.externalID = vdo.video.external_id;
	self.targetID = vdo.video.nm_id;
	// the task saveProcessedDataInController: method will still be executed when there's resolution error
	executeSaveActionOnError = YES;
	
	return self;
}

- (id)initImportVideo:(NMConcreteVideo *)vdo {
	self = [super init];
	
	command = NMCommandImportYouTubeVideo;
	self.concreteVideo = vdo;
	self.externalID = vdo.external_id;
	self.targetID = vdo.nm_id;
#ifdef DEBUG_FACEBOOK_IMPORT
	NSLog(@"init import task: %@", self.externalID);
#endif
	// the task saveProcessedDataInController: method will still be executed when there's resolution error
	executeSaveActionOnError = YES;
	
	return self;
}

- (void)dealloc {
	[video release];
	[concreteVideo release];
	[externalID release];
	[directURLString release];
	[directSDURLString release];
	[authorDict release];
	[videoInfoDict release];
	[viewCountFormatter release];
	[timeCreatedFormatter release];
	[super dealloc];
}

- (NSInteger)commandIndex {
	NSInteger idx = 0;
	if ( command == NMCommandImportYouTubeVideo ) {
		// use custom command index method
		idx = ABS((NSInteger)[externalID hash]);
	} else {
		idx = [super commandIndex];
	}
	return idx;
}

- (NSURLRequest *)URLRequest {
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
	NSError * error = nil;
	NSDictionary * dict = [cleanResultStr objectFromJSONStringWithParseOptions:0 error:&error];
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
	if ( contentDict == nil || [contentDict count] == 0 ) {
		encountersErrorDuringProcessing = YES;
		self.errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"No video content", @"reason", [NSNumber numberWithInteger:NMErrorNoData], @"error_code", video, @"target_object", nil];
		return;
	}
	if ( command == NMCommandImportYouTubeVideo ) {
		NSDictionary * srcVdoDict = [contentDict objectForKey:@"video"];
		// the import process will first create the concrete video and video objects. There's no need to recreate them here
		// create author
		self.authorDict = [NSMutableDictionary dictionaryWithCapacity:4];
		[authorDict setObject:[srcVdoDict objectForKey:@"public_name"] forKey:@"username"];
		NSString * urlStr = [srcVdoDict objectForKey:@"profile_url"];
		NSRange rng = [urlStr rangeOfString:@"youtube.com"];
		if ( rng.location == NSNotFound ) {
			[authorDict setObject:[@"http://www.youtube.com" stringByAppendingString:[srcVdoDict objectForKey:@"profile_url"]] forKey:@"profile_uri"];
		} else {
			[authorDict setObject:[srcVdoDict objectForKey:@"profile_url"] forKey:@"profile_uri"];
		}
		// Feb 13, 2012. There's a bug in YouTube API. The attribute in JSOn is not a valid URL - //i1.ytimg.com/vi/HCIcms1RK3o/default.jpg
		NSString * usrThumbURLStr = [srcVdoDict objectForKey:@"user_image_url"];
		if ( usrThumbURLStr ) {
			rng = [usrThumbURLStr rangeOfString:@"//"];
			if ( rng.location == 0 ) {
				// it is affected by the bug
				usrThumbURLStr = [@"http:" stringByAppendingString:usrThumbURLStr];
			}
			[authorDict setObject:usrThumbURLStr forKey:@"thumbnail_uri"];
		}
		// save extra informaiton
		self.videoInfoDict = [NSMutableDictionary dictionaryWithCapacity:4];
		@try {
			[videoInfoDict setObject:[srcVdoDict objectForKey:@"title"] forKey:@"title"];
			[videoInfoDict setObject:[srcVdoDict objectForKey:@"length_seconds"] forKey:@"duration"];
			[videoInfoDict setObject:[self dateFromTimeCreatedString:[srcVdoDict objectForKey:@"time_created_text"]] forKey:@"published_at"];
			[videoInfoDict setObject:[self numberFromViewCountString:[srcVdoDict objectForKey:@"view_count"]] forKey:@"view_count"];
			[videoInfoDict setObject:[srcVdoDict objectForKey:@"thumbnail_for_watch"] forKey:@"thumbnail_uri"];
			[videoInfoDict setObject:[srcVdoDict objectForKey:@"description"] forKey:@"nm_description"];
		}
		@catch (NSException *exception) {
			// some attribute is probably null
		}
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
	NMConcreteVideo * targetVideo = nil;
	if ( video ) targetVideo = video.video;
	else if ( concreteVideo ) targetVideo = concreteVideo;
	if ( command == NMCommandImportYouTubeVideo ) {
		if ( encountersErrorDuringProcessing ) {
			// there's error in resolution, we should delete the video altogetheric
			//[ctrl deleteManagedObject:targetVideo];
#ifdef DEBUG_FACEBOOK_IMPORT
			NSLog(@"error importing video: %@\n%@", self.targetID, self.errorInfo);
#endif
		}
		if ( !encountersErrorDuringProcessing && videoInfoDict && authorDict ) {
			// detail Video
			NMVideoDetail * dtlObj = targetVideo.detail;
			if ( dtlObj == nil ) {
				dtlObj = [ctrl insertNewVideoDetail];
				targetVideo.detail = dtlObj;
			}
			dtlObj.nm_description = [videoInfoDict objectForKey:@"nm_description"];
			[videoInfoDict removeObjectForKey:@"nm_description"];
			targetVideo.nm_error = (NSNumber *)kCFBooleanFalse;
			// make the NMVideo object dirty so that FRC method will get notified
			for (NMVideo * vdo in targetVideo.channels) {
				vdo.nm_make_dirty = (NSNumber *)([vdo.nm_make_dirty boolValue] ? kCFBooleanFalse : kCFBooleanTrue);
			}
			// update Concrete Video
			[targetVideo setValuesForKeysWithDictionary:videoInfoDict];
			// author
			BOOL isNew;
			NMAuthor * arObj = [ctrl insertNewAuthorWithUsername:[authorDict objectForKey:@"username"] isNew:&isNew];
			if ( isNew ) {
				[arObj setValuesForKeysWithDictionary:authorDict];
			}
			targetVideo.author = arObj;
			// In some ways, setting the session here purposely make the NMVideo object dirty. Then, when we save the MOC, the NSFetchedResultsController that owns the channel video row will get notified for change.
			video.nm_session_id = NM_SESSION_ID;
		}
	}
	if ( encountersErrorDuringProcessing ) {
		if ( command == NMCommandImportYouTubeVideo ) {
			// just delete the video
			[ctrl deleteManagedObject:concreteVideo];
			self.concreteVideo = nil;
		} else {
			targetVideo.nm_direct_url = nil;
			targetVideo.nm_direct_sd_url = nil;
			if ( [targetVideo.nm_error integerValue] != NMErrorPendingImport ) {
				targetVideo.nm_error = [self.errorInfo objectForKey:@"error_code"];
			}
			targetVideo.nm_playback_status = NMVideoQueueStatusError;
		}
	} else {
		targetVideo.nm_direct_url = directURLString;
		targetVideo.nm_direct_sd_url = directSDURLString;
		targetVideo.nm_direct_url_expiry = expiryTime;
		targetVideo.nm_playback_status = NMVideoQueueStatusDirectURLReady;
#ifdef DEBUG_FACEBOOK_IMPORT
		NSLog(@"imported video successfully: %@, %@", externalID, [[targetVideo.channels anyObject] valueForKeyPath:@"channel.title"]);
#endif
	}
	return YES;
}

- (NSString *)willLoadNotificationName {
	if ( command == NMCommandImportYouTubeVideo ) {
		return NMWillImportYouTubeVideoNotification;
	}
	return NMWillGetYouTubeDirectURLNotification;
}

- (NSString *)didLoadNotificationName {
	if ( command == NMCommandImportYouTubeVideo ) {
		return NMDidImportYouTubeVideoNotification;
	}
	return NMDidGetYouTubeDirectURLNotification;
}

- (NSString *)didFailNotificationName {
	if ( command == NMCommandImportYouTubeVideo ) {
		return NMDidFailImportYouTubeVideoNotification;
	}
	return NMDidFailGetYouTubeDirectURLNotification;
}

- (NSDictionary *)userInfo {
	if ( encountersErrorDuringProcessing ) {
		return errorInfo;
	}
	NSDictionary * theDict;
	if ( command == NMCommandImportYouTubeVideo ) {
		theDict = directURLString ? [NSDictionary dictionaryWithObjectsAndKeys:concreteVideo, @"target_object", nil] : nil;
	} else {
		theDict = directURLString ? [NSDictionary dictionaryWithObjectsAndKeys:video, @"target_object", nil] : nil;
	}
	return theDict;
}

@end
