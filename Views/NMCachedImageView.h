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
	NMCategory * category;
	NMChannel * channel;
	NMVideo * video;
	NMAuthor * author;
	NMPreviewThumbnail * previewThumbnail;
}

@property (nonatomic, retain) NMImageDownloadTask * downloadTask;
@property (nonatomic, retain) NMCategory * category;
@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NMVideo * video;
@property (nonatomic, retain) NMAuthor * author;
@property (nonatomic, retain) NMPreviewThumbnail * previewThumbnail;
@property (nonatomic, assign) BOOL adjustsImageOnHighlight;

- (void)setImageForChannel:(NMChannel *)chn;
- (void)setImageForAuthorThumbnail:(NMAuthor *)anAuthor;
- (void)setImageForVideoThumbnail:(NMVideo *)vdo;
- (void)setImageForPreviewThumbnail:(NMPreviewThumbnail *)pv;
- (void)setImageForCategory:(NMCategory *)cat;

- (void)delayedIssueChannelImageDownloadRequest;
- (void)delayedIssueAuthorImageDownloadRequest;
- (void)delayedIssueVideoImageDownloadRequest;

- (void)cancelDownload;

@end
