//
//  NMCacheController.h
//  Nowmov
//
//  Created by Bill So on 10/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


@class NMFileExistsCache;
@class NMImageDownloadTask;
@class NMCategory;
@class NMChannel;
@class NMPreviewThumbnail;
@class NMVideo;
@class NMVideoDetail;
@class NMAuthor;
@class NMPersonProfile;
@class NMTaskQueueController;
@class NMStyleUtility;
@class NMCachedImageView;


@interface NMCacheController : NSObject {
	NSString * channelThumbnailCacheDir;
	NSString * authorThumbnailCacheDir;
	NSString * videoThumbnailCacheDir;
    NSString * personThumbnailCacheDir;
	NSFileManager * fileManager;
	
	NSMutableDictionary * targetObjectImageViewMap;
	NSMutableDictionary * commandIndexTaskMap;
	NMTaskQueueController * nowboxTaskController;
	NSNotificationCenter * notificationCenter;
	
	NMStyleUtility * styleUtility;
	
	// file existence cache
	NMFileExistsCache * fileExistenceCache;
	
	// memory image cache
//	NSMutableDictionary * filenameImageMemoryCache; disable in-memory cache for the moment
//	NSMutableArray * imageTemporalList;
}

+ (NMCacheController *)sharedCacheController;

// display image from file cache
- (void)setImageForAuthor:(NMAuthor *)anAuthor imageView:(NMCachedImageView *)iv;
- (void)setImageForChannel:(NMChannel *)chn imageView:(NMCachedImageView *)iv;
- (void)setImageForVideo:(NMVideo *)vdo imageView:(NMCachedImageView *)iv;
- (void)setImageForPreviewThumbnail:(NMPreviewThumbnail *)pv imageView:(NMCachedImageView *)iv;
- (void)setImageForCategory:(NMCategory *)cat imageView:(NMCachedImageView *)iv;
- (void)setImageForPersonProfile:(NMPersonProfile *)profile imageView:(NMCachedImageView *)iv;

// interface for NMCachedImageView
- (NMImageDownloadTask *)downloadImageForCategory:(NMCategory *)cat imageView:(NMCachedImageView *)iv;
- (NMImageDownloadTask *)downloadImageForChannel:(NMChannel *)chn imageView:(NMCachedImageView *)iv;
- (NMImageDownloadTask *)downloadImageForAuthor:(NMAuthor *)anAuthor imageView:(NMCachedImageView *)iv;
- (NMImageDownloadTask *)downloadImageForVideo:(NMVideo *)vdo imageView:(NMCachedImageView *)iv;
- (NMImageDownloadTask *)downloadImageForPreviewThumbnail:(NMPreviewThumbnail *)pv imageView:(NMCachedImageView *)iv;
- (NMImageDownloadTask *)downloadImageForPersonProfile:(NMPersonProfile *)profile imageView:(NMCachedImageView *)iv;
//- (void)saveCacheWithInfo:(NSDictionary *)userInfo;

// saving image from server
- (void)writeCategoryImageData:(NSData *)aData withFilename:(NSString *)fname;
- (void)writeAuthorImageData:(NSData *)aData withFilename:(NSString *)fname;
- (void)writeChannelImageData:(NSData *)aData withFilename:(NSString *)fname;
- (void)writeVideoImageData:(NSData *)aData withFileName:(NSString *)fname;
- (void)writePreviewThumbnailImageData:(NSData *)aData withFileName:(NSString *)fname;
- (void)writePersonProfileImageData:(NSData *)aData withFilename:(NSString *)fname;

// notification handler
- (void)handleImageDownloadNotification:(NSNotification *)aNotification;
- (void)handleImageDownloadFailedNotification:(NSNotification *)aNotification;

- (void)cacheWakeUpCheck;

/*
 !This method is called in the app delegate for cache housekeeping
 */
- (void)cleanUpCache;
- (void)cleanBeforeSignout;

// debug
- (void)removeAllFiles;
@end

