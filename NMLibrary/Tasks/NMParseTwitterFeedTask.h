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
}

@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) ACAccount * account;
@property (nonatomic) NSInteger page;
@property (nonatomic, retain) NSString * user_id;
@property (nonatomic, retain) NSString * since_id;
@property (nonatomic, retain) NSMutableArray * profileArray;
@property (nonatomic, retain) NSString * newestTwitIDString;

- (id)initWithChannel:(NMChannel *)chnObj account:(ACAccount *)acObj;
- (id)initWithInfo:(NSDictionary *)aDict;

@end
