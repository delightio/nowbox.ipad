//
//  NMGetTwitterProfileTask.m
//  ipad
//
//  Created by Bill So on 2/6/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMGetTwitterProfileTask.h"
#import "NMDataController.h"
#import "NMPersonProfile.h"
#import "NMSubscription.h"

NSString * const NMWillGetTwitterProfileNotification = @"NMWillGetTwitterProfileNotification";
NSString * const NMDidGetTwitterProfileNotification = @"NMDidGetTwitterProfileNotification";
NSString * const NMDidFailGetTwitterProfileNotification = @"NMDidFailGetTwitterProfileNotification";

@implementation NMGetTwitterProfileTask
@synthesize profile = _profile;
@synthesize account = _account;
@synthesize userID = _userID;
@synthesize profileDictionary = _profileDictionary;

- (id)initWithProfile:(NMPersonProfile *)aProfile account:(ACAccount *)acObj {
	self = [super init];
	command = NMCommandGetTwitterProfile;
	profileOwnsByMe = [aProfile.nm_relationship_type integerValue] == NMRelationshipMe;
	self.targetID = aProfile.nm_id;
	self.account = acObj;
	self.profile = aProfile;
	self.userID = aProfile.nm_user_id;
	return self;
}

- (void)dealloc {
	[_account release];
	[_profile release];
	[_userID release];
	[_profileDictionary release];
	[super dealloc];
}

- (NSURLRequest *)URLRequest {
	NSDictionary * params = nil;
	// we should always have the userID ready if the PersonProfile is not the account owner
	if ( profileOwnsByMe ) params = [NSDictionary dictionaryWithObject:_account.username forKey:@"screen_name"];
	else params = [NSDictionary dictionaryWithObject:_userID forKey:@"user_id"];
	TWRequest * twitRequest = [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.twitter.com/1/users/show.json"] parameters:params requestMethod:TWRequestMethodGET];
	NSURLRequest * req = [twitRequest signedURLRequest];
	[twitRequest release];
	return req;
}

- (void)processDownloadedDataInBuffer {
	if ( [buffer length] == 0 ) {
		encountersErrorDuringProcessing = YES;
		self.errorInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:NMErrorNoData] forKey:@"error_code"];
		return;
	}
	NSDictionary * dict = [buffer objectFromJSONData];
	
	NSMutableDictionary * theDict = [NSMutableDictionary dictionaryWithCapacity:3];
	NSString * key = @"username";
	NSString * str = [dict objectForKey:@"screen_name"];
	if ( str ) [theDict setObject:str forKey:key];
	else [theDict setObject:[NSNull null] forKey:key];

	// use the string version of the ID to avoid complication handling 64-bit integer
	[theDict setObject:[dict objectForKey:@"id_str"] forKey:@"nm_user_id"];

	key = @"name";
	str = [dict objectForKey:key];
	if ( str ) [theDict setObject:str forKey:key];
	else [theDict setObject:[NSNull null] forKey:key];
	
	key = @"picture";
	str = [dict objectForKey:@"profile_image_url"];
	if ( str ) [theDict setObject:str forKey:key];
	else [theDict setObject:[NSNull null] forKey:key];
	
	self.profileDictionary = theDict;
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	_profile.nm_error = (NSNumber *)kCFBooleanFalse;
	[_profile setValuesForKeysWithDictionary:_profileDictionary];
	
	// check if we need to create the channel object. Automatically subscribe to the profile if we are grabbing the owner's profile
	if ( profileOwnsByMe && _profile.subscription == nil ) {
		[ctrl subscribeUserChannelWithPersonProfile:_profile];
		_profile.nm_id = [NSNumber numberWithInteger:[ctrl maxPersonProfileID] + 1];
		_profile.subscription.nm_subscription_tier = (NSNumber *)kCFBooleanFalse;
		// save the channel ID
		[[NSUserDefaults standardUserDefaults] setObject:_profile.nm_id forKey:NM_USER_TWITTER_CHANNEL_ID_KEY];
		NM_USER_TWITTER_CHANNEL_ID = [_profile.nm_id integerValue];
		return YES;
	}
	return NO;
}

- (NSString *)willLoadNotificationName {
	return NMWillGetTwitterProfileNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidGetTwitterProfileNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailGetTwitterProfileNotification;
}

- (NSDictionary *)userInfo {
	return [NSDictionary dictionaryWithObjectsAndKeys:_profile, @"target_object", nil];
}

- (NSDictionary *)failUserInfo {
	return [NSDictionary dictionaryWithObject:_profile forKey:@"target_object"];
}

@end
