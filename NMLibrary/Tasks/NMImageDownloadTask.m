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
#import "NMVideo.h"
#import "NMVideoDetail.h"

NSString * const NMWillDownloadImageNotification = @"NMWillDownloadImageNotification";
NSString * const NMDidDownloadImageNotification = @"NMDidDownloadImageNotification";
NSString * const NMDidFailDownloadImageNotification = @"NMDidFailDownloadImageNotification";

@implementation NMImageDownloadTask

@synthesize channel, imageURLString;
@synthesize httpResponse, originalImagePath;
@synthesize image, videoDetail;

+ (NSUInteger)commandIndexForChannel:(NMChannel *)chn {
	NSUInteger tid = [chn.nm_id unsignedIntegerValue];
	return tid << 5 | (NSUInteger)NMCommandGetChannelThumbnail;
}

+ (NSUInteger)commandIndexForAuthor:(NMVideoDetail *)dtl {
	NSUInteger tid = [dtl.author_id unsignedIntegerValue];
	return tid << 5 | (NSUInteger)NMCommandGetAuthorThumbnail;
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
	self.originalImagePath = dtl.nm_author_thunbmail_file_name;
	self.videoDetail = dtl;
	self.targetID = dtl.author_id;
	command = NMCommandGetAuthorThumbnail;
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
	[channel release];
	[imageURLString release];
	[videoDetail release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:imageURLString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	return request;
}

- (NSString *)suggestedFilename {
	return [NSString stringWithFormat:@"%@_%@", targetID, [httpResponse suggestedFilename]];
}

- (void)processDownloadedDataInBuffer {
	if ( originalImagePath ) {
		// delete the original image
		NSFileManager * fm = [[NSFileManager alloc] init];
		[fm removeItemAtPath:originalImagePath error:nil];
		[fm release];
	}
	// save the file in file system
	[cacheController writeImageData:buffer withFilename:[self suggestedFilename]];
	self.image = [UIImage imageWithData:buffer];
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	// create the image object
//	self.image = [UIImage imageWithData:buffer];	// seems that it's not safe to use UIImage in worker thread
	// update channel MOC with new file name
	if ( originalImagePath == nil ) {
		switch (command) {
			case NMCommandGetAuthorThumbnail:
				videoDetail.nm_author_thunbmail_file_name = [self suggestedFilename];
				break;
				
			case NMCommandGetChannelThumbnail:
				channel.nm_thumbnail_file_name = [self suggestedFilename];
				break;
				
			default:
				break;
		}
	}
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
			
		default:
			break;
	}
	return nil;
}

@end
