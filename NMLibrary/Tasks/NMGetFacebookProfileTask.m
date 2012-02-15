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

- (id)initGetMe {
	self = [super init];
	command = NMCommandGetFacebookProfile;
	profileOwnsByMe = YES;
	return self;
}

- (id)initWithProfile:(NMPersonProfile *)aProfile {
	self = [super init];
	command = NMCommandGetFacebookProfile;
	self.userID = aProfile.nm_user_id;
	self.targetID = aProfile.nm_id;
	profileOwnsByMe = [aProfile.nm_me boolValue];
	return self;
}

- (void)dealloc {
	[_profileDictionary release];
	[_userID release];
	[_profile release];
	[super dealloc];
}

- (FBRequest *)facebookRequestForController:(NMNetworkController *)ctrl {
	NSString * str;
	if ( profileOwnsByMe ) {
		str = @"me";
	} else {
		str = _userID;
	}
	return [self.facebook requestWithGraphPath:str andParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"name,id,username,picture", @"fields", @"normal", @"type", nil] andDelegate:ctrl];
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
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	NSString * theID = [_profileDictionary objectForKey:@"nm_user_id"];
	BOOL newState;
	NMPersonProfile * theProfile = [ctrl insertNewPersonProfileWithID:theID isNew:&newState];
	if ( newState ) theProfile.nm_type = [NSNumber numberWithInteger:NMChannelUserFacebookType];
	theProfile.nm_error = (NSNumber *)kCFBooleanFalse;
	if ( profileOwnsByMe ) theProfile.nm_me = (NSNumber *)kCFBooleanTrue;
	[theProfile setValuesForKeysWithDictionary:_profileDictionary];
	self.profile = theProfile;
	
	// check if we need to create the channel object. Automatically subscribe to the profile if we are grabbing the owner's profile
	if ( newState && profileOwnsByMe ) {
		[ctrl subscribeUserChannelWithPersonProfile:theProfile];
		theProfile.nm_id = [NSNumber numberWithInteger:[ctrl maxPersonProfileID] + 1];
		theProfile.subscription.nm_subscription_tier = (NSNumber *)kCFBooleanFalse;
		return YES;
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

@end
