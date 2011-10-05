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
//	[userDictionary release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSMutableURLRequest * request;
	NSString * urlStr;
	switch (command) {
		case NMCommandCreateUser:
		{
			NSLog(@"timezone: %@", [[NSTimeZone systemTimeZone] name]);
			urlStr = [NSString stringWithFormat:@"http://%@/users?locale=%@", NM_BASE_URL, [[NSLocale currentLocale] localeIdentifier]];
			request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
			[request setHTTPMethod:@"POST"];
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
		encountersErrorDuringProcessing = YES;
		return;
	}
	// parse the returned JSON object
	NSDictionary * theDict = [buffer objectFromJSONData];
	NSInteger uid = [[theDict objectForKey:@"id"] integerValue];
	switch (command) {
		case NMCommandCreateUser:
		{
			if ( uid ) {
				//TODO: save the data to Keychain
				
				// update global variable
				NM_USER_ACCOUNT_ID = uid;
				NM_USER_WATCH_LATER_CHANNEL_ID = [[theDict objectForKey:@"queue_channel_id"] integerValue];
				NM_USER_FAVORITES_CHANNEL_ID = [[theDict objectForKey:@"favorite_channel_id"] integerValue];
				NM_USER_HISTORY_CHANNEL_ID = [[theDict objectForKey:@"history_channel_id"] integerValue];
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
			
		default:
		{
			// verification command
//			self.userDictionary = theDict;
			break;
		}
	}
}

//- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
//	if ( command != NMCommandVerifyTwitterUser && command != NMCommandVerifyFacebookUser ) return NO;
//	// merge all channels with current list from server
//	NSArray * newSubscribedChannels = [userDictionary objectForKey:@"subscribed_channel_ids"];
//	NSArray * channelAy = ctrl.subscribedChannels;
//	NMChannel * chnObj;
//	NSUInteger idx;
//	NSMutableArray * chnToDeleteAy = nil;
//	if ( newSubscribedChannels ) {
//		NSUInteger order = 10;
//		// loop through all local subscribed channels
//		for (chnObj in channelAy) {
//			idx = [newSubscribedChannels indexOfObject:chnObj.nm_id];
//			if ( idx == NSNotFound ) {
//				if ( chnToDeleteAy == nil ) chnToDeleteAy = [NSMutableArray arrayWithCapacity:4];
//				[chnToDeleteAy addObject:chnObj.nm_id];
//			} else {
//				// local channel exists in the server set
//				chnObj.nm_subscribed = [NSNumber numberWithUnsignedInteger:order++];
//			}
//		}
//	}
//	// check whether user channels exists
//	NSNumber * idNum = nil;
//	switch (command) {
//		case NMCommandVerifyFacebookUser:
//			idNum = [userDictionary objectForKey:@"facebook_channel_id"];
//			if ( idNum ) {
//				NM_USER_FACEBOOK_CHANNEL_ID = [idNum integerValue];
//				if ( [chnToDeleteAy indexOfObject:idNum] ) {
//					// raise the channel to the top
//					// remove the channel from the "to-be-deleted set"
//					[chnToDeleteAy removeObject:idNum];
//				} // else, create new channel later
//			}
//			break;
//			
//		case NMCommandVerifyTwitterUser:
//			idNum = [userDictionary objectForKey:@"twitter_channel_id"];
//			if ( idNum ) {
//				NM_USER_TWITTER_CHANNEL_ID = [idNum integerValue];
//				if ( [chnToDeleteAy indexOfObject:idNum] ) {
//					[chnToDeleteAy removeObject:idNum];
//				}
//			}
//			break;
//			
//		default:
//			break;
//	}
//	if ( [chnToDeleteAy count] ) {
//		// delete all these channels
//		[ctrl batchDeleteChannelForIDs:chnToDeleteAy];
//	}
//	// No need to add new list of subscribed channels here. Make sure the task queue scheduler call for channel list refresh after this is finished.
//	return YES;
//}

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
