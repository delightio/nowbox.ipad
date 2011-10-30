//
//  NMCategory.h
//  ipad
//
//  Created by Bill So on 11/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMChannel;

@interface NMCategory : NSManagedObject

@property (nonatomic, retain) NSNumber * nm_id;
@property (nonatomic, retain) NSDate * nm_last_refresh;
@property (nonatomic, retain) NSNumber * nm_sort_order;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *channels;
@end

@interface NMCategory (CoreDataGeneratedAccessors)

- (void)addChannelsObject:(NMChannel *)value;
- (void)removeChannelsObject:(NMChannel *)value;
- (void)addChannels:(NSSet *)values;
- (void)removeChannels:(NSSet *)values;

@end
