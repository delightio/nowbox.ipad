//
//  NMEventTask.m
//  ipad
//
//  Created by Bill So on 06/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMEventTask.h"
#import "NMDataController.h"
#import "NMChannel.h"
#import "NMVideo.h"
#import "NMCategory.h"

NSString * const NMDidFailSendEventNotification = @"NMDidFailSendEventNotification";

// channel
NSString * const NMWillSubscribeChannelNotification = @"NMWillSubscribeChannelNotification";
NSString * const NMDidSubscribeChannelNotification = @"NMDidSubscribeChannelNotification";
NSString * const NMDidFailSubscribeChannelNotification = @"NMDidFailSubscribeChannelNotification";
NSString * const NMWillUnsubscribeChannelNotification = @"NMWillUnsubscribeChannelNotification";
NSString * const NMDidUnsubscribeChannelNotification = @"NMDidUnsubscribeChannelNotification";
NSString * const NMDidFailUnsubscribeChannelNotification = @"NMDidFailUnsubscribeChannelNotification";
// event
NSString * const NMWillShareVideoNotification = @"NMWillShareVideoNotification";
NSString * const NMDidShareVideoNotification = @"NMDidShareVideoNotification";
NSString * const NMDidFailShareVideoNotification = @"NMDidFailShareVideoNotification";
NSString * const NMWillUnfavoriteVideoNotification = @"NMWillUnfavoriteVideoNotification";
NSString * const NMDidUnfavoriteVideoNotification = @"NMDidUnfavoriteVideoNotification";
NSString * const NMDidFailUnfavoriteVideoNotification = @"NMDidFailUnfavoriteVideoNotification";

NSString * const NMWillEnqueueVideoNotification = @"NMWillEnqueueVideoNotification";
NSString * const NMDidEnqueueVideoNotification = @"NMDidEnqueueVideoNotification";
NSString * const NMDidFailEnqueueVideoNotification = @"NMDidFailEnqueueVideoNotification";
NSString * const NMWillDequeueVideoNotification = @"NMWillDequeueVideoNotification";
NSString * const NMDidDequeueVideoNotification = @"NMDidDequeueVideoNotification";
NSString * const NMDidFailDequeueVideoNotification = @"NMDidFailDequeueVideoNotification";


@implementation NMEventTask

