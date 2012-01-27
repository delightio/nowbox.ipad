//
//  NMParseFacebookFeedTask.h
//  ipad
//
//  Created by Bill So on 16/1/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMFacebookTask.h"

@class NMChannel;

@interface NMParseFacebookFeedTask : NMFacebookTask

@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NSString * nextPageURLString;
@property (nonatomic, retain) NSString * user_id;

+ (NSString *)youTubeExternalIDFromLink:(NSString *)urlStr;

- (id)initWithChannel:(NMChannel *)chn;

@end
