//
//  NMGetChannelVideosTask.h
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTask.h"

@class NMChannel;

@interface NMGetChannelVideoListTask : NMTask {
	NMChannel * channel;
	NSString * channelName;
	NSString * urlString;
	BOOL newChannel;
	NSUInteger numberOfVideoAdded;
	NSUInteger numberOfVideoRequested;
}

@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NSString * channelName;
@property (nonatomic, retain) NSString * urlString;
@property (nonatomic) NSUInteger numberOfVideoRequested;
@property (nonatomic) BOOL newChannel;

// in this wind-down version. we only have one single channel - Live
- (id)initWithChannel:(NMChannel *)aChn;

+ (NSMutableDictionary *)normalizeVideoDictionary:(NSDictionary *)dict;

@end
