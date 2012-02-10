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

@property (nonatomic, retain) NSDate * created_time;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSManagedObject *facebook_info;
@property (nonatomic, retain) NMPersonProfile *from;

@end
