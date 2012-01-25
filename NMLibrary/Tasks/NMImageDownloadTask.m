//
//  NMImageDownloadTask.m
//  ipad
//
//  Created by Bill So on 20/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMImageDownloadTask.h"
#import "NMCacheController.h"
#import "NMCategory.h"
#import "NMChannel.h"
#import "NMPreviewThumbnail.h"
#import "NMVideo.h"
#import "NMConcreteVideo.h"
#import "NMVideoDetail.h"
#import "NMAuthor.h"

NSString * const NMWillDownloadImageNotification = @"NMWillDownloadImageNotification";
NSString * const NMDidDownloadImageNotification = @"NMDidDownloadImageNotification";
NSString * const NMDidFailDownloadImageNotification = @"NMDidFailDownloadImageNotification";

@implementation NMImageDownloadTask

@synthesize category;
@synthesize channel, imageURLString;
@synthesize httpResponse, originalImagePath;
@synthesize image, video, author;
@synthesize externalID, previewThumbnail;

+ (NSInteger)commandIndexForCategory:(NMCategory *)cat {
	NSInteger tid = [cat.nm_id unsignedIntegerValue];
	return tid << 6 | NMCommandGetCategoryThumbnail;
}

+ (NSInteger)commandIndexForChannel:(NMChannel *)chn {
	NSInteger tid = [chn.nm_id unsignedIntegerValue];
	return tid << 6 | NMCommandGetChannelThumbnail;
}

+ (NSInteger)commandIndexForAuthor:(NMAuthor *)anAuthor {
	NSInteger tid = [anAuthor.nm_id unsignedIntegerValue];
	return tid << 6 | NMCommandGetAuthorThumbnail;
}

+ (NSInteger)commandIndexForVideo:(NMVideo *)vdo {
	NSInteger tid = [vdo.video.nm_id unsignedIntegerValue];
	return tid << 6 | NMCommandGetVideoThumbnail;
}

+ (NSInteger)commandIndexForPreviewThumbnail:(NMPreviewThumbnail *)pv {
	NSInteger tid = [pv.nm_id unsignedIntegerValue];
	return tid << 6 | NMCommandGetPreviewThumbnail;
}

- (id)initWithCategory:(NMCategory *)cat {
	self = [super init];
	
	cacheController = [NMCacheController sharedCacheController];
	self.imageURLString = cat.thumbnail_uri;
	self.originalImagePath = cat.nm_thumbnail_file_name;
	self.category = cat;
	self.targetID = cat.nm_id;
	command = NMCommandGetCategoryThumbnail;
	retainCount = 1;
	
	return self;
}

- (id)initWithChannel:(NMChannel *)chn {
	self = [super init];
	
	cacheController = [NMCacheController sharedCacheController];
	self.imageURLString = chn.thumbnail_uri;
	self.originalImagePath = chn.nm_thumbnail_file_name;
	self.channel = chn;
	self.targetID = chn.nm_id;
	command = NMCommandGetChannelThumbnail;
	retainCount = 1;
	
	return self;
}

- (id)initWithAuthor:(NMAuthor *)anAuthor {
	self = [super init];
	
	cacheController = [NMCacheController sharedCacheController];
	self.imageURLString = anAuthor.thumbnail_uri;
	self.originalImagePath = anAuthor.nm_thumbnail_file_name;
	self.author = anAuthor;
	self.targetID = anAuthor.nm_id;
	command = NMCommandGetAuthorThumbnail;
	retainCount = 1;
	
	return self;
}

- (id)initWithVideoThumbnail:(NMVideo *)vdo {
	self = [super init];
	
	cacheController = [NMCacheController sharedCacheController];
	self.imageURLString = vdo.video.thumbnail_uri;
	// we do not store the image in cache for now.
	// self.originalImagePath = nil;
	self.video = vdo;
	self.targetID = vdo.video.nm_id;
	self.externalID = vdo.video.external_id;
	command = NMCommandGetVideoThumbnail;
	retainCount = 1;

	return self;
}

- (id)initWithPreviewThumbnail:(NMPreviewThumbnail *)pv {
	self = [super init];
	
	cacheController = [NMCacheController sharedCacheController];
	self.imageURLString = pv.thumbnail_uri;
	// we do not store the image in cache for now.
	// self.originalImagePath = nil;
	self.previewThumbnail = pv;
	self.targetID = pv.nm_id;
	self.externalID = pv.external_id;
	command = NMCommandGetPreviewThumbnail;
	retainCount = 1;

	return self;
}


- (void)retainDownload {
	retainCount++;
}

- (void)releaseDownload {
	retainCount--;
	if ( retainCount == 0 ) {
		// cancel the task
		self.state = NMTaskExecutionStateCanceled;
	}
}

