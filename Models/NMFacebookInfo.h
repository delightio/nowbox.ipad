//
//  NMFacebookInfo.h
//  ipad
//
//  Created by Bill So on 2/9/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMConcreteVideo, NMFacebookComment, NMPersonProfile;

@interface NMFacebookInfo : NSManagedObject

@property (nonatomic, retain) NSNumber * likes_count;
@property (nonatomic, retain) NSNumber * comments_count;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) NMConcreteVideo *video;
@property (nonatomic, retain) NSSet *people_like;
@end

@interface NMFacebookInfo (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(NMFacebookComment *)value;
- (void)removeCommentsObject:(NMFacebookComment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

- (void)addPeople_likeObject:(NMPersonProfile *)value;
- (void)removePeople_likeObject:(NMPersonProfile *)value;
- (void)addPeople_like:(NSSet *)values;
- (void)removePeople_like:(NSSet *)values;

@end
