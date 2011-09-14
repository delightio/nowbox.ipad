//
//  NMImageDownloadTask.m
//  ipad
//
//  Created by Bill So on 20/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMImageDownloadTask.h"
#import "NMCacheController.h"
#import "NMChannel.h"
#import "NMPreviewThumbnail.h"
#import "NMVideo.h"
#import "NMVideoDetail.h"

NSString * const NMWillDownloadImageNotification = @"NMWillDownloadImageNotification";
NSString * const NMDidDownloadImageNotification = @"NMDidDownloadImageNotification";
NSString * const NMDidFailDownloadImageNotification = @"NMDidFailDownloadImageNotification";

@implementation NMImageDownloadTask

@synthesize channel, imageURLString;
@synthesize httpResponse, originalImagePath;
@synthesize image, video, videoDetail;
@synthesize externalID, previewThumbnail;

+ (NSUInteger)commandIndexForChannel:(NMChannel *)chn {
	NSUInteger tid = [chn.nm_id unsignedIntegerValue];
	return tid << 5 | (NSUInteger)NMCommandGetChannelThumbnail;
}

+ (NSUInteger)commandIndexForAuthor:(NMVideoDetail *)dtl {
	NSUInteger tid = [dtl.author_id unsignedIntegerValue];
	return tid << 5 | (NSUInteger)NMCommandGetAuthorThumbnail;
}

+ (NSUInteger)commandIndexForVideo:(NMVideo *)vdo {
	NSUInteger tid = [vdo.nm_id unsignedIntegerValue];
	return tid << 5 | (NSUInteger)NMCommandGetVideoThumbnail;
}

+ (NSUInteger)commandIndexForPreviewThumbnail:(NMPreviewThumbnail *)pv {
	NSUInteger tid = [pv.nm_id unsignedIntegerValue];
	return tid << 5 | (NSUInteger)NMCommandGetPreviewThumbnail;
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

- (id)initWithAuthor:(NMVideoDetail *)dtl {
	self = [super init];
	
	cacheController = [NMCacheController sharedCacheController];
	self.imageURLString = dtl.author_thumbnail_uri;
	self.originalImagePath = dtl.nm_author_thumbnail_file_name;
	self.videoDetail = dtl;
	self.targetID = dtl.author_id;
	command = NMCommandGetAuthorThumbnail;
	retainCount = 1;
	
	return self;
}

- (id)initWithVideoThumbnail:(NMVideo *)vdo {
	self = [super init];
	
	cacheController = [NMCacheController sharedCacheController];
	self.imageURLString = vdo.thumbnail_uri;
	// we do not store the image in cache for now.
	// self.originalImagePath = nil;
	self.video = vdo;
	self.targetID = vdo.nm_id;
	self.externalID = vdo.external_id;
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
	[channel release];
	[video release];
	[videoDetail release];
	[externalID release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
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
				videoDetail.nm_author_thumbnail_file_name = [self suggestedFilename];
				break;
				
			case NMCommandGetChannelThumbnail:
				channel.nm_thumbnail_file_name = [self suggestedFilename];
				break;
				
			case NMCommandGetVideoThumbnail:
				video.nm_thumbnail_file_name = [self suggestedFilename];
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
			return [NSDictionary dictionaryWithObjectsAndKeys:videoDetail, @"target_object", image, @"image", [NSNumber numberWithInteger:command], @"command", nil];
			
		case NMCommandGetChannelThumbnail:
			return [NSDictionary dictionaryWithObjectsAndKeys:channel, @"target_object", image, @"image", [NSNumber numberWithInteger:command], @"command", nil];
			
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
