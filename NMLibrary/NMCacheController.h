//
//  NMCacheController.h
//  Nowmov
//
//  Created by Bill So on 10/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


@class NMImageDownloadTask;
@class NMTouchImageView;
@class NMChannel;
@class NMTaskQueueController;

@protocol NMImageDownloadDelegate;
@interface NMCacheController : NSObject {
	NSString * channelThumbnailCacheDir;
	NSFileManager * fileManager;
	
	NSMutableDictionary * channelImageViewMap;
	NMTaskQueueController * nowmovTaskController;
	
	id <NMImageDownloadDelegate> delegate;
		
	// memory image cache
//	NSMutableDictionary * filenameImageMemoryCache; disable in-memory cache for the moment
//	NSMutableArray * imageTemporalList;
}

@property (nonatomic, assign) id <NMImageDownloadDelegate> delegate;

+ (NMCacheController *)sharedCacheController;

// display image from file cache
- (BOOL)setImageInChannel:(NMChannel *)chn forImageView:(UIImageView *)iv;

// saving image from server
- (void)writeImageData:(NSData *)aData withFilename:(NSString *)fname;

- (void)cacheWakeUpCheck;

/*
 !This method is called in the app delegate for cache housekeeping
 */
- (void)cleanUpCache;
- (void)cleanBeforeSignout;
@end

@protocol NMImageDownloadDelegate

@optional
- (void)tableView:(UITableView *)table imageDidLoadAtIndexPath:(NSIndexPath *)indexPath;

@end