//
//  NMParseTwitterFeedTask.h
//  ipad
//
//  Created by Bill So on 1/23/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMTask.h"
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>

@class NMChannel;

@interface NMParseTwitterFeedTask : NMTask {
	BOOL isAccountOwner;
	NSInteger numberOfVideoAdded;
}

@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) ACAccount * account;
@property (nonatomic) NSInteger page;
@property (nonatomic, retain) NSString * user_id;
@property (nonatomic, retain) NSString * since_id;
@property (nonatomic, retain) NSString * newestTwitIDString;
@property (nonatomic, retain) NSDateFormatter * feedDateFormatter;
@property (nonatomic, retain) NSNumber * twitterTypeNumber;
@property (nonatomic) BOOL notifyOnNewProfile;

- (id)initWithChannel:(NMChannel *)chnObj account:(ACAccount *)acObj;
- (id)initWithInfo:(NSDictionary *)aDict;

@end
