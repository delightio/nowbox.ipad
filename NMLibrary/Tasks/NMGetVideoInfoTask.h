//
//  NMGetVideoInfoTask.h
//  Nowmov
//
//  Created by Bill So on 10/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//


#import "NMTask.h"

@class NMVideo;

@interface NMGetVideoInfoTask : NMTask {
	NMVideo * video;
	NSInteger videoID;
	NSDictionary * infoDictionary;
}

@property (nonatomic, retain) NMVideo * video;

@end
