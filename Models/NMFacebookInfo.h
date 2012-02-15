//
//  NMFacebookInfo.h
//  ipad
//
//  Created by Bill So on 2/14/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMFacebookComment, NMPersonProfile, NMVideo;

@interface NMFacebookInfo : NSManagedObject

@property (nonatomic, retain) NSString * comment_post_url;
@property (nonatomic, retain) NSNumber * comments_count;
@property (nonatomic, retain) NSString * like_post_url;
@property (nonatomic, retain) NSNumber * likes_count;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) NSSet *peopleLike;
@property (nonatomic, retain) NMVideo *video;
@end

@interface NMFacebookInfo (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(NMFacebookComment *)value;
- (void)removeCommentsObject:(NMFacebookComment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

- (void)addPeopleLikeObject:(NMPersonProfile *)value;
- (void)removePeopleLikeObject:(NMPersonProfile *)value;
- (void)addPeopleLike:(NSSet *)values;
- (void)removePeopleLike:(NSSet *)values;

@end
