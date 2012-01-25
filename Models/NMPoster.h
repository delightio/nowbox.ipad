//
//  NMPoster.h
//  ipad
//
//  Created by Bill So on 1/25/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMVideo;

@interface NMPoster : NSManagedObject

@property (nonatomic, retain) NSString * nm_username;
@property (nonatomic, retain) NSNumber * nm_social_network;
@property (nonatomic, retain) NSString * nm_user_id;
@property (nonatomic, retain) NSString * nm_description;
@property (nonatomic, retain) NSSet *videos;
@end

@interface NMPoster (CoreDataGeneratedAccessors)

- (void)addVideosObject:(NMVideo *)value;
- (void)removeVideosObject:(NMVideo *)value;
- (void)addVideos:(NSSet *)values;
- (void)removeVideos:(NSSet *)values;

@end
