//
//  NMCacheController.h
//  Nowmov
//
//  Created by Bill So on 10/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


@class NMImageDownloadTask;
@class NMChannel;
@class NMVideoDetail;
@class NMTaskQueueController;
@class NMStyleUtility;
@class NMCachedImageView;


@interface NMCacheController : NSObject {
	NSString * channelThumbnailCacheDir;
	NSString * authorThumbnailCacheDir;
	NSFileManager * fileManager;
	
	NSMutableDictionary * targetObjectImageViewMap;
	NSMutableDictionary * commandIndexTaskMap;
	NMTaskQueueController * nowmovTaskController;
	NSNotificationCenter * notificationCenter;
	
	NMStyleUtility * styleUtility;
	
	// memory image cache
//	NSMutableDictionary * filenameImageMemoryCache; disable in-memory cache for the moment
//	NSMutableArray * imageTemporalList;
}

+ (NMCacheController *)sharedCacheController;

// display image from file cache
- (BOOL)setImageForAuthor:(NMVideoDetail *)dtlObj imageView:(NMCachedImageView *)iv;
- (BOOL)setImageForChannel:(NMChannel *)chn imageView:(NMCachedImageView *)iv;

// interface for NMCachedImageView
- (NMImageDownloadTask *)downloadImageForChannel:(NMChannel *)chn;
- (NMImageDownloadTask *)downloadImageForAuthor:(NMVideoDetail *)dtl;
//- (void)saveCacheWithInfo:(NSDictionary *)userInfo;

// saving image from server
- (void)writeAuthorImageData:(NSData *)aData withFilename:(NSString *)fname;- (void)writeChannelImageData:(NSData *)aData withFilename:(NSString *)fname;

- (void)cacheWakeUpCheck;

/*
 !This method is called in the app delegate for cache housekeeping
 */
- (void)cleanUpCache;
- (void)cleanBeforeSignout;
@end

