//
//  NMAuthor.h
//  ipad
//
//  Created by Bill So on 1/21/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMConcreteVideo;

@interface NMAuthor : NSManagedObject

@property (nonatomic, retain) NSNumber * nm_id;
@property (nonatomic, retain) NSString * nm_thumbnail_file_name;
@property (nonatomic, retain) NSString * profile_uri;
@property (nonatomic, retain) NSString * thumbnail_uri;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSSet *videos;
@end

@interface NMAuthor (CoreDataGeneratedAccessors)

- (void)addVideosObject:(NMConcreteVideo *)value;
- (void)removeVideosObject:(NMConcreteVideo *)value;
- (void)addVideos:(NSSet *)values;
- (void)removeVideos:(NSSet *)values;

@end
