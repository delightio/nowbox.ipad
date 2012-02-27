//
//  NMSocialComment.h
//  ipad
//
//  Created by Bill So on 2/9/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMPersonProfile, NMSocialInfo;

@interface NMSocialComment : NSManagedObject

@property (nonatomic, retain) NSNumber * created_time;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * object_id;
@property (nonatomic, retain) NMSocialInfo *socialInfo;
@property (nonatomic, retain) NMPersonProfile *fromPerson;

- (NSString *)relativeTimeString;

@end
