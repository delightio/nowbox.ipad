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

NSString * const NMWillDownloadImageNotification = @"NMWillDownloadImageNotification";
NSString * const NMDidDownloadImageNotification = @"NMDidDownloadImageNotification";
NSString * const NMDidFailDownloadImageNotification = @"NMDidFailDownloadImageNotification";

@implementation NMImageDownloadTask

@synthesize channel, imageURLString;
@synthesize httpResponse, originalImagePath;
@synthesize image;

- (id)initWithChannel:(NMChannel *)chn {
	self = [self init];
	
	cacheController = [NMCacheController sharedCacheController];
	self.imageURLString = chn.thumbnail;
	self.originalImagePath = chn.nm_thumbnail_file_name;
	self.channel = chn;
	command = NMCommandGetChannelThumbnail;
	
	return self;
}

- (void)dealloc {
	[image release];
	[httpResponse release];
	[channel release];
	[imageURLString release];
	[super dealloc];
}

- (NSMutableURLRequest *)URLRequest {
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:imageURLString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:NM_URL_REQUEST_TIMEOUT];
	return request;
}

- (void)processDownloadedDataInBuffer {
	if ( originalImagePath ) {
		// delete the original image
		NSFileManager * fm = [[NSFileManager alloc] init];
		[fm removeItemAtPath:originalImagePath error:nil];
		[fm release];
	}
	[cacheController writeImageData:buffer withFilename:[httpResponse suggestedFilename]];
	// create the image object
	self.image = [UIImage imageWithData:buffer];
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	// save the file in file system
	NSString * imgFName = [httpResponse suggestedFilename];
	channel.nm_thumbnail_file_name = imgFName;
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
	return [NSDictionary dictionaryWithObjectsAndKeys:channel, @"target_object", image, @"image", [NSNumber numberWithInteger:command], @"command", nil];
}

@end
