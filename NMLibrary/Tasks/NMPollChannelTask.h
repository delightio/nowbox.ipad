//
//  NMPollChannelTask.h
//  ipad
//
//  Created by Bill So on 10/17/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMTask.h"

@class NMChannel;

/*!
 Poll the server for readiness of a channel. This mainly serves for stream and keyword channels
 */

@interface NMPollChannelTask : NMTask {
	NMChannel * channel;
	BOOL populated;
}

@property (nonatomic, retain) NMChannel * channel;

- (id)initWithChannel:(NMChannel *)chnObj;

@end
