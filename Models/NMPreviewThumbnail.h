//
//  NMPreviewThumbnail.h
//  ipad
//
//  Created by Bill So on 8/31/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMChannel;

@interface NMPreviewThumbnail : NSManagedObject

@property (nonatomic, retain) NSString * thumbnail_uri;
@property (nonatomic, retain) NSString * nm_thumbnail_file_name;
@property (nonatomic, retain) NMChannel *channel;

@end
