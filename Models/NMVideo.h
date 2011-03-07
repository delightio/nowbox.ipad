//
//  NMVideo.h
//  Nowmov
//
//  Created by Bill So on 08/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class NMChannel;

@interface NMVideo :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * nm_description;
@property (nonatomic, retain) NSNumber * nm_id;
@property (nonatomic, retain) NSDate * created_at;
@property (nonatomic, retain) NSString * external_id;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * total_mentions;
@property (nonatomic, retain) NSString * nm_direct_url;
@property (nonatomic, retain) NSNumber * nm_sort_order;
@property (nonatomic, retain) NSString * reason_included;
@property (nonatomic, retain) NSSet* channels;

@end


@interface NMVideo (CoreDataGeneratedAccessors)
- (void)addChannelsObject:(NMChannel *)value;
- (void)removeChannelsObject:(NMChannel *)value;
- (void)addChannels:(NSSet *)value;
- (void)removeChannels:(NSSet *)value;

@end

