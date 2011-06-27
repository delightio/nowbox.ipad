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
	self = [super init];
	
	cacheController = [NMCacheController sharedCacheController];
	self.imageURLString = chn.thumbnail_uri;
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

- (NSString *)suggestedFilename {
	NSString * imgFName = nil;
	if ( [imageURLString rangeOfString:@"youtube"].location == NSNotFound ) {
		imgFName = [httpResponse suggestedFilename];
	} else {
		NSArray * ay = [[httpResponse URL] pathComponents];
		imgFName = [NSString stringWithFormat:@"%@_%@", [ay objectAtIndex:[ay count] - 2], [httpResponse suggestedFilename]];
	}
	return imgFName;
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
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	// create the image object
	self.image = [UIImage imageWithData:buffer];	// seems that it's not safe to use UIImage in worker thread
	// update channel MOC with new file name
	channel.nm_thumbnail_file_name = [self suggestedFilename];
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
