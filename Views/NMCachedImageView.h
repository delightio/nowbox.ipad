//
//  NMCachedImageView.h
//  ipad
//
//  Created by Bill So on 30/7/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "NMLibrary.h"

@interface NMCachedImageView : UIImageView {
	NMCacheController * cacheController;
	NMImageDownloadTask * downloadTask;
//	NSNotificationCenter * notificationCenter;
	NMCategory * category;
	NMChannel * channel;
	NMVideo * video;
	NMVideoDetail * videoDetail;
	NMPreviewThumbnail * previewThumbnail;
}

@property (nonatomic, retain) NMImageDownloadTask * downloadTask;
@property (nonatomic, retain) NMCategory * category;
@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NMVideo * video;
@property (nonatomic, retain) NMVideoDetail * videoDetail;
@property (nonatomic, retain) NMPreviewThumbnail * previewThumbnail;

- (void)setImageForChannel:(NMChannel *)chn;
- (void)setImageForAuthorThumbnail:(NMVideoDetail *)dtl;
- (void)setImageForVideoThumbnail:(NMVideo *)vdo;
- (void)setImageForPreviewThumbnail:(NMPreviewThumbnail *)pv;
- (void)setImageForCategory:(NMCategory *)cat;

- (void)delayedIssueChannelImageDownloadRequest;
- (void)delayedIssueAuthorImageDownloadRequest;
- (void)delayedIssueVideoImageDownloadRequest;

- (void)cancelDownload;

@end
