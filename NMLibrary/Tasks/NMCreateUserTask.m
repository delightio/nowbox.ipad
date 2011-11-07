//
//  NMCreateUserTask.m
//  ipad
//
//  Created by Bill So on 7/9/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMCreateUserTask.h"
#import "NMChannel.h"
#import "NMDataController.h"

#define DEBUG_USER_ID 0

NSString * const NMWillCreateUserNotification = @"NMWillCreateUserNotification";
NSString * const NMDidCreateUserNotification = @"NMDidCreateUserNotification";
NSString * const NMDidFailCreateUserNotification = @"NMDidFailCreateUserNotification";
NSString * const NMWillEditUserNotification = @"NMWillEditUserNotification";
NSString * const NMDidEditUserNotification = @"NMDidEditUserNotification";
NSString * const NMDidFailEditUserNotification = @"NMDidFailEditUserNotification";
NSString * const NMWillVerifyUserNotification = @"NMWillVerifyUserNotification";
NSString * const NMDidVerifyUserNotification = @"NMDidVerifyUserNotification";
NSString * const NMDidFailVerifyUserNotification = @"NMDidFailVerifyUserNotification";

@implementation NMCreateUserTask
@synthesize verificationURL, email;
@synthesize userDictionary;

- (id)init {
	self = [super init];
	command = NMCommandCreateUser;
	return self;
}

- (id)initTwitterVerificationWithURL:(NSURL *)aURL {
	self = [super init];
	command = NMCommandVerifyTwitterUser;
	self.verificationURL = aURL;
	return self;
}

- (id)initYoutubeVerificationWithURL:(NSURL *)aURL {
	self = [super init];
	command = NMCommandVerifyYoutubeUser;
	self.verificationURL = aURL;
	return self;
}

- (id)initFacebookVerificationWithURL:(NSURL *)aURL {
	self = [super init];
	command = NMCommandVerifyFacebookUser;
	self.verificationURL = aURL;
	return self;
}

- (id)initWithEmail:(NSString *)anEmail {
	self = [super init];
	command = NMCommandEditUser;
	self.email = anEmail;
	return self;
}

