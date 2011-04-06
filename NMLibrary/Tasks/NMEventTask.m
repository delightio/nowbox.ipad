//
//  NMEventTask.m
//  ipad
//
//  Created by Bill So on 06/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMEventTask.h"
#import "NMVideo.h"


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
	NSString * urlStr = [NSString stringWithFormat:@"http://nowmov.com/events/track?video_id=%d&elapsed_seconds=%f&duration=%f&event_type=%d&trigger_name=touch", videoID, elapsedSeconds, duration, eventType];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	
	return request;
}

@end
