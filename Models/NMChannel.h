//
//  NMChannel.h
//  ipad
//
//  Created by Bill So on 18/1/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMCategory, NMChannelDetail, NMPreviewThumbnail, NMVideo, NMSocialAccount;

@interface NMChannel : NSManagedObject {
	NSNumber * nm_populated;
	BOOL didFirstPopulateStatusCheck;
}

@property (nonatomic, retain) NSNumber * nm_current_page;
@property (nonatomic, retain) NSNumber * nm_hidden;
@property (nonatomic, retain) NSNumber * nm_id;
@property (nonatomic, retain) NSNumber * nm_is_new;
@property (nonatomic, retain) NSNumber * nm_last_vid;
@property (nonatomic, retain) NSNumber * nm_populated;
@property (nonatomic, retain) NSNumber * nm_sort_order;
@property (nonatomic, retain) NSNumber * nm_subscribed;
@property (nonatomic, retain) NSString * nm_thumbnail_file_name;
@property (nonatomic, retain) NSNumber * nm_time_elapsed_timescale;
@property (nonatomic, retain) NSNumber * nm_time_elapsed_value;
@property (nonatomic, retain) NSDate * nm_video_last_refresh;
@property (nonatomic, retain) NSDate * populated_at;
@property (nonatomic, retain) NSString * resource_uri;
@property (nonatomic, retain) NSNumber * subscriber_count;
@property (nonatomic, retain) NSString * thumbnail_uri;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSNumber * video_count;
@property (nonatomic, retain) NSSet *categories;
@property (nonatomic, retain) NMChannelDetail *detail;
@property (nonatomic, retain) NSSet *previewThumbnails;
@property (nonatomic, retain) NSSet *videos;
@property (nonatomic, retain) NMSocialAccount * socialAccount;

@end

@interface NMChannel (CoreDataGeneratedAccessors)

- (void)addCategoriesObject:(NMCategory *)value;
- (void)removeCategoriesObject:(NMCategory *)value;
- (void)addCategories:(NSSet *)values;
- (void)removeCategories:(NSSet *)values;

- (void)addPreviewThumbnailsObject:(NMPreviewThumbnail *)value;
- (void)removePreviewThumbnailsObject:(NMPreviewThumbnail *)value;
- (void)addPreviewThumbnails:(NSSet *)values;
- (void)removePreviewThumbnails:(NSSet *)values;

- (void)addVideosObject:(NMVideo *)value;
- (void)removeVideosObject:(NMVideo *)value;
- (void)addVideos:(NSSet *)values;
- (void)removeVideos:(NSSet *)values;

- (NSDate *)primitivePopulated_at;
- (void)setPrimitivePopulated_at:(NSDate *)aDate;
- (NSNumber *)primitiveNm_populated;
- (void)setPrimitiveNm_populated:(NSNumber *)aVal;

@end
