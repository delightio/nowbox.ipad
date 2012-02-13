//
//  NMSubscription.h
//  ipad
//
//  Created by Bill So on 2/10/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMChannel, NMPersonProfile;

@interface NMSubscription : NSManagedObject

@property (nonatomic, retain) NSNumber * nm_current_page;
@property (nonatomic, retain) NSNumber * nm_hidden;
@property (nonatomic, retain) NSNumber * nm_is_new;
@property (nonatomic, retain) NSNumber * nm_last_vid;
@property (nonatomic, retain) NSString * nm_since_id;
@property (nonatomic, retain) NSNumber * nm_sort_order;
@property (nonatomic, retain) NSNumber * nm_subscription_tier;
@property (nonatomic, retain) NSNumber * nm_time_elapsed_timescale;
@property (nonatomic, retain) NSNumber * nm_time_elapsed_value;
@property (nonatomic, retain) NSNumber * nm_video_last_refresh;
@property (nonatomic, retain) NMChannel *channel;
@property (nonatomic, retain) NMPersonProfile *personProfile;

@end
