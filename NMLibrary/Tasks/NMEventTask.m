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
NSString * const NMWillFavoriteVideoNotification = @"NMWillFavoriteVideoNotification";
NSString * const NMDidFavoriteVideoNotification = @"NMDidFavoriteVideoNotification";
NSString * const NMDidFailFavoriteVideoNotification = @"NMDidFailFavoriteVideoNotification";
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
@synthesize elapsedSeconds, startSecond;
@synthesize playedToEnd;
@synthesize bulkSubscribe;

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
	[resultDictionary release];
	[channelID release];
	[channel release];
	[video release];
	[super dealloc];
}

- (NSInteger)commandIndex {
	if ( targetID ) {
		NSInteger tid = [self.targetID integerValue];
		// clean up the upper 9 bit
		tid = (NSIntegerMax >> 9) & tid;
		return tid << 9 | eventType << 6 | command;
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
		case NMEventFavorite:
			evtStr = @"favorite";
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
				urlStr = [NSString stringWithFormat:@"http://%@/events?channel_id=%@&video_id=%@&action=%@&user_id=%d&reason=%@", NM_BASE_URL, channelID, targetID, evtStr, NM_USER_ACCOUNT_ID, [NMTask stringByAddingPercentEscapes:reasonStr]];
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
			urlStr = [NSString stringWithFormat:@"http://%@/events?channel_id=%@&video_id=%@&video_start=%d&video_elapsed=%d&action=%@&user_id=%d", NM_BASE_URL, channelID, targetID, startSecond, elapsedSeconds, evtStr, NM_USER_ACCOUNT_ID];
			break;
	}
#ifdef DEBUG_EVENT_TRACKING
	NSLog(@"send event: %@", urlStr);
#endif
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	[request setHTTPMethod:@"POST"];
#ifndef DEBUG_DO_NOT_SEND_API_TOKEN
	[request addValue:NM_USER_TOKEN forHTTPHeaderField:NMAuthTokenHeaderKey];
#endif
	
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
			if ( bulkSubscribe ) {
				// in case of bulk subscribe (right now, only supported in onboard process), we preserve the order of subscription to be the same as sorting order
				channel.nm_subscribed = channel.nm_sort_order;
			} else {
				channel.nm_subscribed = [NSNumber numberWithInteger:[ctrl maxChannelSortOrder] + 1];
			}
			channel.nm_hidden = (NSNumber *)kCFBooleanFalse;
			[ctrl.internalSubscribedChannelsCategory addChannelsObject:channel];
			return YES;
		}
		case NMEventUnsubscribeChannel:
		{
			NSUserDefaults * def = [NSUserDefaults standardUserDefaults];
			if ( [channel isEqual:ctrl.userTwitterStreamChannel] ) {
				// the unsubscribed channel is a user stream channel
				// remove twitter stream channel
				[ctrl markChannelDeleteStatus:channel];
				NM_USER_TWITTER_CHANNEL_ID = 0;
				[def setInteger:0 forKey:NM_USER_TWITTER_CHANNEL_ID_KEY];
				// when a user login, the server will always set the AUTO POST to true. On the client side, we need to reset that too.
				[def setBool:YES forKey:NM_SETTING_TWITTER_AUTO_POST_KEY];
			} else if ( [channel isEqual:ctrl.userFacebookStreamChannel] ) {
				// remove facebook stream channel
				[ctrl markChannelDeleteStatus:channel];
				NM_USER_FACEBOOK_CHANNEL_ID = 0;
				[def setInteger:0 forKey:NM_USER_FACEBOOK_CHANNEL_ID_KEY];
				[def setBool:YES forKey:NM_SETTING_FACEBOOK_AUTO_POST_KEY];
			} else {
				channel.nm_subscribed = [NSNumber numberWithInteger:0];
				[ctrl.internalSubscribedChannelsCategory removeChannelsObject:channel];
			}
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
			// mark the flag
			[ctrl batchUpdateVideoWithID:video.nm_id forValue:yesNum key:@"nm_watch_later"];
			// show/hide channel
			[ctrl updateChannelHiddenStatus:ctrl.myQueueChannel];
			return YES;
		}
		case NMEventDequeue:
		{
			// get the video from Watch Later channel
			//remove video to "watch later" channel
			NMVideo * theVdo = [ctrl video:video inChannel:ctrl.myQueueChannel];
			theVdo.nm_error = [NSNumber numberWithInteger:NMErrorDequeueVideo];
			theVdo.channel = nil;
//			video.nm_error = [NSNumber numberWithInteger:NMErrorDequeueVideo];
			// update the original video object
			[ctrl batchUpdateVideoWithID:video.nm_id forValue:[NSNumber numberWithBool:NO] key:@"nm_watch_later"];
			// show/hide channel
			[ctrl updateChannelHiddenStatus:ctrl.myQueueChannel];
			return YES;
		}
		case NMEventFavorite:
		{
			newVideo = [ctrl duplicateVideo:video];
			newVideo.channel = ctrl.favoriteVideoChannel;
			newVideo.nm_sort_order = [NSNumber numberWithInteger:[ctrl maxVideoSortOrderInChannel:ctrl.favoriteVideoChannel sessionOnly:NO] + 1];
			NSNumber * yesNum = [NSNumber numberWithBool:YES];
			newVideo.nm_favorite = yesNum;
			// mark the flag
			[ctrl batchUpdateVideoWithID:video.nm_id forValue:yesNum key:@"nm_favorite"];
			// show/hide channel
			[ctrl updateChannelHiddenStatus:ctrl.favoriteVideoChannel];
			return YES;
		}
		case NMEventUnfavorite:
		{
			// remove video
			NMVideo * theVdo = [ctrl video:video inChannel:ctrl.favoriteVideoChannel];
			theVdo.nm_error = [NSNumber numberWithInteger:NMErrorUnfavoriteVideo];
			theVdo.channel = nil;
//			video.nm_error = [NSNumber numberWithInteger:NMErrorUnfavoriteVideo];
			// update the original video object
			[ctrl batchUpdateVideoWithID:video.nm_id forValue:[NSNumber numberWithBool:NO] key:@"nm_favorite"];
			// show/hide channel
			[ctrl updateChannelHiddenStatus:ctrl.favoriteVideoChannel];
			return YES;
		}	
//		case NMEventShare:
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
		case NMEventFavorite:
			return NMWillFavoriteVideoNotification;
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
		case NMEventFavorite:
			return NMDidFavoriteVideoNotification;
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
		case NMEventFavorite:
			return NMDidFailFavoriteVideoNotification;
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
		case NMEventFavorite:
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

- (NSDictionary *)failUserInfo {
	switch (eventType) {
		case NMEventSubscribeChannel:
		case NMEventUnsubscribeChannel:
			return [NSDictionary dictionaryWithObject:channel forKey:@"channel"];
			break;
			
		case NMEventEnqueue:
			return [NSDictionary dictionaryWithObject:video forKey:@"video"];
		case NMEventDequeue:
			if ( ![video isDeleted] ) {
				return [NSDictionary dictionaryWithObject:video forKey:@"video"];
			}
		default:
			break;
	}
	return nil;
}

@end
