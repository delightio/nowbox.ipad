//
//  NMEventTask.h
//  ipad
//
//  Created by Bill So on 06/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTask.h"
#import "NMDataType.h"


@class NMVideo;

@interface NMEventTask : NMTask {
    NSInteger videoID;
	NMEventType eventType;
	CGFloat duration;	// duration of video
	CGFloat elapsedSeconds;	// time elapse
	NMVideo * video;
	NSInteger errorCode;
	BOOL playedToEnd;
}

@property (nonatomic, retain) NMVideo * video;
@property (nonatomic) CGFloat elapsedSeconds;
@property (nonatomic) CGFloat duration;
@property (nonatomic) BOOL playedToEnd;
@property (nonatomic) NSInteger errorCode;

- (id)initWithEventType:(NMEventType)evtType forVideo:(NMVideo *)v;

@end