- (void)dealloc {
	[image release];
	[httpResponse release];
	[imageURLString release];
	[category release];
	[channel release];
	[video release];
	[author release];
	[externalID release];
	[super dealloc];
}

- (NSURLRequest *)URLRequest {
#ifdef DEBUG_IMAGE_CACHE
	NSLog(@"Image URL: %@ cmd: %d", imageURLString, command);
#endif
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:imageURLString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	return request;
}

- (NSString *)suggestedFilename {
	switch (command) {
		case NMCommandGetAuthorThumbnail:
			return [NSString stringWithFormat:@"%@.%@", targetID, [[httpResponse suggestedFilename] pathExtension]];
		case NMCommandGetVideoThumbnail:
		case NMCommandGetPreviewThumbnail:
			return [NSString stringWithFormat:@"%@.%@", externalID, [[httpResponse suggestedFilename] pathExtension]];
		case NMCommandGetChannelThumbnail:
			return [NSString stringWithFormat:@"%@_%@", targetID, [httpResponse suggestedFilename]];
		case NMCommandGetCategoryThumbnail:
			return [NSString stringWithFormat:@"cat_%@", targetID, [httpResponse suggestedFilename]];
			
		default:
			break;
	}
	return nil;
}

- (void)processDownloadedDataInBuffer {
	if ( originalImagePath ) {
		// delete the original image
		NSFileManager * fm = [[NSFileManager alloc] init];
		[fm removeItemAtPath:originalImagePath error:nil];
		[fm release];
	}
	// save the file in file system
	switch (command) {
		case NMCommandGetChannelThumbnail:
			[cacheController writeChannelImageData:buffer withFilename:[self suggestedFilename]];
			break;
		case NMCommandGetCategoryThumbnail:
			[cacheController writeCategoryImageData:buffer withFilename:[self suggestedFilename]];
			break;
			
		case NMCommandGetAuthorThumbnail:
			[cacheController writeAuthorImageData:buffer withFilename:[self suggestedFilename]];
			break;
			
		case NMCommandGetVideoThumbnail:
			[cacheController writeVideoImageData:buffer withFileName:[self suggestedFilename]];
			break;
			
		case NMCommandGetPreviewThumbnail:
			[cacheController writePreviewThumbnailImageData:buffer withFileName:[self suggestedFilename]];
			break;
			
		default:
			break;
	}
	self.image = [UIImage imageWithData:buffer];
}

- (BOOL)saveProcessedDataInController:(NMDataController *)ctrl {
	// create the image object
//	self.image = [UIImage imageWithData:buffer];	// seems that it's not safe to use UIImage in worker thread
	// update channel MOC with new file name
	if ( originalImagePath == nil ) {
		switch (command) {
			case NMCommandGetAuthorThumbnail:
				author.nm_thumbnail_file_name = [self suggestedFilename];
				break;
				
			case NMCommandGetChannelThumbnail:
				channel.nm_thumbnail_file_name = [self suggestedFilename];
				break;
				
			case NMCommandGetCategoryThumbnail:
				category.nm_thumbnail_file_name = [self suggestedFilename];
				break;
				
			case NMCommandGetVideoThumbnail:
				video.video.nm_thumbnail_file_name = [self suggestedFilename];
				break;
				
			case NMCommandGetPreviewThumbnail:
				previewThumbnail.nm_thumbnail_file_name = [self suggestedFilename];
				break;
								
			default:
				// no need to save for NMVideo or NMPreviewThumbnail. These 2 object types use external_id to identify images
				break;
		}
	}
	return NO;
}

- (NSString *)willLoadNotificationName {
	return NMWillDownloadImageNotification;
}

- (NSString *)didLoadNotificationName {
	return NMDidDownloadImageNotification;
}

- (NSString *)didFailNotificationName {
	return NMDidFailDownloadImageNotification;
}

- (NSDictionary *)userInfo {
	switch (command) {
		case NMCommandGetAuthorThumbnail:
			return [NSDictionary dictionaryWithObjectsAndKeys:author, @"target_object", image, @"image", [NSNumber numberWithInteger:command], @"command", nil];
			
		case NMCommandGetChannelThumbnail:
			return [NSDictionary dictionaryWithObjectsAndKeys:channel, @"target_object", image, @"image", [NSNumber numberWithInteger:command], @"command", nil];
			
		case NMCommandGetCategoryThumbnail:
			return [NSDictionary dictionaryWithObjectsAndKeys:category, @"target_object", image, @"image", [NSNumber numberWithInteger:command], @"command", nil];
			
		case NMCommandGetVideoThumbnail:
			return [NSDictionary dictionaryWithObjectsAndKeys:video, @"target_object", image, @"image", nil];
			
		case NMCommandGetPreviewThumbnail:
			return [NSDictionary dictionaryWithObjectsAndKeys:previewThumbnail, @"target_object", image, @"image", nil];
			
		default:
			break;
	}
	return nil;
}

@end
