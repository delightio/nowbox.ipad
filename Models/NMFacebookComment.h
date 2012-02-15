//
//  NMFacebookComment.h
//  ipad
//
//  Created by Bill So on 2/9/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMPersonProfile;

@interface NMFacebookComment : NSManagedObject

@property (nonatomic, retain) NSNumber * created_time;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSManagedObject *facebookInfo;
@property (nonatomic, retain) NMPersonProfile *fromPerson;

@end
