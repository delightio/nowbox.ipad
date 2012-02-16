//
//  NMFacebookLikeTask.h
//  ipad
//
//  Created by Bill So on 2/15/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMFacebookTask.h"

@class NMFacebookInfo;

@interface NMFacebookLikeTask : NMFacebookTask

@property (nonatomic, retain) NMFacebookInfo * postInfo;
@property (nonatomic, retain) NSString * objectID;

- (id)initWithInfo:(NMFacebookInfo *)info like:(BOOL)aLike;

@end
