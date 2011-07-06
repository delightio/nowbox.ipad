//
//  NMGetChannelVideosTask.h
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTask.h"
#import "NMTaskQueueController.h"

@class NMChannel;

@interface NMRefreshChannelVideoListTask : NMTask {
	NMChannel * channel;
	NSString * urlString;
	NSMutableArray * parsedDetailObjects;
	BOOL newChannel;
	NSUInteger numberOfVideoAdded;
	NSUInteger numberOfVideoRequested;
	id <NMVideoListUpdateDelegate> delegate;
}

@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NSString * urlString;
@property (nonatomic) NSUInteger numberOfVideoRequested;
@property (nonatomic) BOOL newChannel;
@property (nonatomic, assign) id <NMVideoListUpdateDelegate> delegate;

// in this wind-down version. we only have one single channel - Live
- (id)initWithChannel:(NMChannel *)aChn;

@end
