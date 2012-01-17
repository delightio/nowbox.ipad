//
//  NMAuthor.h
//  ipad
//
//  Created by Bill So on 18/1/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMVideo;

@interface NMAuthor : NSManagedObject

@property (nonatomic, retain) NSNumber * nm_id;
@property (nonatomic, retain) NSString * profile_uri;
@property (nonatomic, retain) NSString * thumbnail_uri;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * nm_thumbnail_file_name;
@property (nonatomic, retain) NMVideo *videos;

@end
