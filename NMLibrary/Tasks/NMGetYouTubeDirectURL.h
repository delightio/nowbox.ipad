//
//  NMGetYouTubeDirectURL.h
//  Nowmov
//
//  Created by Bill So on 04/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTask.h"

@class NMVideo;

@interface NMGetYouTubeDirectURL : NMTask {
	NMVideo * video;
	NSString * externalID;
	NSString * directURLString;
}

@property (nonatomic, retain) NMVideo * video;
@property (nonatomic, retain) NSString * externalID;
@property (nonatomic, retain) NSString * directURLString;

@end
