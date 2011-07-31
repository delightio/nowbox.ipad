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
	NSNotificationCenter * notificationCenter;
	NMChannel * channel;
	NMVideoDetail * videoDetail;
}

@property (nonatomic, retain) NMImageDownloadTask * downloadTask;
@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NMVideoDetail * videoDetail;

- (void)setImageForChannel:(NMChannel *)chn;
- (void)setImageForAuthorThumbnail:(NMVideoDetail *)dtl;

@end
