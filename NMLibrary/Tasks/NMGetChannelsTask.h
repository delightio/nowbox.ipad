//
//  NMGetChannelsTask.h
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTask.h"

@class NMChannel;

@interface NMGetChannelsTask : NMTask {
	NSArray * channelJSONKeys;
	NMChannel * liveChannel;
}

@property (nonatomic, retain) NMChannel * liveChannel;

@end
