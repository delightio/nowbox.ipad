//
//  NMGetFacebookProfileTask.m
//  ipad
//
//  Created by Bill So on 1/26/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMGetFacebookProfileTask.h"
#import "NMNetworkController.h"
#import "NMDataController.h"
#import "FBConnect.h"
#import "NMPersonProfile.h"
#import "NMSubscription.h"

NSString * const NMWillGetFacebookProfileNotification = @"NMWillGetFacebookProfileNotification";
NSString * const NMDidGetFacebookProfileNotification = @"NMDidGetFacebookProfileNotification";
NSString * const NMDidFailGetFacebookProfileNotification = @"NMDidFailGetFacebookProfileNotification";

@implementation NMGetFacebookProfileTask
@synthesize profileDictionary = _profileDictionary;
@synthesize userID = _userID;
@synthesize profile = _profile;
@synthesize facebookTypeNumber = _facebookTypeNumber;

- (id)initWithProfile:(NMPersonProfile *)aProfile {
	// For Facebook, the person's profile is always created before we perform fetch person profile detail.
	self = [super init];
	command = NMCommandGetFacebookProfile;
	self.userID = aProfile.nm_user_id;
	self.targetID = aProfile.nm_id;
	self.profile = aProfile;
	profileOwnsByMe = [aProfile.nm_me boolValue];
	return self;
}

- (void)dealloc {
	[_profileDictionary release];
	[_userID release];
	[_profile release];
	[_facebookTypeNumber release];
	[super dealloc];
}

- (NSInteger)commandIndex {
	NSInteger idx = 0;
	// use custom command index method
	idx = ABS((NSInteger)[_userID hash]);
	return (((NSIntegerMax >> 6 ) & idx) << 6) | command;
}

- (NSNumber *)facebookTypeNumber {
	if ( _facebookTypeNumber == nil ) {
		_facebookTypeNumber = [[NSNumber numberWithInteger:NMChannelUserFacebookType] retain];
	}
	return _facebookTypeNumber;
}

- (FBRequest *)facebookRequestForController:(NMNetworkController *)ctrl {
#ifdef DEBUG_FACEBOOK_IMPORT
	NSLog(@"get facebook profile - %@", profileOwnsByMe ? @"me" : _userID);
#endif
	NSString * str;
	if ( profileOwnsByMe ) {
		str = @"me";
	} else {
		str = _userID;
	}
	return [self.facebook requestWithGraphPath:str andParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"name,id,username,picture", @"fields", @"large", @"type", nil] andDelegate:ctrl];
}

- (void)setParsedObjectsForResult:(id)result {
	NSMutableDictionary * theDict = [NSMutableDictionary dictionaryWithCapacity:3];
	[theDict setObject:[result objectForKey:@"id"] forKey:@"nm_user_id"];
	NSString * str = [result objectForKey:@"username"];
	if ( str ) [theDict setObject:str forKey:@"username"];
	else [theDict setObject:[NSNull null] forKey:@"username"];
	str = [result objectForKey:@"name"];
	if ( str ) [theDict setObject:str forKey:@"name"];
	else [theDict setObject:[NSNull null] forKey:@"name"];
	str = [result objectForKey:@"picture"];
	if ( str ) [theDict setObject:str forKey:@"picture"];
	else [theDict setObject:[NSNull null] forKey:@"picture"];
	self.profileDictionary = theDict;
#ifdef DEBUG_FACEBOOK_IMPORT
	NSLog(@"facebook profile received: %@", [theDict objectForKey:@"name"]);
#endif
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	NSString * theID = [_profileDictionary objectForKey:@"nm_user_id"];
	BOOL newState;
	if ( _profile == nil ) {
		self.profile = [ctrl insertNewPersonProfileWithID:theID type:self.facebookTypeNumber isNew:&newState];
	}
	if ( newState ) _profile.nm_type = [NSNumber numberWithInteger:NMChannelUserFacebookType];
	_profile.nm_error = (NSNumber *)kCFBooleanFalse;
	[_profile setValuesForKeysWithDictionary:_profileDictionary];
	
	// check if we need to create the channel object. Automatically subscribe to the profile if we are grabbing the owner's profile
	if ( profileOwnsByMe && _profile.subscription == nil ) {
		[ctrl subscribeUserChannelWithPersonProfile:_profile];
		_profile.nm_id = [NSNumber numberWithInteger:[ctrl maxPersonProfileID] + 1];
		// tier 0 is the highest level
		_profile.subscription.nm_subscription_tier = (NSNumber *)kCFBooleanFalse;
		// save the channel ID
		[[NSUserDefaults standardUserDefaults] setObject:_profile.nm_id forKey:NM_USER_FACEBOOK_CHANNEL_ID_KEY];
		NM_USER_FACEBOOK_CHANNEL_ID = [_profile.nm_id integerValue];
		return YES;
	} else if ( _profile.subscription ) {
		// this profile contains a channel
		_profile.subscription.channel.thumbnail_uri = [_profileDictionary objectForKey:@"picture"];
	}
	return NO;
}

- (NSString *)willLoadNotificationName {
	return NMWillGetFacebookProfileNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidGetFacebookProfileNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailGetFacebookProfileNotification;
}

- (NSDictionary *)userInfo {
	return [NSDictionary dictionaryWithObjectsAndKeys:_profile, @"target_object", nil];
}

- (NSDictionary *)failUserInfo {
	return [NSDictionary dictionaryWithObject:_profile forKey:@"target_object"];
}

@end
