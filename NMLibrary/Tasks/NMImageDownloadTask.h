//
//  NMImageDownloadTask.h
//  ipad
//
//  Created by Bill So on 20/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMTask.h"

@class NMCategory;
@class NMChannel;
@class NMPreviewThumbnail;
@class NMVideo;
@class NMVideoDetail;
@class NMCacheController;

@interface NMImageDownloadTask : NMTask {
	NSString * imageURLString;
	NSString * originalImagePath;
	NMCategory * category;
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

@property (nonatomic, retain) NMCategory * category;
@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NMPreviewThumbnail * previewThumbnail;
@property (nonatomic, retain) NMVideo * video;
@property (nonatomic, retain) NMVideoDetail * videoDetail;
@property (nonatomic, retain) NSString * imageURLString;
@property (nonatomic, retain) NSString * externalID;
@property (nonatomic, retain) UIImage * image;
@property (nonatomic, retain) NSString * originalImagePath;
@property (nonatomic, retain) NSHTTPURLResponse * httpResponse;

+ (NSInteger)commandIndexForCategory:(NMCategory *)cat;
+ (NSInteger)commandIndexForChannel:(NMChannel *)chn;
+ (NSInteger)commandIndexForAuthor:(NMVideoDetail *)dtl;
+ (NSInteger)commandIndexForVideo:(NMVideo *)vdo;
+ (NSInteger)commandIndexForPreviewThumbnail:(NMPreviewThumbnail *)pv;

- (id)initWithCategory:(NMCategory *)cat;
- (id)initWithChannel:(NMChannel *)chn;
- (id)initWithAuthor:(NMVideoDetail *)dtl;
- (id)initWithVideoThumbnail:(NMVideo *)vdo;
- (id)initWithPreviewThumbnail:(NMPreviewThumbnail *)pv;

- (void)retainDownload;
- (void)releaseDownload;

@end
