//
//  NMSubscription.h
//  ipad
//
//  Created by Bill So on 1/27/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMChannel, NMPersonProfile;

@interface NMSubscription : NSManagedObject

@property (nonatomic, retain) NSDate * nm_last_crawled;
@property (nonatomic, retain) NSString * nm_since_id;
@property (nonatomic, retain) NMChannel *channel;
@property (nonatomic, retain) NMPersonProfile *personProfile;

@end
