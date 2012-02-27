//
//  NMPersonProfile.h
//  ipad
//
//  Created by Bill So on 2/14/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMSocialComment, NMSocialInfo, NMSubscription;

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
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) NSSet *facebookLikes;
@property (nonatomic, retain) NMSubscription *subscription;
@end

@interface NMPersonProfile (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(NMSocialComment *)value;
- (void)removeCommentsObject:(NMSocialComment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

- (void)addFacebookLikesObject:(NMSocialInfo *)value;
- (void)removeFacebookLikesObject:(NMSocialInfo *)value;
- (void)addFacebookLikes:(NSSet *)values;
- (void)removeFacebookLikes:(NSSet *)values;

@end
