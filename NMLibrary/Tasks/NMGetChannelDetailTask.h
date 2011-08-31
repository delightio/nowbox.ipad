//
//  NMGetChannelDetailTask.h
//  ipad
//
//  Created by Bill So on 8/31/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMTask.h"

@class NMChannel;

@interface NMGetChannelDetailTask : NMTask {
	NMChannel * channel;
	NSString * channelDescription;
	NSMutableArray * videoThumbnailURIs;
}

@property (nonatomic, retain) NMChannel * channel;

@end
