//
//  NMPostSharingTask.m
//  ipad
//
//  Created by Bill So on 11/7/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMPostSharingTask.h"
#import "NMDataController.h"
#import "NMChannel.h"
#import "NMVideo.h"

NSString * const NMWillPostSharingNotification = @"NMWillPostSharingNotification";
NSString * const NMDidPostSharingNotification = @"NMDidPostSharingNotification";
NSString * const NMDidFailPostSharingNotification = @"NMDidFailPostSharingNotification";

@implementation NMPostSharingTask
@synthesize video;
@synthesize channelID;
@synthesize elapsedSeconds, startSecond;
@synthesize message;

- (id)initWithType:(NMSocialLoginType)aType video:(NMVideo *)v {
	self = [super init];
	command = NMCommandPostSharing;
	self.video = v;
	self.targetID = v.nm_id;
	self.channelID = v.channel.nm_id;
	service = aType;
	return self;
}

- (void)dealloc {
	[video release];
	[channelID release];
	[message release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSString * urlStr = nil;
	NSString * ser = (service == NMLoginTwitterType ? @"twitter" : @"facebook");
	if ( message ) {
		urlStr = [NSString stringWithFormat:@"http://%@/shares?channel_id=%@&video_id=%@&video_start=%d&video_elapsed=%d&network=%@&user_id=%d&message=%@", NM_BASE_URL, channelID, targetID, startSecond, elapsedSeconds, ser, NM_USER_ACCOUNT_ID, [message stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	} else {
		urlStr = [NSString stringWithFormat:@"http://%@/shares?channel_id=%@&video_id=%@&video_start=%d&video_elapsed=%d&network=%@&user_id=%d", NM_BASE_URL, channelID, targetID, startSecond, elapsedSeconds, ser, NM_USER_ACCOUNT_ID];
	}
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	[request setHTTPMethod:@"POST"];
	[request addValue:NM_USER_TOKEN forHTTPHeaderField:@"X-NB-AuthToken"];
	return request;
}

- (void)processDownloadedDataInBuffer {
	if ( [buffer length] == 0 ) return;
	// the server returns a result dictionary. but the app doesn't need it for now.
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	NMVideo * newVideo = [ctrl duplicateVideo:video];
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

- (NSString *)willLoadNotificationName {
	return NMWillPostSharingNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidPostSharingNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailPostSharingNotification;
}

- (NSDictionary *)userInfo {
	return [NSDictionary dictionaryWithObject:video forKey:@"video"];
}

@end
