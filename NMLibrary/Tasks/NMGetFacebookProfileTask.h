//
//  NMGetFacebookProfileTask.h
//  ipad
//
//  Created by Bill So on 1/26/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMFacebookTask.h"

@interface NMGetFacebookProfileTask : NMFacebookTask

@property (nonatomic, retain) NSDictionary * profileDictionary;
@property (nonatomic, retain) NSString * userID;

- (id)initGetMe;

@end
