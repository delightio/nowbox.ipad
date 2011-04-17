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

@synthesize video, duration, elapsedSeconds;

- (id)initWithEventType:(NMEventType)evtType forVideo:(NMVideo *)v {
	self = [super init];
	
	self.video = v;
	// grab values in the video object to be used in the thread
	videoID = [v.vid integerValue];
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
	}
	NSString * urlStr = [NSString stringWithFormat:@"http://nowmov.com/events/track?video_id=%d&elapsed_seconds=%f&duration=%f&event_type=%@&trigger_name=touch", videoID, elapsedSeconds, duration, evtStr];
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
