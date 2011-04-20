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

@protocol NMImageDownloadDelegate;
@interface NMCacheController : NSObject {
	NSString * channelThumbnailCacheDir;
	NSFileManager * fileManager;
	
	NSMutableDictionary * channelImageViewMap;
	
	id <NMImageDownloadDelegate> delegate;
		
	// memory image cache
//	NSMutableDictionary * filenameImageMemoryCache; disable in-memory cache for the moment
//	NSMutableArray * imageTemporalList;
}

@property (nonatomic, assign) id <NMImageDownloadDelegate> delegate;

+ (NMCacheController *)sharedCacheController;

- (void)setImageInChannel:(NMChannel *)chn forImageView:(NMTouchImageView *)iv;

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