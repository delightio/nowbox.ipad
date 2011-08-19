//
//  NMChannel.h
//  ipad
//
//  Created by Bill So on 8/15/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMCategory, NMVideo;

@interface NMChannel : NSManagedObject

@property (nonatomic, retain) NSNumber * nm_current_page;
@property (nonatomic, retain) NSString * nm_description;
@property (nonatomic, retain) NSNumber * nm_id;
@property (nonatomic, retain) NSNumber * nm_last_vid;
@property (nonatomic, retain) NSNumber * nm_sort_order;
@property (nonatomic, retain) NSNumber * nm_subscribed;
@property (nonatomic, retain) NSString * nm_thumbnail_file_name;
@property (nonatomic, retain) NSNumber * nm_time_elapsed_timescale;
@property (nonatomic, retain) NSNumber * nm_time_elapsed_value;
@property (nonatomic, retain) NSString * resource_uri;
@property (nonatomic, retain) NSString * thumbnail_uri;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * nm_last_page;
@property (nonatomic, retain) NSSet *categories;
@property (nonatomic, retain) NSSet *videos;
@end

@interface NMChannel (CoreDataGeneratedAccessors)

- (void)addCategoriesObject:(NMCategory *)value;
- (void)removeCategoriesObject:(NMCategory *)value;
- (void)addCategories:(NSSet *)values;
- (void)removeCategories:(NSSet *)values;

- (void)addVideosObject:(NMVideo *)value;
- (void)removeVideosObject:(NMVideo *)value;
- (void)addVideos:(NSSet *)values;
- (void)removeVideos:(NSSet *)values;

@end
