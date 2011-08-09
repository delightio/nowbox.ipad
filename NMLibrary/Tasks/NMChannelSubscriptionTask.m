//
//  NMChannelSubscriptionTask.m
//  ipad
//
//  Created by Bill So on 8/9/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "NMChannelSubscriptionTask.h"
#import "NMChannel.h"

NSString * const NMWillSubscribeChannelNotification = @"NMWillSubscribeChannelNotification";
NSString * const NMDidSubscribeChannelNotification = @"NMDidSubscribeChannelNotification";
NSString * const NMDidFailSubscribeChannelNotification = @"NMDidFailSubscribeChannelNotification";
NSString * const NMWillUnsubscribeChannelNotification = @"NMWillUnsubscribeChannelNotification";
NSString * const NMDidUnsubscribeChannelNotification = @"NMDidUnsubscribeChannelNotification";
NSString * const NMDidFailUnsubscribeChannelNotification = @"NMDidFailUnsubscribeChannelNotification";

@implementation NMChannelSubscriptionTask
@synthesize channel, channelID;

//- (id)init
//{
//    self = [super init];
//    if (self) {
//        // Initialization code here.
//    }
//    
//    return self;
//}

- (id)initSubscribeChannel:(NMChannel *)aChn {
	self = [super init];
	command = NMCommandSubscribeChannel;
	return self;
}

- (id)initUnsubscribeChannel:(NMChannel *)aChn {
	self = [super init];
	command = NMCommmandUnsubscrbeChannel;
	return self;
}

- (void)dealloc {
	[channelID release];
	[channel release];
	[super dealloc];
}

- (void)processDownloadedDataInBuffer {
	
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	
}

- (NSString *)willLoadNotificationName {
	switch (command) {
		case NMCommandSubscribeChannel:
			return NMWillSubscribeChannelNotification;
			
		default:
			return NMWillUnsubscribeChannelNotification;
	}
	return nil;
}

- (NSString *)didLoadNotificationName {
	switch (command) {
		case NMCommandSubscribeChannel:
			return NMDidSubscribeChannelNotification;
			
		default:
			return NMDidUnsubscribeChannelNotification;
	}
	return nil;
}

- (NSString *)didFailNotificationName {
	switch (command) {
		case NMCommandSubscribeChannel:
			return NMDidFailSubscribeChannelNotification;
			
		default:
			return NMDidFailUnsubscribeChannelNotification;
	}
	return nil;
}

@end
