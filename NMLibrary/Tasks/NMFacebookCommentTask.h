//
//  NMFacebookCommentTask.h
//  ipad
//
//  Created by Bill So on 2/15/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMFacebookTask.h"

@class NMSocialInfo;

@interface NMFacebookCommentTask : NMFacebookTask

@property (nonatomic, retain) NMSocialInfo * postInfo;
@property (nonatomic, retain) NSString * objectID;
@property (nonatomic, retain) NSString * message;

- (id)initWithInfo:(NMSocialInfo *)info message:(NSString *)msg;

@end
