//
//  NMOpenGraphWatchTask.h
//  ipad
//
//  Created by Bill So on 2/21/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMFacebookTask.h"

@class NMVideo;

@interface NMOpenGraphWatchTask : NMFacebookTask {
	BOOL isPlayingVideo;
}

@property (nonatomic, retain) NSString * externalID;

- (id)initForVideo:(NMVideo *)vdo playsVideo:(BOOL)aflag;

@end
