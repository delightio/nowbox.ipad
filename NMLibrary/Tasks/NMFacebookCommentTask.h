//
//  NMFacebookCommentTask.h
//  ipad
//
//  Created by Bill So on 2/15/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMFacebookTask.h"

@class NMFacebookInfo;

@interface NMFacebookCommentTask : NMFacebookTask

@property (nonatomic, retain) NMFacebookInfo * postInfo;
@property (nonatomic, retain) NSString * objectID;
@property (nonatomic, retain) NSString * message;

- (id)initWithInfo:(NMFacebookInfo *)info message:(NSString *)msg;

@end
