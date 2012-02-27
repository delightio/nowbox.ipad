//
//  NMPostTweetTask.m
//  ipad
//
//  Created by Bill So on 2/24/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMPostTweetTask.h"
#import "NMDataController.h"
#import "NMSocialComment.h"

NSString * const NMWillPostRetweetNotification = @"NMWillPostRetweetNotification";
NSString * const NMDidPostRetweetNotification = @"NMDidPostRetweetNotification";
NSString * const NMDidFailPostRetweetNotification = @"NMDidFailPostRetweetNotification";

NSString * const NMWillReplyTweetNotificaiton = @"NMWillReplyTweetNotificaiton";
NSString * const NMDidReplyTweetNotificaiton = @"NMDidReplyTweetNotificaiton";
NSString * const NMDidFailReplyTweetNotificaiton = @"NMDidFailReplyTweetNotificaiton";

NSString * const NMWillPostTweetNotification = @"NMWillPostTweetNotification";
NSString * const NMDidPostTweetNotification = @"NMDidPostTweetNotification";
NSString * const NMDidFailPostTweetNotification = @"NMDidFailPostTweetNotification";

@implementation NMPostTweetTask

@synthesize account = _account;
@synthesize message = _message;
@synthesize tweetID = _tweetID;

- (id)initRetweetComment:(NMSocialComment *)cmt {
	self = [super init];
	command = NMCommandRetweet;
	self.tweetID = cmt.object_id;
	return self;
}

- (id)initReplyWithComment:(NMSocialComment *)cmt {
	self = [super init];
	command = NMCommandReplyTweet;
	self.message = cmt.message;
	self.tweetID = cmt.object_id;
	return self;
}

- (id)initPostComment:(NMSocialComment *)cmt {
	self = [super init];
	command = NMCommandPostTweet;
	self.message = cmt.message;
	return self;
}

- (NSInteger)commandIndex {
	if ( _tweetID ) {
		NSInteger idx = 0;
		// use custom command index method
		idx = ABS((NSInteger)[_tweetID hash]);
		return (((NSIntegerMax >> 6 ) & idx) << 6) | command;
	}
	return [super commandIndex];
}

- (NSURLRequest *)URLRequest {
	NSString * urlStr = nil;
	TWRequest * twitRequest = nil;
	switch (command) {
		case NMCommandRetweet:
			urlStr = [NSString stringWithFormat:@"http://api.twitter.com/1/statuses/retweet/%@.json", _tweetID];
			twitRequest	= [[TWRequest alloc] initWithURL:[NSURL URLWithString:urlStr] parameters:nil requestMethod:TWRequestMethodPOST];
			break;
			
		case NMCommandReplyTweet:
		{
			urlStr = @"http://api.twitter.com/1/statuses/update.json";
			NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:_message, @"status", _tweetID, @"in_reply_to_status_id", nil];
			twitRequest	= [[TWRequest alloc] initWithURL:[NSURL URLWithString:urlStr] parameters:dict requestMethod:TWRequestMethodPOST];
			break;
		}	
		case NMCommandPostTweet:
		{
			urlStr = @"http://api.twitter.com/1/statuses/update.json";
			NSDictionary * dict = [NSDictionary dictionaryWithObject:_message forKey:@"status"];
			twitRequest	= [[TWRequest alloc] initWithURL:[NSURL URLWithString:urlStr] parameters:dict requestMethod:TWRequestMethodPOST];
			break;
		}	
		default:
			break;
	}
	twitRequest.account = _account;
	NSURLRequest * req = [twitRequest signedURLRequest];
	[twitRequest release];
	return req;
}

//- (void)processDownloadedDataInBuffer {
//	
//}

//- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
//	
//}

- (NSString *)willLoadNotificationName {
	NSString * str = nil;
	switch (command) {
		case NMCommandRetweet:
			str = NMWillPostRetweetNotification;
			break;
			
		case NMCommandReplyTweet:
			str = NMWillReplyTweetNotificaiton;
			break;
			
		case NMCommandPostTweet:
			str = NMWillPostTweetNotification;
			break;
			
		default:
			break;
	}
	return str;
}

- (NSString *)didLoadNotificationName {
	NSString * str = nil;
	switch (command) {
		case NMCommandRetweet:
			str = NMDidPostRetweetNotification;
			break;
			
		case NMCommandReplyTweet:
			str = NMDidReplyTweetNotificaiton;
			break;
			
		case NMCommandPostTweet:
			str = NMDidPostTweetNotification;
			break;
			
		default:
			break;
	}
	return str;
}

- (NSString *)didFailNotificationName {
	NSString * str = nil;
	switch (command) {
		case NMCommandRetweet:
			str = NMDidFailPostRetweetNotification;
			break;
			
		case NMCommandReplyTweet:
			str = NMDidFailReplyTweetNotificaiton;
			break;
			
		case NMCommandPostTweet:
			str = NMDidFailPostTweetNotification;
			break;
			
		default:
			break;
	}
	return str;
}

@end
