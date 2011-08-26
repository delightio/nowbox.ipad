//
//  NMCacheController.m
//  Nowmov
//
//  Created by Bill So on 10/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NMCacheController.h"
#import "NMImageDownloadTask.h"
#import "NMTaskQueueController.h"
#import "NMStyleUtility.h"
#import "NMChannel.h"
#import "NMVideoDetail.h"
#import "NMCachedImageView.h"

#define MEMORY_CACHE_CAPACITY	10
#define CHANNEL_FILE_CACHE_SIZE	100
#define AUTHOR_FILE_CACHE_SIZE	100

static NMCacheController * _sharedCacheController = nil;
static NSString * const JPIndexPathDictionaryKey = @"idxpath";
static NSString * const JPTableViewDictionaryKey = @"table";

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
	
	// check if the cache directory is here or not. If not, create it.
	NSString * docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
	NSString * cacheBaseDir = [docDir stringByAppendingPathComponent:@"image_cache"];
	channelThumbnailCacheDir = [[cacheBaseDir stringByAppendingPathComponent:@"channel_thumbnail"] retain];
	authorThumbnailCacheDir = [[cacheBaseDir stringByAppendingPathComponent:@"author_thumbnail"] retain];
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
	}
		
	targetObjectImageViewMap = [[NSMutableDictionary alloc] initWithCapacity:MEMORY_CACHE_CAPACITY];
	commandIndexTaskMap = [[NSMutableDictionary alloc] initWithCapacity:MEMORY_CACHE_CAPACITY];
	
//	filenameImageMemoryCache = [[NSMutableDictionary alloc] initWithCapacity:MEMORY_CACHE_CAPACITY];
//	imageTemporalList = [[NSMutableArray alloc] initWithCapacity:MEMORY_CACHE_CAPACITY];
		
	return self;
}

