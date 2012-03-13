//
//  NMGetFacebookProfileTask.h
//  ipad
//
//  Created by Bill So on 1/26/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMFacebookTask.h"

@class NMPersonProfile;

@interface NMGetFacebookProfileTask : NMFacebookTask {
	BOOL profileOwnsByMe;
}

@property (nonatomic, retain) NSDictionary * profileDictionary;
@property (nonatomic, retain) NMPersonProfile * profile;
@property (nonatomic, retain) NSString * userID;
@property (nonatomic, retain) NSNumber * facebookTypeNumber;

- (id)initWithProfile:(NMPersonProfile *)aProfile;

@end
