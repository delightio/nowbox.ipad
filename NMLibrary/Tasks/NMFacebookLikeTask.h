//
//  NMFacebookLikeTask.h
//  ipad
//
//  Created by Bill So on 2/15/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMFacebookTask.h"

@class NMSocialInfo;

@interface NMFacebookLikeTask : NMFacebookTask

@property (nonatomic, retain) NMSocialInfo * postInfo;
@property (nonatomic, retain) NSString * objectID;

- (id)initWithInfo:(NMSocialInfo *)info like:(BOOL)aLike;

@end
