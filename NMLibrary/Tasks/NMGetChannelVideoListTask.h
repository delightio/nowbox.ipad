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
	BOOL newChannel;
}

@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NSString * channelName;
@property (nonatomic) BOOL newChannel;

- (id)initWithChannel:(NMChannel *)aChn;

@end