@synthesize channel, video;
@synthesize channelID;
@synthesize resultDictionary;
@synthesize elapsedSeconds, playedToEnd;

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
			executeSaveActionOnError = YES;
			break;
		case NMEventDequeue:
			evtStr = @"dequeue";
			executeSaveActionOnError = YES;
			break;
		case NMEventShare:
			evtStr = @"share";
			executeSaveActionOnError = YES;
			break;
		case NMEventUnfavorite:
			evtStr = @"unfavorite";
			executeSaveActionOnError = YES;
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
		{
			NSString * reasonStr = [errorInfo objectForKey:@"reason"];
			if ( reasonStr ) {
				urlStr = [NSString stringWithFormat:@"http://%@/events?channel_id=%@&video_id=%@&action=%@&user_id=%d&reason=%@", NM_BASE_URL, channelID, targetID, evtStr, NM_USER_ACCOUNT_ID, [reasonStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			} else {
				urlStr = [NSString stringWithFormat:@"http://%@/events?channel_id=%@&video_id=%@&action=%@&user_id=%d", NM_BASE_URL, channelID, targetID, evtStr, NM_USER_ACCOUNT_ID];
			}
			break;
		}
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

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	NMVideo * newVideo = nil;
	switch (eventType) {
		case NMEventSubscribeChannel:
		{
			channel.nm_subscribed = [NSNumber numberWithInteger:[ctrl maxChannelSortOrder] + 1];
			[ctrl.internalSubscribedChannelsCategory addChannelsObject:channel];
			return YES;
		}
		case NMEventUnsubscribeChannel:
		{
			channel.nm_subscribed = [NSNumber numberWithInteger:0];
			[ctrl.internalSubscribedChannelsCategory removeChannelsObject:channel];
			return YES;
		}
		case NMEventEnqueue:
		{
			//add video to "watch later" channel
			newVideo = [ctrl duplicateVideo:video];
			newVideo.channel = ctrl.myQueueChannel;
			newVideo.nm_sort_order = [NSNumber numberWithInteger:[ctrl maxVideoSortOrderInChannel:ctrl.myQueueChannel sessionOnly:NO] + 1];
			NSNumber * yesNum = [NSNumber numberWithBool:YES];
			newVideo.nm_watch_later = yesNum;
			[ctrl.myQueueChannel addVideosObject:newVideo];
			// mark the flag
			[ctrl batchUpdateVideoWithID:video.nm_id forValue:yesNum key:@"nm_watch_later"];
			// show/hide channel
			[ctrl updateMyQueueChannelHideStatus];
			return YES;
		}
		case NMEventDequeue:
		{
			// get the video from Watch Later channel
			//remove video to "watch later" channel
			video.nm_error = [NSNumber numberWithInteger:NMErrorDequeueVideo];
			// update the original video object
			[ctrl batchUpdateVideoWithID:video.nm_id forValue:[NSNumber numberWithBool:NO] key:@"nm_watch_later"];
			// show/hide channel
			[ctrl updateMyQueueChannelHideStatus];
//			// get the video from Watch Later channel
//			NSNumber * vid = [video.nm_id retain];
//			//remove video to "watch later" channel
//			[ctrl deleteVideoWithID:vid fromChannel:ctrl.myQueueChannel];
//			// update the original video object
//			[ctrl batchUpdateVideoWithID:vid forValue:[NSNumber numberWithBool:NO] key:@"nm_watch_later"];
//			[vid release];
//			// show/hide channel
//			[ctrl updateMyQueueChannelHideStatus];
			return YES;
		}
		case NMEventShare:
		{
			newVideo = [ctrl duplicateVideo:video];
			newVideo.channel = ctrl.favoriteVideoChannel;
			newVideo.nm_sort_order = [NSNumber numberWithInteger:[ctrl maxVideoSortOrderInChannel:ctrl.favoriteVideoChannel sessionOnly:NO] + 1];
			NSNumber * yesNum = [NSNumber numberWithBool:YES];
			newVideo.nm_favorite = yesNum;
			// mark the flag
			[ctrl batchUpdateVideoWithID:video.nm_id forValue:yesNum key:@"nm_favorite"];
			// show/hide channel
			[ctrl updateFavoriteChannelHideStatus];
			return YES;
		}
		case NMEventUnfavorite:
		{
			// remove video
			video.nm_error = [NSNumber numberWithInteger:NMErrorUnfavoriteVideo];
			// update the original video object
			[ctrl batchUpdateVideoWithID:video.nm_id forValue:[NSNumber numberWithBool:NO] key:@"nm_favorite"];
			// show/hide channel
			[ctrl updateFavoriteChannelHideStatus];
//			NSNumber * vid = [video.nm_id retain];
//			// remove video
//			[ctrl deleteVideoWithID:vid fromChannel:ctrl.favoriteVideoChannel];
//			// update the original video object
//			[ctrl batchUpdateVideoWithID:vid forValue:[NSNumber numberWithBool:NO] key:@"nm_favorite"];
//			[vid release];
//			// show/hide channel
//			[ctrl updateFavoriteChannelHideStatus];
			return YES;
		}	
		default:
			break;
	}
	return NO;
}

- (NSString *)willLoadNotificationName {
	switch (eventType) {
		case NMEventSubscribeChannel:
			return NMWillSubscribeChannelNotification;
		case NMEventUnsubscribeChannel:
			return NMWillUnsubscribeChannelNotification;
		case NMEventDequeue:
			return NMWillDequeueVideoNotification;
		case NMEventEnqueue:
			return NMWillEnqueueVideoNotification;
		case NMEventShare:
			return NMWillShareVideoNotification;
		case NMEventUnfavorite:
			return NMWillUnfavoriteVideoNotification;
			
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
		case NMEventDequeue:
			return NMDidDequeueVideoNotification;
		case NMEventEnqueue:
			return NMDidEnqueueVideoNotification;
		case NMEventShare:
			return NMDidShareVideoNotification;
		case NMEventUnfavorite:
			return NMDidUnfavoriteVideoNotification;
			
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
		case NMEventDequeue:
			return NMDidFailDequeueVideoNotification;
		case NMEventEnqueue:
			return NMDidFailEnqueueVideoNotification;
		case NMEventShare:
			return NMDidFailShareVideoNotification;
		case NMEventUnfavorite:
			return NMDidFailUnfavoriteVideoNotification;
			
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
			
		case NMEventEnqueue:
		case NMEventShare:
			return [NSDictionary dictionaryWithObject:video forKey:@"video"];
		case NMEventDequeue:
		case NMEventUnfavorite:
			if ( ![video isDeleted] ) {
				return [NSDictionary dictionaryWithObject:video forKey:@"video"];
			}
		default:
			break;
	}
	return nil;
}

@end
