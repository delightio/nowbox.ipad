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

NSString * const NMWillGetFacebookProfileNotification = @"NMWillGetFacebookProfileNotification";
NSString * const NMDidGetFacebookProfileNotification = @"NMDidGetFacebookProfileNotification";
NSString * const NMDidFailGetFacebookProfileNotification = @"NMDidFailGetFacebookProfileNotification";

@implementation NMGetFacebookProfileTask
@synthesize profileDictionary = _profileDictionary;
@synthesize userID = _userID;

- (id)initGetMe {
	self = [super init];
	command = NMCommandGetFacebookProfile;
	
	return self;
}

- (id)initWithUserID:(NSString *)strID {
	self = [super init];
	command = NMCommandGetFacebookProfile;
	self.userID = strID;
	return self;
}

- (void)dealloc {
	[_profileDictionary release];
	[_userID release];
	[super dealloc];
}

- (FBRequest *)facebookRequestForController:(NMNetworkController *)ctrl {
	NSString * str;
	if ( _userID ) {
		str = _userID;
	} else {
		str = @"me";
	}
	return [self.facebook requestWithGraphPath:str andParams:[NSMutableDictionary dictionaryWithObject:@"first_name,id,username,picture" forKey:@"fields"] andDelegate:ctrl];
}

- (void)setParsedObjectsForResult:(id)result {
	NSMutableDictionary * theDict = [NSMutableDictionary dictionaryWithCapacity:3];
	[theDict setObject:[result objectForKey:@"id"] forKey:@"nm_user_id"];
	NSString * str = [result objectForKey:@"username"];
	if ( str ) [theDict setObject:str forKey:@"username"];
	else [theDict setObject:[NSNull null] forKey:@"username"];
	str = [result objectForKey:@"first_name"];
	if ( str ) [theDict setObject:str forKey:@"first_name"];
	else [theDict setObject:[NSNull null] forKey:@"first_name"];
	str = [result objectForKey:@"picture"];
	if ( str ) [theDict setObject:str forKey:@"picture"];
	else [theDict setObject:[NSNull null] forKey:@"picture"];
	self.profileDictionary = theDict;
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	NSString * theID = [_profileDictionary objectForKey:@"nm_user_id"];
	BOOL newState;
	NMPersonProfile * theProfile = [ctrl insertNewPersonProfileWithID:theID isNew:&newState];
	theProfile.nm_type = [NSNumber numberWithInteger:NMChannelUserFacebookType];
	[theProfile setValuesForKeysWithDictionary:_profileDictionary];
	if ( newState ) {
		// check if we need to create the channel object as well
		[ctrl subscribeUserChannelWithPersonProfile:theProfile];
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

@end
