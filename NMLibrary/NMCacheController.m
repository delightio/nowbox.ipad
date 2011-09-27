//
//  NMCacheController.m
//  Nowmov
//
//  Created by Bill So on 10/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NMCacheController.h"
#import "NMFileExistsCache.h"
#import "NMImageDownloadTask.h"
#import "NMTaskQueueController.h"
#import "NMStyleUtility.h"
#import "NMChannel.h"
#import "NMPreviewThumbnail.h"
#import "NMVideoDetail.h"
#import "NMCachedImageView.h"

#define MEMORY_CACHE_CAPACITY	10
#define CHANNEL_FILE_CACHE_SIZE	100
#define AUTHOR_FILE_CACHE_SIZE	100

static NMCacheController * _sharedCacheController = nil;
static NSString * const JPIndexPathDictionaryKey = @"idxpath";
static NSString * const JPTableViewDictionaryKey = @"table";

extern NSString * const NMChannelManagementWillAppearNotification;
extern NSString * const NMChannelManagementDidDisappearNotification;

@implementation NMCacheController

+ (NMCacheController *)sharedCacheController {
	if ( !_sharedCacheController ) {
		_sharedCacheController = [[NMCacheController alloc] init];
	}
	return _sharedCacheController;
}

- (id)init {
	self = [super init];
	
	styleUtility = [NMStyleUtility sharedStyleUtility];
	nowmovTaskController = [NMTaskQueueController sharedTaskQueueController];
	notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(handleImageDownloadNotification:) name:NMDidDownloadImageNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(handleImageDownloadFailedNotification:) name:NMDidFailDownloadImageNotification object:nil];
	
	// listen to channel management view notification
	[notificationCenter addObserver:self selector:@selector(handleCleanUpCacheNotification:) name:NMChannelManagementDidDisappearNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(handleCleanUpCacheNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
	
	// check if the cache directory is here or not. If not, create it.
	NSString * docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
	NSString * cacheBaseDir = [docDir stringByAppendingPathComponent:@"image_cache"];
	channelThumbnailCacheDir = [[cacheBaseDir stringByAppendingPathComponent:@"channel_thumbnail"] retain];
	authorThumbnailCacheDir = [[cacheBaseDir stringByAppendingPathComponent:@"author_thumbnail"] retain];
	videoThumbnailCacheDir = [[cacheBaseDir stringByAppendingPathComponent:@"video_thumbnail"] retain];
	// file manager
	fileManager = [[NSFileManager alloc] init];
	
	if ( ![fileManager fileExistsAtPath:cacheBaseDir] ) {
		// create the basic structure
		//	image_cache
		//		/channel_thumbnail
		//		/author_thumbnail
		NSError * error = nil;
		[fileManager createDirectoryAtPath:channelThumbnailCacheDir withIntermediateDirectories:YES attributes:nil error:&error];
		if ( error ) {
			// raise exception
			NSException * e = [NSException exceptionWithName:@"CacheError" reason:@"cannot create cache directory" userInfo:nil];
			[e raise];
		}
		[fileManager createDirectoryAtPath:authorThumbnailCacheDir withIntermediateDirectories:YES attributes:nil error:&error];
		if ( error ) {
			// raise exception
			NSException * e = [NSException exceptionWithName:@"CacheError" reason:@"cannot create cache directory" userInfo:nil];
			[e raise];
		}
		[fileManager createDirectoryAtPath:videoThumbnailCacheDir withIntermediateDirectories:YES attributes:nil error:&error];
		if ( error ) {
			NSException * e = [NSException exceptionWithName:@"CacheError" reason:@"cannot create cache directory" userInfo:nil];
			[e raise];
		}
	}
	
	fileExistenceCache = [[NMFileExistsCache alloc] initWithCapacity:48];
		
	targetObjectImageViewMap = [[NSMutableDictionary alloc] initWithCapacity:MEMORY_CACHE_CAPACITY];
	commandIndexTaskMap = [[NSMutableDictionary alloc] initWithCapacity:MEMORY_CACHE_CAPACITY];
	
//	filenameImageMemoryCache = [[NSMutableDictionary alloc] initWithCapacity:MEMORY_CACHE_CAPACITY];
//	imageTemporalList = [[NSMutableArray alloc] initWithCapacity:MEMORY_CACHE_CAPACITY];
		
	return self;
}

- (void)dealloc {
	[fileExistenceCache release];
	[targetObjectImageViewMap release];
	[commandIndexTaskMap release];
	[channelThumbnailCacheDir release];
	[authorThumbnailCacheDir release];
	[videoThumbnailCacheDir release];
	[fileManager release];
	[super dealloc];
}

//- (UIImage *)imageCachedWithFilename:(NSString *)afile {
//	return [filenameImageMemoryCache objectForKey:afile];
//}
//
//- (void)addImage:(UIImage *)img withFilename:(NSString *)filename {
//	if ( [filenameImageMemoryCache objectForKey:filename] ) return;
//	if ( [imageTemporalList count] >= MEMORY_CACHE_CAPACITY ) {
//		// remove index 0 item
//		NSString * theKey = [imageTemporalList objectAtIndex:0];
//		[filenameImageMemoryCache removeObjectForKey:theKey];
//		[imageTemporalList removeObjectAtIndex:0];
//	}
//	// add item
//
//	if(img) {
//		[filenameImageMemoryCache setObject:img forKey:filename];
//		[imageTemporalList addObject:filename];
//	}
//}
//

#pragma mark load image
- (void)setImageForAuthor:(NMVideoDetail *)dtlObj imageView:(NMCachedImageView *)iv {
	if ( dtlObj == nil || iv == nil ) return;

	// check if the image is in local file system
	NSString * fPath;
	NMFileExistsType t;
	if ( [dtlObj.nm_author_thumbnail_file_name length] ) {
		fPath = [authorThumbnailCacheDir stringByAppendingPathComponent:dtlObj.nm_author_thumbnail_file_name];
		t = [fileExistenceCache fileExistsAtPath:fPath];
		if ( t == NMFileExistsNotCached ) {
			BOOL ex = [fileManager fileExistsAtPath:fPath];
			[fileExistenceCache setFileExists:ex atPath:fPath];
			t = ex ? NMFileExists : NMFileDoesNotExist;
		}
		if ( t == NMFileExists ) {
			UIImage * img = [UIImage imageWithContentsOfFile:fPath];
			if ( img ) {
				// file exists in path, load the file
				iv.image = img;
				return;
			} else {
				// the file specified by the cache does not exist
				//chn.nm_thumbnail_file_name = nil; deadloop fix https://pipely.lighthouseapp.com/projects/77614-aji/tickets/153
			}
		}
	} else {
		// this extra check is needed because author info is not properly normalized.
		// same author info is stored repeatedly in NMVideoDetail object
		fPath = [authorThumbnailCacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", dtlObj.author_id]];
		t = [fileExistenceCache fileExistsAtPath:fPath];
		if ( t == NMFileExistsNotCached ) {
			BOOL ex = [fileManager fileExistsAtPath:fPath];
			[fileExistenceCache setFileExists:ex atPath:fPath];
			t = ex ? NMFileExists : NMFileDoesNotExist;
		}
		if ( t == NMFileExists ) {
			iv.image = [UIImage imageWithContentsOfFile:fPath];
			dtlObj.nm_author_thumbnail_file_name = [NSString stringWithFormat:@"%@.jpg", dtlObj.author_id];
			return;
		}
		
		fPath = [authorThumbnailCacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", dtlObj.author_id]];
		t = [fileExistenceCache fileExistsAtPath:fPath];
		if ( t == NMFileExistsNotCached ) {
			BOOL ex = [fileManager fileExistsAtPath:fPath];
			[fileExistenceCache setFileExists:ex atPath:fPath];
			t = ex ? NMFileExists : NMFileDoesNotExist;
		}
		if ( t == NMFileExists ) {
			iv.image = [UIImage imageWithContentsOfFile:fPath];
			dtlObj.nm_author_thumbnail_file_name = [NSString stringWithFormat:@"%@.png", dtlObj.author_id];
			return;
		}
	}
	
	if ( [dtlObj.author_thumbnail_uri length] ) {
		// check if there's already an existing task requesting the image
		NSUInteger idxNum = [NMImageDownloadTask commandIndexForAuthor:dtlObj];
		NMImageDownloadTask * task = [commandIndexTaskMap objectForKey:[NSNumber numberWithUnsignedInteger:idxNum]];
		
		// cancel previous delayed method
		[NSObject cancelPreviousPerformRequestsWithTarget:iv];
		// we have the download task already exist
		if ( task ) {
			// check if "self" is requesting
			if ( [iv.downloadTask commandIndex] == idxNum ) {
				// actually the image view which request for the download task is asking for the same image again (the download hasn't completed yet)
				// do nothing
			} else {
				// stop listening the notification
				[notificationCenter removeObserver:iv];
				// listen to notification
				[notificationCenter addObserver:iv selector:@selector(handleImageDownloadNotification:) name:NMDidDownloadImageNotification object:task];
				[notificationCenter addObserver:iv selector:@selector(handleImageDownloadFailedNotification:) name:NMDidFailDownloadImageNotification object:task];
				// release original download count
				[iv.downloadTask releaseDownload];
				// retain download count
				[task retainDownload];
				iv.downloadTask = task;
			}
		} else {
			if ( iv.downloadTask ) {
				// stop listening
				[notificationCenter removeObserver:iv];
				[iv.downloadTask releaseDownload];
				iv.downloadTask = nil;
			}
			// no existing download task for this image. create new download task
			[iv delayedIssueAuthorImageDownloadRequest];
		}
	}

	iv.image = styleUtility.userPlaceholderImage;
	
}

- (void)setImageForChannel:(NMChannel *)chn imageView:(NMCachedImageView *)iv {
	if ( chn == nil || iv == nil ) return;
	// check if the image is in local file system
	if ( [chn.nm_thumbnail_file_name length] ) {
		NSString * fPath = [channelThumbnailCacheDir stringByAppendingPathComponent:chn.nm_thumbnail_file_name];
		NMFileExistsType t = [fileExistenceCache fileExistsAtPath:fPath];
		if ( t == NMFileExistsNotCached ) {
			BOOL ex = [fileManager fileExistsAtPath:fPath];
			[fileExistenceCache setFileExists:ex atPath:fPath];
			t = ex ? NMFileExists : NMFileDoesNotExist;
		}
		if ( t == NMFileExists ) {
			UIImage * img = [UIImage imageWithContentsOfFile:fPath];
			if ( img ) {
				// file exists in path, load the file
				iv.image = img;
				return;
			} else {
				// the file specified by the cache does not exist
				//chn.nm_thumbnail_file_name = nil; deadloop fix https://pipely.lighthouseapp.com/projects/77614-aji/tickets/153
			}
		}
	}
	// check if the channel contains a uri
	if ( [chn.thumbnail_uri length] ) {
		// check if there's already an existing task requesting the image
		NSUInteger idxNum = [NMImageDownloadTask commandIndexForChannel:chn];
		NMImageDownloadTask * task = [commandIndexTaskMap objectForKey:[NSNumber numberWithUnsignedInteger:idxNum]];
		
		// cancel previous delayed method
		[NSObject cancelPreviousPerformRequestsWithTarget:iv];
		// we have the download task already exists for the current channel thumbnail image
		if ( task ) {
			// check if "self" is requesting
			if ( [iv.downloadTask commandIndex] == idxNum ) {
				// actually the image view which request for the download task is asking for the same image again (the download hasn't completed yet)
				// do nothing
			} else {
				// stop listening the notification
				[notificationCenter removeObserver:iv];
				// listen to notification
				[notificationCenter addObserver:iv selector:@selector(handleImageDownloadNotification:) name:NMDidDownloadImageNotification object:task];
				[notificationCenter addObserver:iv selector:@selector(handleImageDownloadFailedNotification:) name:NMDidFailDownloadImageNotification object:task];
				// release original download count
				[iv.downloadTask releaseDownload];
				// retain download count
				[task retainDownload];
				iv.downloadTask = task;
			}
		} else {
			// the channel does not contain any existing download task.
			// check the image view if it contains a download task
			if ( iv.downloadTask ) {
				// stop listening
				[notificationCenter removeObserver:iv];
				[iv.downloadTask releaseDownload];
				iv.downloadTask = nil;
			}
			// no existing download task for this image. create new download task
			[iv delayedIssueChannelImageDownloadRequest];
		}
	}
	iv.image = styleUtility.userPlaceholderImage;
	
}

- (void)setImageForVideo:(NMVideo *)vdo imageView:(NMCachedImageView *)iv {
	if ( vdo == nil || iv == nil ) return;
#ifdef DEBUG_IMAGE_CACHE
	NSLog(@"running cache controller logic for %@", vdo.title);
#endif
	// check if the file exists
	if ( [vdo.nm_thumbnail_file_name length] ) {
		NSString * fPath = [videoThumbnailCacheDir stringByAppendingPathComponent:vdo.nm_thumbnail_file_name];
		NMFileExistsType t = [fileExistenceCache fileExistsAtPath:fPath];
		if ( t == NMFileExistsNotCached ) {
			BOOL ex = [fileManager fileExistsAtPath:fPath];
			[fileExistenceCache setFileExists:ex atPath:fPath];
			t = ex ? NMFileExists : NMFileDoesNotExist;
		}
		
		if ( t == NMFileExists ) {
			// open up the file
			UIImage * img = [UIImage imageWithContentsOfFile:fPath];
			if ( img ) {
				iv.image = img;
				return;
			}
		}
	}
	if ( [vdo.thumbnail_uri length] ) {
		// check if there's already an existing task requesting the image
		NSUInteger idxNum = [NMImageDownloadTask commandIndexForVideo:vdo];
		NMImageDownloadTask * task = [commandIndexTaskMap objectForKey:[NSNumber numberWithUnsignedInteger:idxNum]];
		// no delay download in video thumbnail. therefore, there's no need to cancel previous perform request
		if ( task ) {
			// check if "self" is requesting
			if ( [iv.downloadTask commandIndex] == idxNum ) {
				// actually the image view which request for the download task is asking for the same image again (the download hasn't completed yet)
				// do nothing
			} else {
				// stop listening the notification
				[notificationCenter removeObserver:iv];
				// listen to notification
				[notificationCenter addObserver:iv selector:@selector(handleImageDownloadNotification:) name:NMDidDownloadImageNotification object:task];
				[notificationCenter addObserver:iv selector:@selector(handleImageDownloadFailedNotification:) name:NMDidFailDownloadImageNotification object:task];
				// release original download count
				[iv.downloadTask releaseDownload];
				// retain download count
				[task retainDownload];
				iv.downloadTask = task;
			}
		} else {
			// the video does not contain any existing download task
			if ( iv.downloadTask ) {
				// stop listening
				[notificationCenter removeObserver:iv];
				[iv.downloadTask releaseDownload];
				iv.downloadTask = nil;
			}
			[iv delayedIssueVideoImageDownloadRequest];
		}
	}
	iv.image = nil;
}

- (void)setImageForPreviewThumbnail:(NMPreviewThumbnail *)pv imageView:(NMCachedImageView *)iv {
	if ( pv == nil || iv == nil ) return;
	// check if the file exists
	NSString * fPath = [videoThumbnailCacheDir stringByAppendingPathComponent:pv.nm_thumbnail_file_name];
	NMFileExistsType t = [fileExistenceCache fileExistsAtPath:fPath];
	if ( t == NMFileExistsNotCached ) {
		BOOL ex = [fileManager fileExistsAtPath:fPath];
		[fileExistenceCache setFileExists:ex atPath:fPath];
		t = ex ? NMFileExists : NMFileDoesNotExist;
	}
	if ( t == NMFileExists ) {
		// open up the file
		UIImage * img = [UIImage imageWithContentsOfFile:fPath];
		if ( img ) {
			iv.image = img;
			return;
		}
	}
	// check if the PV contains valid uri
	if ( [pv.thumbnail_uri length] ) {
		NSUInteger idxNum = [NMImageDownloadTask commandIndexForPreviewThumbnail:pv];
		NMImageDownloadTask * task = [commandIndexTaskMap objectForKey:[NSNumber numberWithUnsignedInteger:idxNum]];
		// image view used for showing preview thumbnail does not support delayed call
		if ( task ) {
			// check if "self" is requesting
			if ( [iv.downloadTask commandIndex] == idxNum ) {
				// actually the image view which request for the download task is asking for the same image again (the download hasn't completed yet)
				// do nothing
			} else {
				// stop listening to notificaiton
				[notificationCenter removeObserver:iv];
				// listen to notification
				[notificationCenter addObserver:iv selector:@selector(handleImageDownloadNotification:) name:NMDidDownloadImageNotification object:task];
				[notificationCenter addObserver:iv selector:@selector(handleImageDownloadFailedNotification:) name:NMDidFailDownloadImageNotification object:task];
				// release original download count
				[iv.downloadTask releaseDownload];
				// retain download count
				[task retainDownload];
				iv.downloadTask = task;
			}
		} else {
			if ( iv.downloadTask ) {
				// stop listening
				[notificationCenter removeObserver:iv];
				[iv.downloadTask releaseDownload];
				iv.downloadTask = nil;
			}
			// create download task
			[self downloadImageForPreviewThumbnail:pv imageView:iv];
		}
	}
	iv.image = nil;
}

- (NMImageDownloadTask *)downloadImageForChannel:(NMChannel *)chn imageView:(NMCachedImageView *)iv {
	NSNumber * idxNum = [NSNumber numberWithUnsignedInteger:[NMImageDownloadTask commandIndexForChannel:chn]];
	NMImageDownloadTask * task = [commandIndexTaskMap objectForKey:idxNum];
	if ( task == nil ) {
		task = [nowmovTaskController issueGetThumbnailForChannel:chn];
		if ( task ) [commandIndexTaskMap setObject:task forKey:[NSNumber numberWithUnsignedInteger:[task commandIndex]]];
	}
	iv.downloadTask = task;
	[notificationCenter addObserver:iv selector:@selector(handleImageDownloadNotification:) name:NMDidDownloadImageNotification object:task];
	[notificationCenter addObserver:iv selector:@selector(handleImageDownloadFailedNotification:) name:NMDidFailDownloadImageNotification object:task];
	return task;
}

- (NMImageDownloadTask *)downloadImageForAuthor:(NMVideoDetail *)dtl imageView:(NMCachedImageView *)iv {
	NSNumber * idxNum = [NSNumber numberWithUnsignedInteger:[NMImageDownloadTask commandIndexForAuthor:dtl]];
	NMImageDownloadTask * task = [commandIndexTaskMap objectForKey:idxNum];
	if ( task == nil ) {
		task = [nowmovTaskController issueGetThumbnailForAuthor:dtl];
		if ( task ) [commandIndexTaskMap setObject:task forKey:[NSNumber numberWithUnsignedInteger:[task commandIndex]]];
	}
	iv.downloadTask = task;
	[notificationCenter addObserver:iv selector:@selector(handleImageDownloadNotification:) name:NMDidDownloadImageNotification object:task];
	[notificationCenter addObserver:iv selector:@selector(handleImageDownloadFailedNotification:) name:NMDidFailDownloadImageNotification object:task];
	return task;
}

- (NMImageDownloadTask *)downloadImageForVideo:(NMVideo *)vdo imageView:(NMCachedImageView *)iv {
	NSNumber * idxNum = [NSNumber numberWithUnsignedInteger:[NMImageDownloadTask commandIndexForVideo:vdo]];
	NMImageDownloadTask * task = [commandIndexTaskMap objectForKey:idxNum];
	if ( task == nil ) {
		task = [nowmovTaskController issueGetThumbnailForVideo:vdo];
		if ( task ) [commandIndexTaskMap setObject:task forKey:[NSNumber numberWithUnsignedInteger:[task commandIndex]]];
	}
	iv.downloadTask = task;
	[notificationCenter addObserver:iv selector:@selector(handleImageDownloadNotification:) name:NMDidDownloadImageNotification object:task];
	[notificationCenter addObserver:iv selector:@selector(handleImageDownloadFailedNotification:) name:NMDidFailDownloadImageNotification object:task];
	return task;
}

- (NMImageDownloadTask *)downloadImageForPreviewThumbnail:(NMPreviewThumbnail *)pv imageView:(NMCachedImageView *)iv {
	NSNumber * idxNum = [NSNumber numberWithUnsignedInteger:[NMImageDownloadTask commandIndexForPreviewThumbnail:pv]];
#ifdef DEBUG_IMAGE_CACHE
	NSLog(@"preview thumbnail download - command index: %@", idxNum);
#endif
	NMImageDownloadTask * task = [commandIndexTaskMap objectForKey:idxNum];
	if ( task == nil ) {
		task = [nowmovTaskController issueGetPreviewThumbnail:pv];
		if ( task ) {
			[commandIndexTaskMap setObject:task forKey:[NSNumber numberWithUnsignedInteger:[task commandIndex]]];
#ifdef DEBUG_IMAGE_CACHE
			NSLog(@"preview thumbnail download - new command index: %d", [task commandIndex]);
#endif
		}
	}
	iv.downloadTask = task;
	[notificationCenter addObserver:iv selector:@selector(handleImageDownloadNotification:) name:NMDidDownloadImageNotification object:task];
	[notificationCenter addObserver:iv selector:@selector(handleImageDownloadFailedNotification:) name:NMDidFailDownloadImageNotification object:task];

	return task;
}

- (void)handleImageDownloadNotification:(NSNotification *)aNotification {
	NMImageDownloadTask * theTask = [aNotification object];
	NSManagedObject * obj = [[aNotification userInfo] objectForKey:@"target_object"];
	[commandIndexTaskMap removeObjectForKey:[NSNumber numberWithUnsignedInteger:[theTask commandIndex]]];
	// update the cache
	NSString * path = nil;
	switch (theTask.command) {
		case NMCommandGetAuthorThumbnail:
			path = [obj valueForKey:@"nm_author_thumbnail_file_name"];
			break;
			
		case NMCommandGetChannelThumbnail:
			path = [obj valueForKey:@"nm_thumbnail_file_name"];
			break;
			
		case NMCommandGetVideoThumbnail:
			path = [obj valueForKey:@"nm_thumbnail_file_name"];
			break;
			
		case NMCommandGetPreviewThumbnail:
			path = [obj valueForKey:@"nm_thumbnail_file_name"];
			break;
			
		default:
			break;
	}
	if ( path ) [fileExistenceCache setFileExists:YES atPath:path];
}

- (void)handleImageDownloadFailedNotification:(NSNotification *)aNotification {
	NMImageDownloadTask * theTask = [aNotification object];
	[commandIndexTaskMap removeObjectForKey:[NSNumber numberWithUnsignedInteger:[theTask commandIndex]]];
}

#pragma mark save downloaded image
- (void)writeAuthorImageData:(NSData *)aData withFilename:(NSString *)fname {
#ifdef DEBUG_IMAGE_CACHE
	NSLog(@"write author image: %@", [authorThumbnailCacheDir stringByAppendingPathComponent:fname]);
#endif
	[aData writeToFile:[authorThumbnailCacheDir stringByAppendingPathComponent:fname] options:0 error:nil];
}

- (void)writeChannelImageData:(NSData *)aData withFilename:(NSString *)fname {
#ifdef DEBUG_IMAGE_CACHE
	NSLog(@"write channel image: %@", [channelThumbnailCacheDir stringByAppendingPathComponent:fname]);
#endif
	[aData writeToFile:[channelThumbnailCacheDir stringByAppendingPathComponent:fname] options:0 error:nil];
}

- (void)writeVideoImageData:(NSData *)aData withFileName:(NSString *)fname {
#ifdef DEBUG_IMAGE_CACHE
	NSLog(@"write video image: %@", [videoThumbnailCacheDir stringByAppendingPathComponent:fname]);
#endif
	[aData writeToFile:[videoThumbnailCacheDir stringByAppendingPathComponent:fname] options:0 error:nil];
}

- (void)writePreviewThumbnailImageData:(NSData *)aData withFileName:(NSString *)fname {
#ifdef DEBUG_IMAGE_CACHE
	NSLog(@"write preview thumbnail image: %@", [videoThumbnailCacheDir stringByAppendingPathComponent:fname]);
#endif
	[aData writeToFile:[videoThumbnailCacheDir stringByAppendingPathComponent:fname] options:0 error:nil];
}

#pragma mark housekeeping methods
- (void)cacheWakeUpCheck {
	// check the cache when the app is awaken or put to foreground
}

- (void)cleanUpDirectoryAtPath:(NSString *)dirPath withLimit:(NSInteger)maxFileCount {
	NSString * filename;
	NSArray * items = [fileManager contentsOfDirectoryAtPath:dirPath error:NULL];
	NSInteger numFiles = [items count];
	if ( numFiles > maxFileCount ) {
		// remove extra files
		NSDictionary * fAttr;
		NSMutableArray * fileDictAy = [NSMutableArray arrayWithCapacity:numFiles];
		NSString * fNameKey = @"filename";
		for (filename in items) {
			fAttr = [fileManager attributesOfItemAtPath:[dirPath stringByAppendingPathComponent:filename] error:NULL];
			if ( fAttr ) {
				[fileDictAy addObject:[NSDictionary dictionaryWithObjectsAndKeys:filename, fNameKey, [fAttr fileModificationDate], NSFileModificationDate, nil]];
			}
		}
		// sort the items
		NSSortDescriptor * dateSortDesc = [[NSSortDescriptor alloc] initWithKey:NSFileModificationDate ascending:YES];
		[fileDictAy sortUsingDescriptors:[NSArray arrayWithObject:dateSortDesc]];
		numFiles = [fileDictAy count];
		// get the items to delete
		for (NSInteger i = 0; i < numFiles - maxFileCount; i++) {
			[fileManager removeItemAtPath:[dirPath stringByAppendingPathComponent:[fileDictAy objectAtIndex:i]] error:NULL];
		}
	}
}

- (void)cleanUpCache {
	[self cleanUpDirectoryAtPath:channelThumbnailCacheDir withLimit:CHANNEL_FILE_CACHE_SIZE];
}

- (void)cleanBeforeSignout {
	
}

- (void)handleCleanUpCacheNotification:(NSNotification *)aNotification {
	// clean up channel thumbnail and video thumbnail files cache. Make sure they do not exceed the cap respectively.
	
}

@end
