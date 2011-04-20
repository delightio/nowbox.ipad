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


@implementation NMImageDownloadTask

@synthesize channel, imageURLString;
@synthesize httpResponse;

- (id)initWithChannel:(NMChannel *)chn {
	self = [super init];
	
	self.imageURLString = chn.thumbnail;
	self.channel = chn;
	command = NMCommandGetChannelThumbnail;
	
	return self;
}

- (void)dealloc {
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
	
}

- (void)saveProcessedDataInController:(NMDataController *)ctrl {
	// save the file in file system
	NSString * imgFName = [httpResponse suggestedFilename];
	
}

@end
