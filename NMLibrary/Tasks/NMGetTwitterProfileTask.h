//
//  NMGetTwitterProfileTask.h
//  ipad
//
//  Created by Bill So on 2/6/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMTask.h"
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>

@class NMPersonProfile;

@interface NMGetTwitterProfileTask : NMTask {
	BOOL profileOwnsByMe;
}

@property (nonatomic, retain) ACAccount * account;
@property (nonatomic, retain) NMPersonProfile * profile;
@property (nonatomic, retain) NSString * userID;
@property (nonatomic, retain) NSDictionary * profileDictionary;

- (id)initWithProfile:(NMPersonProfile *)aProfile account:(ACAccount *)acObj;

@end
