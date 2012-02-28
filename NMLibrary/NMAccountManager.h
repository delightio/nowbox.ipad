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

@class NMPersonProfile;

extern NSString * const NM_FACEBOOK_ACCESS_TOKEN_KEY;
extern NSString * const NM_FACEBOOK_EXPIRATION_DATE_KEY;

@interface NMAccountManager : NSObject <FBSessionDelegate> {
	id signOutTarget;
	SEL signOutAction;
	NSInteger numberOfVideoImported;
}

@property (nonatomic, retain) NSUserDefaults * userDefaults;
@property (nonatomic, readonly) Facebook * facebook;
@property (nonatomic, readonly) ACAccountStore * accountStore;
@property (nonatomic, retain) ACAccount * currentTwitterAccount;
@property (nonatomic, retain) NSNumber * facebookAccountStatus;
@property (nonatomic, retain) NSNumber * twitterAccountStatus;
@property (nonatomic, retain) NSMutableSet * updatedChannels;
@property (nonatomic, retain) NMPersonProfile * twitterProfile;
@property (nonatomic, retain) NMPersonProfile * facebookProfile;

@property (nonatomic, retain) NSTimer * socialChannelParsingTimer;
@property (nonatomic, retain) NSTimer * videoImportTimer;

+ (NMAccountManager *)sharedAccountManager;

- (void)authorizeFacebook;
- (void)signOutFacebookOnCompleteTarget:(id)aTarget action:(SEL)completionSelector;

// Twitter
- (void)subscribeAccount:(ACAccount *)acObj;

// Application lifecycle
- (void)applicationDidLaunch;
- (void)applicationDidSuspend;

// Sync methods
- (void)scheduleSyncSocialChannels;
- (void)scheduleImportVideos;

@end
