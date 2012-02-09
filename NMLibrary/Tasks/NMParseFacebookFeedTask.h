//
//  NMParseFacebookFeedTask.h
//  ipad
//
//  Created by Bill So on 16/1/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMFacebookTask.h"

@class NMChannel;

@interface NMParseFacebookFeedTask : NMFacebookTask {
	NSInteger maxUnixTime;
	BOOL isAccountOwner;
	NSString * feedDirectURLString;
}

@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NSString * nextPageURLString;
@property (nonatomic, retain) NSString * user_id;
@property (nonatomic, retain) NSString * since_id;
@property (nonatomic, retain) NSMutableArray * profileArray;
@property (nonatomic, retain) NSString * feedDirectURLString;

+ (NSString *)youTubeExternalIDFromLink:(NSString *)urlStr;

- (id)initWithChannel:(NMChannel *)chn;
- (id)initWithChannel:(NMChannel *)chn directURLString:(NSString *)urlStr;

@end