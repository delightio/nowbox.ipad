//
//  NMEventTask.h
//  ipad
//
//  Created by Bill So on 06/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTask.h"
#import "NMDataType.h"

@class NMChannel;
@class NMVideo;

@interface NMEventTask : NMTask {
	NMEventType eventType;
//	CGFloat duration;	// duration of video
	NSInteger elapsedSeconds;	// time elapse
	NSInteger startSecond;
	NMVideo * video;
	NMChannel * channel;
	NSNumber * channelID;
	NSDictionary * resultDictionary;
	BOOL playedToEnd;
	BOOL bulkSubscribe;
}

@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NMVideo * video;
@property (nonatomic, retain) NSNumber * channelID;
@property (nonatomic, retain) NSDictionary * resultDictionary;
@property (nonatomic) NSInteger elapsedSeconds;
@property (nonatomic) NSInteger startSecond;
//@property (nonatomic) CGFloat duration;
@property (nonatomic) BOOL playedToEnd;
@property (nonatomic) BOOL bulkSubscribe;

- (id)initWithEventType:(NMEventType)evtType forVideo:(NMVideo *)v;
- (id)initWithChannel:(NMChannel *)aChn subscribe:(BOOL)abool;

@end
