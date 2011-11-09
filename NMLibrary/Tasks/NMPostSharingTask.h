//
//  NMPostSharingTask.h
//  ipad
//
//  Created by Bill So on 11/7/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMTask.h"

@class NMVideo;

@interface NMPostSharingTask : NMTask {
	NSInteger elapsedSeconds;	// time elapse
	NSInteger startSecond;
	NMVideo * video;
	NSNumber * channelID;
	NSString * message;
	NMSocialLoginType service;
}
@property (nonatomic, retain) NMVideo * video;
@property (nonatomic, retain) NSNumber * channelID;
@property (nonatomic) NSInteger elapsedSeconds;
@property (nonatomic) NSInteger startSecond;
@property (nonatomic, retain) NSString * message;

- (id)initWithType:(NMSocialLoginType)aType video:(NMVideo *)v;

@end
