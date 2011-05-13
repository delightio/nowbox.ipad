//
//  NMChannel.h
//  Nowmov
//
//  Created by Bill So on 10/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <CoreMedia/CoreMedia.h>

@class NMVideo;

@interface NMChannel :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * nm_description;
@property (nonatomic, retain) NSNumber * nm_sort_order;
@property (nonatomic, retain) NSNumber * nm_last_vid;
@property (nonatomic, retain) NSNumber * nm_time_elapsed_value;
@property (nonatomic, retain) NSNumber * nm_time_elapsed_timescale;
@property (nonatomic, retain) NSNumber * count;
@property (nonatomic, retain) NSString * reason;
@property (nonatomic, retain) NSString * thumbnail;
@property (nonatomic, retain) NSString * nm_thumbnail_file_name;
@property (nonatomic, retain) NSString * channel_name;
@property (nonatomic, retain) NSSet* videos;
@property (nonatomic, retain) NSString * channel_url;
@property (nonatomic, retain) NSString * channel_type;
@property (nonatomic, retain) NSString * title;

@end


@interface NMChannel (CoreDataGeneratedAccessors)
- (void)addVideosObject:(NMVideo *)value;
- (void)removeVideosObject:(NMVideo *)value;
- (void)addVideos:(NSSet *)value;
- (void)removeVideos:(NSSet *)value;

@end

