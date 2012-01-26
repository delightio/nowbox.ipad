//
//  NMAccountManager.m
//  ipad
//
//  Created by Bill So on 1/26/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMAccountManager.h"
#import "NMTaskQueueController.h"

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
	NSArray *permissions = [NSArray arrayWithObjects:@"publish_stream", @"read_stream", @"read_friendlists", nil];
	[self.facebook authorize:permissions];
}

#pragma mark Facebook delegate methods

- (void)fbDidLogin {
	// save the token
	[_userDefaults setObject:[_facebook accessToken] forKey:NM_FACEBOOK_ACCESS_TOKEN_KEY];
	[_userDefaults setObject:[_facebook expirationDate] forKey:NM_FACEBOOK_EXPIRATION_DATE_KEY];
	[_userDefaults synchronize];
	
	// issue call to get user info
	[[NMTaskQueueController sharedTaskQueueController] issueGetMyFacebookProfile];
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
	[self.facebook extendAccessToken];
}

@end
