//
//  NMAccountManager.m
//  ipad
//
//  Created by Bill So on 1/26/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMAccountManager.h"
#import "NMTaskQueueController.h"
#import "NMDataController.h"
#import "NMPersonProfile.h"

static NMAccountManager * _sharedAccountManager = nil;

@implementation NMAccountManager
@synthesize userDefaults = _userDefaults;
@synthesize facebook = _facebook;
@synthesize facebookAuthorized;

+ (NMAccountManager *)sharedAccountManager {
	if ( _sharedAccountManager == nil ) {
		_sharedAccountManager = [[NMAccountManager alloc] init];
	}
	return _sharedAccountManager;
}

- (id)init {
	self = [super init];
	self.userDefaults = [NSUserDefaults standardUserDefaults];
	return self;
}

- (void)dealloc {
	[_facebook release];
	[_userDefaults release];
	[super dealloc];
}

#pragma mark Twitter

- (void)subscribeAccount:(ACAccount *)acObj {
	NMDataController * ctrl = [NMTaskQueueController sharedTaskQueueController].dataController;
	// create the person profile from the account object
	BOOL isNew;
	NMPersonProfile * theProfile = [ctrl insertNewPersonProfileWithAccountIdentifier:acObj.identifier isNew:&isNew];
	theProfile.nm_account_identifier = acObj.identifier;
	theProfile.nm_me = (NSNumber *)kCFBooleanTrue;
	theProfile.username = acObj.username;
	theProfile.nm_type = [NSNumber numberWithInteger:NMChannelUserTwitterType];
	theProfile.nm_error = [NSNumber numberWithInteger:NM_ENTITY_PENDING_IMPORT_ERROR];
	// listen to profile notification
	NMTaskQueueController * tqc = [NMTaskQueueController sharedTaskQueueController];
	[[NSNotificationCenter defaultCenter] addObserver:tqc selector:@selector(handleDidGetPersonProfile:) name:NMDidGetTwitterProfileNotification object:nil];
	
	// issue call to get user info
	[tqc issueGetProfile:theProfile account:acObj];
}

#pragma mark Facebook

- (Facebook *)facebook {
	if ( _facebook == nil ) {
		_facebook = [[Facebook alloc] initWithAppId:@"190577807707530" andDelegate:self];
		if ([_userDefaults objectForKey:NM_FACEBOOK_ACCESS_TOKEN_KEY] 
			&& [_userDefaults objectForKey:NM_FACEBOOK_EXPIRATION_DATE_KEY]) {
			_facebook.accessToken = [_userDefaults objectForKey:NM_FACEBOOK_ACCESS_TOKEN_KEY];
			_facebook.expirationDate = [_userDefaults objectForKey:NM_FACEBOOK_EXPIRATION_DATE_KEY];
		}
	}
	return _facebook;
}

- (BOOL)facebookAuthorized {
	NSString * tk = [_userDefaults objectForKey:NM_FACEBOOK_ACCESS_TOKEN_KEY];
	if ( tk && ![tk isEqualToString:@""] ) {
		return YES;
	}
	return NO;
}

- (void)authorizeFacebook {
	NSArray *permissions = [NSArray arrayWithObjects:@"publish_stream", @"read_stream", nil];
	[self.facebook authorize:permissions];
}

#pragma mark Facebook delegate methods

- (void)fbDidLogin {
	// save the token
	[_userDefaults setObject:[_facebook accessToken] forKey:NM_FACEBOOK_ACCESS_TOKEN_KEY];
	[_userDefaults setObject:[_facebook expirationDate] forKey:NM_FACEBOOK_EXPIRATION_DATE_KEY];
	[_userDefaults synchronize];
	
	// listen to profile notification
	NMTaskQueueController * tqc = [NMTaskQueueController sharedTaskQueueController];
	[[NSNotificationCenter defaultCenter] addObserver:tqc selector:@selector(handleDidGetPersonProfile:) name:NMDidGetFacebookProfileNotification object:nil];

	// issue call to get user info
	[tqc issueGetMyFacebookProfile];
	// Login interface should listen to notification so that it can update the interface accordingly
}

- (void)fbDidLogout {
    // Remove saved authorization information if it exists
	if ([_userDefaults objectForKey:NM_FACEBOOK_ACCESS_TOKEN_KEY]) {
		[_userDefaults removeObjectForKey:NM_FACEBOOK_ACCESS_TOKEN_KEY];
		[_userDefaults removeObjectForKey:NM_FACEBOOK_EXPIRATION_DATE_KEY];
		[_userDefaults synchronize];
	}
}

- (void)fbDidExtendToken:(NSString*)accessToken expiresAt:(NSDate*)expiresAt {
    [_userDefaults setObject:accessToken forKey:NM_FACEBOOK_ACCESS_TOKEN_KEY];
    [_userDefaults setObject:expiresAt forKey:NM_FACEBOOK_EXPIRATION_DATE_KEY];
    [_userDefaults synchronize];
}

- (void)fbDidNotLogin:(BOOL)cancelled {
	
}

- (void)fbSessionInvalidated {
	_facebook.accessToken = [_userDefaults objectForKey:NM_FACEBOOK_ACCESS_TOKEN_KEY];
	_facebook.expirationDate = [_userDefaults objectForKey:NM_FACEBOOK_EXPIRATION_DATE_KEY];
	[_facebook extendAccessToken];
}

@end
