//
//  NMAccountManager.h
//  ipad
//
//  Created by Bill So on 1/26/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBConnect.h"
#import <Accounts/Accounts.h>

extern NSString * const NM_FACEBOOK_ACCESS_TOKEN_KEY;
extern NSString * const NM_FACEBOOK_EXPIRATION_DATE_KEY;

@interface NMAccountManager : NSObject <FBSessionDelegate> {
	id signOutTarget;
	SEL signOutAction;
}

@property (nonatomic, retain) NSUserDefaults * userDefaults;
@property (nonatomic, readonly) Facebook * facebook;
@property (nonatomic, readonly) BOOL facebookAuthorized;

+ (NMAccountManager *)sharedAccountManager;

- (void)authorizeFacebook;
- (void)signOutFacebookOnCompleteTarget:(id)aTarget action:(SEL)completionSelector;

- (void)subscribeAccount:(ACAccount *)acObj;

@end
