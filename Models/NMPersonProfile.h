//
//  NMPersonProfile.h
//  ipad
//
//  Created by Bill So on 2/9/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMFacebookComment, NMFacebookInfo, NMSubscription, NMVideo;

@interface NMPersonProfile : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * nm_account_identifier;
@property (nonatomic, retain) NSNumber * nm_error;
@property (nonatomic, retain) NSNumber * nm_id;
@property (nonatomic, retain) NSNumber * nm_me;
@property (nonatomic, retain) NSNumber * nm_type;
@property (nonatomic, retain) NSString * nm_user_id;
@property (nonatomic, retain) NSString * picture;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NMSubscription *subscription;
@property (nonatomic, retain) NSSet *videos;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) NSSet *facebook_likes;
@end

@interface NMPersonProfile (CoreDataGeneratedAccessors)

- (void)addVideosObject:(NMVideo *)value;
- (void)removeVideosObject:(NMVideo *)value;
- (void)addVideos:(NSSet *)values;
- (void)removeVideos:(NSSet *)values;

- (void)addCommentsObject:(NMFacebookComment *)value;
- (void)removeCommentsObject:(NMFacebookComment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

- (void)addFacebook_likesObject:(NMFacebookInfo *)value;
- (void)removeFacebook_likesObject:(NMFacebookInfo *)value;
- (void)addFacebook_likes:(NSSet *)values;
- (void)removeFacebook_likes:(NSSet *)values;

@end
