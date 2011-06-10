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
#import "NMChannel.h"
#import "NMTouchImageView.h"

#define MEMORY_CACHE_CAPACITY	20
#define CHANNEL_FILE_CACHE_SIZE	100

static NMCacheController * _sharedCacheController = nil;
static NSString * const JPIndexPathDictionaryKey = @"idxpath";
static NSString * const JPTableViewDictionaryKey = @"table";

@implementation NMCacheController
@synthesize delegate;

+ (NMCacheController *)sharedCacheController {
	if ( !_sharedCacheController ) {
		_sharedCacheController = [[NMCacheController alloc] init];
	}
	return _sharedCacheController;
}

- (id)init {
	self = [super init];
	
	nowmovTaskController = [NMTaskQueueController sharedTaskQueueController];
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(handleImageDownloadNotification:) name:NMDidDownloadImageNotification object:nil];
	[nc addObserver:self selector:@selector(handleImageDownloadFailedNotification:) name:NMDidFailDownloadImageNotification object:nil];
	
	// check if the cache directory is here or not. If not, create it.
	NSString * docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
	NSString * cacheBaseDir = [docDir stringByAppendingPathComponent:@"image_cache"];
	channelThumbnailCacheDir = [[cacheBaseDir stringByAppendingPathComponent:@"channel_thumbnail"] retain];
	// file manager
	fileManager = [[NSFileManager alloc] init];
	
	if ( ![fileManager fileExistsAtPath:cacheBaseDir] ) {
		// create the basic structure
		//	image_cache
		//		/channel_thumbnail
		NSError * error = nil;
		[fileManager createDirectoryAtPath:channelThumbnailCacheDir withIntermediateDirectories:YES attributes:nil error:&error];
		if ( error ) {
			// raise exception
			NSException * e = [NSException exceptionWithName:@"CacheError" reason:@"cannot create cache directory" userInfo:nil];
			[e raise];
		}
	}
		
	channelImageViewMap = [[NSMutableDictionary alloc] init];
	
//	filenameImageMemoryCache = [[NSMutableDictionary alloc] initWithCapacity:MEMORY_CACHE_CAPACITY];
//	imageTemporalList = [[NSMutableArray alloc] initWithCapacity:MEMORY_CACHE_CAPACITY];
		
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
//	[imageTemporalList release];
//	[filenameImageMemoryCache release];
	[channelImageViewMap release];
	[channelThumbnailCacheDir release];
	[fileManager dealloc];
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
- (BOOL)setImageInChannel:(NMChannel *)chn forImageView:(NMTouchImageView *)iv {
	// check if the image is in local file system
	NSString * fPath = [channelThumbnailCacheDir stringByAppendingPathComponent:chn.nm_thumbnail_file_name];
	if ( [fileManager fileExistsAtPath:fPath] ) {
		UIImage * img = [UIImage imageWithContentsOfFile:fPath];
		if ( img ) {
			// file exists in path, load the file
			iv.image = img;
			return YES;
		} else {
			// the file specified by the cache does not exist
			chn.nm_thumbnail_file_name = nil;
		}
	} 
	iv.image = nil;
	// issue image load request
	[nowmovTaskController issueGetThumbnailForChannel:chn];
	// note: the Task Queue Controller should check if we have already queued the task!!
	
	[channelImageViewMap setObject:iv forKey:[NSNumber numberWithUnsignedInteger:[chn hash]]];
	return NO;
}

- (void)handleImageDownloadNotification:(NSNotification *)aNotification {
	// update the view
	NSDictionary * userInfo = [aNotification userInfo];
	NSNumber * hashNum = [NSNumber numberWithUnsignedInteger:[[userInfo objectForKey:@"target_object"] hash]];
	NMTouchImageView * iv = [channelImageViewMap objectForKey:hashNum];
	if ( iv ) {
		iv.image = [userInfo objectForKey:@"image"];
		[channelImageViewMap removeObjectForKey:hashNum];
	}
}

- (void)handleImageDownloadFailedNotification:(NSNotification *)aNotification {
	// try again?
}

#pragma mark save downloaded image
- (void)writeImageData:(NSData *)aData withFilename:(NSString *)fname {
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
