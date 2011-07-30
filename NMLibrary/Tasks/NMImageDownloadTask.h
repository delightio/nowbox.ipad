//
//  NMImageDownloadTask.h
//  ipad
//
//  Created by Bill So on 20/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTask.h"

@class NMChannel;
@class NMVideoDetail;
@class NMCacheController;

@interface NMImageDownloadTask : NMTask {
	NSString * imageURLString;
	NSString * originalImagePath;
	NMChannel * channel;
	NMVideoDetail * videoDetail;
	UIImage * image;
	NSHTTPURLResponse * httpResponse;
	NMCacheController * cacheController;
	NSInteger retainCount;
}

@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NMVideoDetail * videoDetail;
@property (nonatomic, retain) NSString * imageURLString;
@property (nonatomic, retain) UIImage * image;
@property (nonatomic, retain) NSString * originalImagePath;
@property (nonatomic, retain) NSHTTPURLResponse * httpResponse;

+ (NSUInteger)commandIndexForChannel:(NMChannel *)chn;
+ (NSUInteger)commandIndexForAuthor:(NMVideoDetail *)dtl;

- (id)initWithChannel:(NMChannel *)chn;
- (id)initWithAuthor:(NMVideoDetail *)dtl;

- (void)retainDownload;
- (void)releaseDownload;

@end
