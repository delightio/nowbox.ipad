//
//  NMImageDownloadTask.h
//  ipad
//
//  Created by Bill So on 20/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTask.h"

@class NMChannel;
@class NMPreviewThumbnail;
@class NMVideo;
@class NMVideoDetail;
@class NMCacheController;

@interface NMImageDownloadTask : NMTask {
	NSString * imageURLString;
	NSString * originalImagePath;
	NMChannel * channel;
	NMVideoDetail * videoDetail;
	NMVideo * video;
	NMPreviewThumbnail * previewThumbnail;
	NSString * externalID;
	UIImage * image;
	NSHTTPURLResponse * httpResponse;
	NMCacheController * cacheController;
	NSInteger retainCount;
}

@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NMPreviewThumbnail * previewThumbnail;
@property (nonatomic, retain) NMVideo * video;
@property (nonatomic, retain) NMVideoDetail * videoDetail;
@property (nonatomic, retain) NSString * imageURLString;
@property (nonatomic, retain) NSString * externalID;
@property (nonatomic, retain) UIImage * image;
@property (nonatomic, retain) NSString * originalImagePath;
@property (nonatomic, retain) NSHTTPURLResponse * httpResponse;

+ (NSUInteger)commandIndexForChannel:(NMChannel *)chn;
+ (NSUInteger)commandIndexForAuthor:(NMVideoDetail *)dtl;
+ (NSUInteger)commandIndexForVideo:(NMVideo *)vdo;
+ (NSUInteger)commandIndexForPreviewThumbnail:(NMPreviewThumbnail *)pv;

- (id)initWithChannel:(NMChannel *)chn;
- (id)initWithAuthor:(NMVideoDetail *)dtl;
- (id)initWithVideoThumbnail:(NMVideo *)vdo;
- (id)initWithPreviewThumbnail:(NMPreviewThumbnail *)pv;

- (void)retainDownload;
- (void)releaseDownload;

@end
