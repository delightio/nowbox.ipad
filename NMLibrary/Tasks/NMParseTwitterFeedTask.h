//
//  NMParseTwitterFeedTask.h
//  ipad
//
//  Created by Bill So on 1/23/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMTask.h"
#import <Twitter/Twitter.h>

@class NMChannel;

@interface NMParseTwitterFeedTask : NMTask 

@property (nonatomic, retain) NMChannel * channel;

- (id)initWithChannel:(NMChannel *)chnObj;

@end