- (void)dealloc {
	[email release];
	[verificationURL release];
	[userDictionary release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSMutableURLRequest * request;
	NSString * urlStr;
	switch (command) {
		case NMCommandCreateUser:
		{
//			urlStr = [NSString stringWithFormat:@"http://%@/users?locale=%@&language=%@&time_zone=%@", NM_BASE_URL, [[NSLocale currentLocale] localeIdentifier], [[NSLocale preferredLanguages] objectAtIndex:0], [[[NSTimeZone systemTimeZone] name] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
#if DEBUG_USER_ID > 0
			urlStr = [NSString stringWithFormat:@"http://%@/users/%d", NM_BASE_URL, DEBUG_USER_ID];
			request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
#else
			urlStr = [NSString stringWithFormat:@"http://%@/users?locale=%@&language=%@", NM_BASE_URL, [[NSLocale currentLocale] localeIdentifier], [[NSLocale preferredLanguages] objectAtIndex:0]];
			request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
			[request setHTTPMethod:@"POST"];
#endif
			break;
		}
		case NMCommandEditUser:
		{
			urlStr = [NSString stringWithFormat:@"http://%@/users?email=%@", NM_BASE_URL, [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
			[request setHTTPMethod:@"PUT"];
			break;
		}
			
		default:
		{
			request = [NSMutableURLRequest requestWithURL:verificationURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
			break;
		}
	}
	return request;
}

- (void)processDownloadedDataInBuffer {
	if ( [buffer length] == 0 ) {
		encountersErrorDuringProcessing = NO;
		return;
	}
	// parse the returned JSON object
	self.userDictionary = [buffer objectFromJSONData];
	NSInteger uid = [[userDictionary objectForKey:@"id"] integerValue];
	NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
	switch (command) {
		case NMCommandCreateUser:
		{
			if ( uid ) {
				//TODO: save the data to Keychain
				
				// update global variable
				NM_USER_ACCOUNT_ID = uid;
				NM_USER_WATCH_LATER_CHANNEL_ID = [[userDictionary objectForKey:@"queue_channel_id"] integerValue];
				NM_USER_FAVORITES_CHANNEL_ID = [[userDictionary objectForKey:@"favorite_channel_id"] integerValue];
				NM_USER_HISTORY_CHANNEL_ID = [[userDictionary objectForKey:@"history_channel_id"] integerValue];
				[defs setInteger:NM_USER_ACCOUNT_ID forKey:NM_USER_ACCOUNT_ID_KEY];
				[defs setInteger:NM_USER_WATCH_LATER_CHANNEL_ID forKey:NM_USER_WATCH_LATER_CHANNEL_ID_KEY];
				[defs setInteger:NM_USER_FAVORITES_CHANNEL_ID forKey:NM_USER_FAVORITES_CHANNEL_ID_KEY];
				[defs setInteger:NM_USER_HISTORY_CHANNEL_ID forKey:NM_USER_HISTORY_CHANNEL_ID_KEY];
			} else {
				encountersErrorDuringProcessing = YES;
			}
			break;
		}
		case NMCommandEditUser:
		{
			break;
		}
		case NMCommandVerifyFacebookUser:
			NM_USER_FACEBOOK_CHANNEL_ID = [[userDictionary objectForKey:@"facebook_channel_id"] integerValue];
			break;
			
		case NMCommandVerifyTwitterUser:
			NM_USER_TWITTER_CHANNEL_ID = [[userDictionary objectForKey:@"twitter_channel_id"] integerValue];
			break;
			
		case NMCommandVerifyYoutubeUser:
			NM_USER_YOUTUBE_SYNC_ACTIVE = YES;
			break;
			
		default:
		{
			break;
		}
	}
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	switch (command) {
		case NMCommandVerifyFacebookUser:
		case NMCommandVerifyTwitterUser:
		case NMCommandVerifyYoutubeUser:
			return NO;
			
		default:
			break;
	}
	/*
	 When this task is done, the backend should queue the "Get Channels" task to merge changes in channels.
	 In this task, there's NO need to merge the channels. Just create the Facebook or Twitter stream channel
	*/
//	NSNumber * idNum = nil;
//	switch (command) {
//		case NMCommandVerifyFacebookUser:
//			idNum = [userDictionary objectForKey:@"facebook_channel_id"];
//			break;
//			
//		case NMCommandVerifyTwitterUser:
//			idNum = [userDictionary objectForKey:@"twitter_channel_id"];
//			break;
//			
//		default:
//			break;
//	}
//	NMChannel * chnObj = [ctrl channelForID:idNum];
//	if ( chnObj == nil ) {
//		// create the new object
//		chnObj = [ctrl insertNewChannelForID:idNum];
//		chnObj.nm_hidden = [NSNumber numberWithBool:YES];
//		// the reset of the attributes are left for the "Get Channels" task to set.
//	}
	return YES;
}

- (NSString *)willLoadNotificationName {
	switch (command) {
		case NMCommandCreateUser:
			return NMWillCreateUserNotification;
		case NMCommandEditUser:
			return NMWillEditUserNotification;
			
		default:
			return NMWillVerifyUserNotification;
	}
	return nil;
}

- (NSString *)didLoadNotificationName {
	switch (command) {
		case NMCommandCreateUser:
			return NMDidCreateUserNotification;
		case NMCommandEditUser:
			return NMDidEditUserNotification;
			
		default:
			return NMDidVerifyUserNotification;
	}
	return nil;
}

- (NSString *)didFailNotificationName {
	switch (command) {
		case NMCommandCreateUser:
			return NMDidFailCreateUserNotification;
		case NMCommandEditUser:
			return NMDidFailEditUserNotification;
			
		default:
			return NMDidFailVerifyUserNotification;
	}
	return nil;
}

@end
