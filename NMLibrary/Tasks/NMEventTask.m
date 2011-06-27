//
//  NMEventTask.m
//  ipad
//
//  Created by Bill So on 06/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMEventTask.h"
#import "NMVideo.h"

NSString * const NMDidFailSendEventNotification = @"NMDidFailSendEventNotification";

@implementation NMEventTask

@synthesize video, duration;
@synthesize elapsedSeconds, playedToEnd;
@synthesize errorCode;

- (id)initWithEventType:(NMEventType)evtType forVideo:(NMVideo *)v {
	self = [super init];
	
	self.video = v;
	// grab values in the video object to be used in the thread
	videoID = [v.nm_id integerValue];
	eventType = evtType;
	
	return self;
}

- (void)dealloc {
	[video release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSString * evtStr;
	switch (eventType) {
		case NMEventUpVote:
			evtStr = @"upvote";
			break;
		case NMEventDownVote:
			evtStr = @"downvote";
			break;
		case NMEventRewind:
			evtStr = @"rewind";
			break;
		case NMEventShare:
			evtStr = @"share";
			break;
		case NMEventView:
			evtStr = @"view";
			break;
		case NMEventViewing:
			evtStr = @"viewing";
		case NMEventReexamine:
			evtStr = @"reexamine_video";
			break;
	}
	NSString * urlStr = nil;
	if ( eventType == NMEventReexamine ) {
		urlStr = [NSString stringWithFormat:@"http://%@/events/track?video_id=%d&event_type=%@&error_code=%d&user_id=%d", NM_BASE_URL, videoID, evtStr, errorCode, NM_USER_ACCOUNT_ID];
	} else {
		urlStr = [NSString stringWithFormat:@"http://%@/events/track?video_id=%d&elapsed_seconds=%f&duration=%f&event_type=%@&trigger_name=%@&user_id=%d", NM_BASE_URL, videoID, elapsedSeconds, duration, evtStr, eventType == NMEventView && playedToEnd ? @"auto" : @"touch", NM_USER_ACCOUNT_ID];
	}
#ifdef DEBUG_EVENT_TRACKING
	NSLog(@"send event: %@", urlStr);
#endif
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	
	return request;
}

- (void)processDownloadedDataInBuffer {
	if ( [buffer length] == 0 ) return;
	NSString * str = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
	NSDictionary * dict = [str objectFromJSONString];
	[str release];
	
	if ( ![[dict objectForKey:@"status"] isEqualToString:@"OK"] ) {
		encountersErrorDuringProcessing = YES;
	}
}

- (NSString *)didFailNotificationName {
	return NMDidFailSendEventNotification;
}

@end
