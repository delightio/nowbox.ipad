//
//  NMEventTask.m
//  ipad
//
//  Created by Bill So on 06/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMEventTask.h"
#import "NMChannel.h"
#import "NMVideo.h"

NSString * const NMDidFailSendEventNotification = @"NMDidFailSendEventNotification";

NSString * const NMWillSubscribeChannelNotification = @"NMWillSubscribeChannelNotification";
NSString * const NMDidSubscribeChannelNotification = @"NMDidSubscribeChannelNotification";
NSString * const NMDidFailSubscribeChannelNotification = @"NMDidFailSubscribeChannelNotification";
NSString * const NMWillUnsubscribeChannelNotification = @"NMWillUnsubscribeChannelNotification";
NSString * const NMDidUnsubscribeChannelNotification = @"NMDidUnsubscribeChannelNotification";
NSString * const NMDidFailUnsubscribeChannelNotification = @"NMDidFailUnsubscribeChannelNotification";

@implementation NMEventTask

@synthesize channel, video;
@synthesize channelID;
@synthesize resultDictionary;
@synthesize elapsedSeconds, playedToEnd;
@synthesize errorCode;

- (id)initWithEventType:(NMEventType)evtType forVideo:(NMVideo *)v {
	self = [super init];
	
	command = NMCommandSendEvent;
	self.video = v;
	// grab values in the video object to be used in the thread
	self.targetID = v.nm_id;
	self.channelID = [video valueForKeyPath:@"channel.nm_id"];
	eventType = evtType;
	
	return self;
}

- (id)initWithChannel:(NMChannel *)aChn subscribe:(BOOL)abool {
	self = [super init];
	
	command = NMCommandSendEvent;
	// if YES, subscribe. Otherwise, unsubscribe
	if ( abool ) {
		// subscribe
		eventType = NMEventSubscribeChannel;
	} else {
		eventType = NMEventUnsubscribeChannel;
	}
	self.channel = aChn;
	self.targetID = aChn.nm_id;
	
	return self;
}

- (void)dealloc {
	[channelID release];
	[channel release];
	[video release];
	[super dealloc];
}

- (NSUInteger)commandIndex {
	if ( targetID ) {
		NSUInteger tid = [self.targetID unsignedIntegerValue];
		return tid << 9 | eventType << 5 | (NSUInteger)command;
	}
	return (NSUInteger)command;
}

- (NSMutableURLRequest *)URLRequest {
	NSString * evtStr;
	switch (eventType) {
		case NMEventSubscribeChannel:
			evtStr = @"subscribe";
			break;
		case NMEventUnsubscribeChannel:
			evtStr = @"unsubscribe";
			break;
		case NMEventEnqueue:
			evtStr = @"enqueue";
			break;
		case NMEventDequeue:
			evtStr = @"dequeue";
			break;
		case NMEventShare:
			evtStr = @"share";
			break;
		case NMEventView:
			evtStr = @"view";
			break;
		case NMEventExamine:
			evtStr = @"examine";
			break;
	}
	NSString * urlStr = nil;
	switch (eventType) {
		case NMEventExamine:
			urlStr = [NSString stringWithFormat:@"http://%@/events?channel_id=%@&video_id=%@&action=%@&user_id=%d", NM_BASE_URL, channelID, targetID, evtStr, NM_USER_ACCOUNT_ID];
			break;
		case NMEventSubscribeChannel:
		case NMEventUnsubscribeChannel:
			urlStr = [NSString stringWithFormat:@"http://%@/events?channel_id=%@&action=%@&user_id=%d", NM_BASE_URL, targetID, evtStr, NM_USER_ACCOUNT_ID];
			break;
			
		default:
			urlStr = [NSString stringWithFormat:@"http://%@/events?channel_id=%@&video_id=%@&video_elapsed=%d&action=%@&user_id=%d", NM_BASE_URL, channelID, targetID, elapsedSeconds, evtStr, NM_USER_ACCOUNT_ID];
			break;
	}
#ifdef DEBUG_EVENT_TRACKING
	NSLog(@"send event: %@", urlStr);
#endif
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	[request setHTTPMethod:@"POST"];
	
	return request;
}

- (void)processDownloadedDataInBuffer {
	if ( [buffer length] == 0 ) return;
	self.resultDictionary = [buffer objectFromJSONData];
#ifdef DEBUG_EVENT_TRACKING
	NSLog(@"did post event: %@", resultDictionary);
#endif
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	switch (eventType) {
		case NMEventSubscribeChannel:
			channel.nm_subscribed = [NSNumber numberWithBool:YES];
			break;
		case NMEventUnsubscribeChannel:
			channel.nm_subscribed = [NSNumber numberWithBool:NO];
			break;
		case NMEventEnqueue:
			//TODO: add video to "watch later" channel
			break;
		case NMEventDequeue:
			//TODO: remove video to "watch later" channel
			break;
			
		default:
			break;
	}
}

- (NSString *)willLoadNotificationName {
	switch (eventType) {
		case NMEventSubscribeChannel:
			return NMWillSubscribeChannelNotification;
		case NMEventUnsubscribeChannel:
			return NMWillUnsubscribeChannelNotification;
			
		default:
			break;
	}
	return nil;
}

- (NSString *)didLoadNotificationName {
	switch (eventType) {
		case NMEventSubscribeChannel:
			return NMDidSubscribeChannelNotification;
		case NMEventUnsubscribeChannel:
			return NMDidUnsubscribeChannelNotification;
			
		default:
			break;
	}
	return nil;
}

- (NSString *)didFailNotificationName {
	switch (eventType) {
		case NMEventSubscribeChannel:
			return NMDidFailSubscribeChannelNotification;
		case NMEventUnsubscribeChannel:
			return NMDidFailUnsubscribeChannelNotification;
			
		default:
			break;
	}
	return NMDidFailSendEventNotification;
}

- (NSDictionary *)userInfo {
	switch (eventType) {
		case NMEventSubscribeChannel:
		case NMEventUnsubscribeChannel:
			return [NSDictionary dictionaryWithObject:channel forKey:@"channel"];
			break;
			
		default:
			break;
	}
	return nil;
}

@end
