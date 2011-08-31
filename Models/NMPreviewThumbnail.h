//
//  NMPreviewThumbnail.h
//  ipad
//
//  Created by Bill So on 1/9/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMChannel;

@interface NMPreviewThumbnail : NSManagedObject

@property (nonatomic, retain) NSNumber * nm_sort_order;
@property (nonatomic, retain) NSString * nm_thumbnail_file_name;
@property (nonatomic, retain) NSString * external_id;
@property (nonatomic, retain) NSString * thumbnail_uri;
@property (nonatomic, retain) NSNumber * nm_id;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSDate * published_at;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * view_count;
@property (nonatomic, retain) NMChannel *channel;

@end
