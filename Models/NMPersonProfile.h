//
//  NMPersonProfile.h
//  ipad
//
//  Created by Bill So on 1/27/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMSubscription, NMVideo;

@interface NMPersonProfile : NSManagedObject

@property (nonatomic, retain) NSString * nm_description;
@property (nonatomic, retain) NSNumber * nm_error;
@property (nonatomic, retain) NSNumber * nm_id;
@property (nonatomic, retain) NSNumber * nm_me;
@property (nonatomic, retain) NSNumber * nm_social_network;
@property (nonatomic, retain) NSString * nm_user_id;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSNumber * nm_type;
@property (nonatomic, retain) NSString * picture;
@property (nonatomic, retain) NSString * first_name;
@property (nonatomic, retain) NSSet *videos;
@property (nonatomic, retain) NMSubscription *subscription;
@end

@interface NMPersonProfile (CoreDataGeneratedAccessors)

- (void)addVideosObject:(NMVideo *)value;
- (void)removeVideosObject:(NMVideo *)value;
- (void)addVideos:(NSSet *)values;
- (void)removeVideos:(NSSet *)values;

@end
