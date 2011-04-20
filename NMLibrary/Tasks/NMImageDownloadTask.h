//
//  NMImageDownloadTask.h
//  ipad
//
//  Created by Bill So on 20/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTask.h"

@class NMChannel;
@class NMCacheController;

@interface NMImageDownloadTask : NMTask {
	NSString * imageURLString;
	NSString * originalImagePath;
	NMChannel * channel;
	NSHTTPURLResponse * httpResponse;
	NMCacheController * cacheController;
}

@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NSString * imageURLString;
@property (nonatomic, retain) NSString * originalImagePath;
@property (nonatomic, retain) NSHTTPURLResponse * httpResponse;

- (id)initWithChannel:(NMChannel *)chn;

@end
