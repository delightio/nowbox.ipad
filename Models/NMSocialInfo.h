//
//  NMSocialInfo.h
//  ipad
//
//  Created by Bill So on 2/14/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMSocialComment, NMPersonProfile, NMConcreteVideo;

@interface NMSocialInfo : NSManagedObject

@property (nonatomic, retain) NSString * comment_post_url;
@property (nonatomic, retain) NSNumber * comments_count;
@property (nonatomic, retain) NSString * like_post_url;
@property (nonatomic, retain) NSNumber * likes_count;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSNumber * nm_date_last_updated;
@property (nonatomic, retain) NSNumber * nm_type;
@property (nonatomic, retain) NSString * object_id;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) NMPersonProfile * poster;
@property (nonatomic, retain) NSSet *peopleLike;
@property (nonatomic, retain) NMConcreteVideo *video;
@end

@interface NMSocialInfo (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(NMSocialComment *)value;
- (void)removeCommentsObject:(NMSocialComment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

- (void)addPeopleLikeObject:(NMPersonProfile *)value;
- (void)removePeopleLikeObject:(NMPersonProfile *)value;
- (void)addPeopleLike:(NSSet *)values;
- (void)removePeopleLike:(NSSet *)values;

@end
