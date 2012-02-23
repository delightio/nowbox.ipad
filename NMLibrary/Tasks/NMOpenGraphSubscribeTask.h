//
//  NMOpenGraphSubscribeTask.h
//  ipad
//
//  Created by Bill So on 2/21/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMFacebookTask.h"

@class NMChannel;

@interface NMOpenGraphSubscribeTask : NMFacebookTask

- (id)initWithChannel:(NMChannel *)chn;

@end
