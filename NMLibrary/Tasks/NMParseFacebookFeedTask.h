//
//  NMParseFacebookFeedTask.h
//  ipad
//
//  Created by Bill So on 16/1/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMTask.h"

@class NMChannel;
@class Facebook;
@class FBRequest;
@class NMNetworkController;

@interface NMParseFacebookFeedTask : NMTask

@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) Facebook * facebook;
@property (nonatomic, retain) NSString * nextPageURLString;

- (id)initWithChannel:(NMChannel *)chn facebookProxy:(Facebook *)fbObj;
- (FBRequest *)facebookRequestForController:(NMNetworkController *)ctrl;
- (void)setParsedObjectsForResult:(id)result;

- (BOOL)isYouTubeLink:(NSString *)urlStr;

@end
