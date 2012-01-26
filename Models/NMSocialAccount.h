//
//  NMSocialAccount.h
//  ipad
//
//  Created by Bill So on 1/26/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMChannel;

@interface NMSocialAccount : NSManagedObject

@property (nonatomic, retain) NSString * first_name;
@property (nonatomic, retain) NSString * nm_identifier;
@property (nonatomic, retain) NSDate * nm_last_crawled;
@property (nonatomic, retain) NSString * nm_since_id;
@property (nonatomic, retain) NSNumber * nm_type;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSSet *channels;

@end

@interface NMSocialAccount (CoreDataGeneratedAccessors)

- (void)addChannelsObject:(NMChannel *)value;
- (void)removeChannelsObject:(NMChannel *)value;
- (void)addChannels:(NSSet *)values;
- (void)removeChannels:(NSSet *)values;

@end