- (void)dealloc {
	[targetObjectImageViewMap release];
	[commandIndexTaskMap release];
	[channelThumbnailCacheDir release];
	[authorThumbnailCacheDir release];
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
- (BOOL)setImageForAuthor:(NMVideoDetail *)dtlObj imageView:(NMCachedImageView *)iv {
	if ( dtlObj == nil || iv == nil ) return NO;

	// check if the image is in local file system
	NSString * fPath;
	if ( dtlObj.nm_author_thumbnail_file_name ) {
		fPath = [authorThumbnailCacheDir stringByAppendingPathComponent:dtlObj.nm_author_thumbnail_file_name];
		if ( [fileManager fileExistsAtPath:fPath] ) {
			UIImage * img = [UIImage imageWithContentsOfFile:fPath];
			if ( img ) {
				// file exists in path, load the file
				iv.image = img;
				return YES;
			} else {
				// the file specified by the cache does not exist
				//chn.nm_thumbnail_file_name = nil; deadloop fix https://pipely.lighthouseapp.com/projects/77614-aji/tickets/153
			}
		}
	} else {
		// this extra check is needed because author info is not properly normalized.
		// same author info is stored repeatedly in NMVideoDetail object
		fPath = [authorThumbnailCacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", dtlObj.author_id]];
		if ( [fileManager fileExistsAtPath:fPath] ) {
			iv.image = [UIImage imageWithContentsOfFile:fPath];
			dtlObj.nm_author_thumbnail_file_name = [NSString stringWithFormat:@"%@.jpg", dtlObj.author_id];
			return YES;
		}
		
		fPath = [authorThumbnailCacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", dtlObj.author_id]];
		if ( [fileManager fileExistsAtPath:fPath] ) {
			iv.image = [UIImage imageWithContentsOfFile:fPath];
			dtlObj.nm_author_thumbnail_file_name = [NSString stringWithFormat:@"%@.png", dtlObj.author_id];
			return YES;
		}
	}

	// check if there's already an existing task requesting the image
	NSUInteger idxNum = [NMImageDownloadTask commandIndexForAuthor:dtlObj];
	NMImageDownloadTask * task = [commandIndexTaskMap objectForKey:[NSNumber numberWithUnsignedInteger:idxNum]];
	
	// we have the download task already exist
	if ( task ) {
		// check if "self" is requesting
		if ( [iv.downloadTask commandIndex] == idxNum ) {
			// actually the image view which request for the download task is asking for the same image again (the download hasn't completed yet)
			// do nothing
		} else {
			// listen to notification
			[notificationCenter addObserver:iv selector:@selector(handleImageDownloadNotification:) name:NMDidDownloadImageNotification object:task];
			[notificationCenter addObserver:iv selector:@selector(handleImageDownloadFailedNotification:) name:NMDidFailDownloadImageNotification object:task];
			// release original download count
			[iv.downloadTask releaseDownload];
			// retain download count
			[task retainDownload];
			iv.downloadTask = task;
		}
		iv.image = styleUtility.userPlaceholderImage;
		return YES;
	}

	iv.image = styleUtility.userPlaceholderImage;
	
	return NO;
}

- (BOOL)setImageForChannel:(NMChannel *)chn imageView:(NMCachedImageView *)iv {
	if ( chn == nil || iv == nil ) return NO;
	// check if the image is in local file system
	if ( [chn.nm_id integerValue] < 0 ) {
		// load from file system
		iv.image = [UIImage imageWithContentsOfFile:chn.thumbnail_uri];
		return YES;
	} else if ( chn.nm_thumbnail_file_name ) {
		NSString * fPath = [channelThumbnailCacheDir stringByAppendingPathComponent:chn.nm_thumbnail_file_name];
		if ( [fileManager fileExistsAtPath:fPath] ) {
			UIImage * img = [UIImage imageWithContentsOfFile:fPath];
			if ( img ) {
				// file exists in path, load the file
				iv.image = img;
				return YES;
			} else {
				// the file specified by the cache does not exist
				//chn.nm_thumbnail_file_name = nil; deadloop fix https://pipely.lighthouseapp.com/projects/77614-aji/tickets/153
			}
		}
	}

	// check if there's already an existing task requesting the image
	NSUInteger idxNum = [NMImageDownloadTask commandIndexForChannel:chn];
	NMImageDownloadTask * task = [commandIndexTaskMap objectForKey:[NSNumber numberWithUnsignedInteger:idxNum]];
	
	// we have the download task already exist
	if ( task ) {
		// check if "self" is requesting
		if ( [iv.downloadTask commandIndex] == idxNum ) {
			// actually the image view which request for the download task is asking for the same image again (the download hasn't completed yet)
			// do nothing
		} else {
			// listen to notification
			[notificationCenter addObserver:iv selector:@selector(handleImageDownloadNotification:) name:NMDidDownloadImageNotification object:task];
			[notificationCenter addObserver:iv selector:@selector(handleImageDownloadFailedNotification:) name:NMDidFailDownloadImageNotification object:task];
			// release original download count
			[iv.downloadTask releaseDownload];
			// retain download count
			[task retainDownload];
			iv.downloadTask = task;
		}
		iv.image = styleUtility.userPlaceholderImage;
		return YES;
	}
	
	iv.image = styleUtility.userPlaceholderImage;
	
	return NO;
}

- (NMImageDownloadTask *)downloadImageForChannel:(NMChannel *)chn {
	NSNumber * idxNum = [NSNumber numberWithUnsignedInteger:[NMImageDownloadTask commandIndexForChannel:chn]];
	NMImageDownloadTask * task = [commandIndexTaskMap objectForKey:idxNum];
	if ( task == nil ) {
		task = [nowmovTaskController issueGetThumbnailForChannel:chn];
		if ( task ) [commandIndexTaskMap setObject:task forKey:[NSNumber numberWithUnsignedInteger:[task commandIndex]]];
	}
	return task;
}

- (NMImageDownloadTask *)downloadImageForAuthor:(NMVideoDetail *)dtl {
	NSNumber * idxNum = [NSNumber numberWithUnsignedInteger:[NMImageDownloadTask commandIndexForAuthor:dtl]];
	NMImageDownloadTask * task = [commandIndexTaskMap objectForKey:idxNum];
	if ( task == nil ) {
		task = [nowmovTaskController issueGetThumbnailForAuthor:dtl];
		if ( task ) [commandIndexTaskMap setObject:task forKey:[NSNumber numberWithUnsignedInteger:[task commandIndex]]];
	}
	return task;
}

- (void)handleImageDownloadNotification:(NSNotification *)aNotification {
	NMImageDownloadTask * theTask = [aNotification object];
	[commandIndexTaskMap removeObjectForKey:[NSNumber numberWithUnsignedInteger:[theTask commandIndex]]];
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

@end
