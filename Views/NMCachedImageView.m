//
//  NMCachedImageView.m
//  ipad
//
//  Created by Bill So on 30/7/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "NMCachedImageView.h"

@implementation NMCachedImageView
@synthesize downloadTask;
@synthesize channel;
@synthesize videoDetail;

- (id)init {
	self = [super init];
	
	cacheController = [NMCacheController sharedCacheController];
	notificationCenter = [NSNotificationCenter defaultCenter];
	
	return self;
}

- (void)awakeFromNib {
	cacheController = [NMCacheController sharedCacheController];
	notificationCenter = [NSNotificationCenter defaultCenter];
}

- (void)dealloc {
	[notificationCenter removeObserver:self];
	[downloadTask release];
	[super dealloc];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

#pragma mark Notification handler
- (void)handleImageDownloadNotification:(NSNotification *)aNotification {
	// update the view
	NSDictionary * userInfo = [aNotification userInfo];
	self.image = [userInfo objectForKey:@"image"];
	[notificationCenter removeObserver:self];
}

- (void)handleImageDownloadFailedNotification:(NSNotification *)aNotification {
	[notificationCenter removeObserver:self];
	self.downloadTask = nil;
	// TODO: retry?
}

#pragma mark delayed method call
- (void)delayedIssueChannelImageDownloadRequest {
	self.downloadTask = [cacheController downloadImageForChannel:channel];
}

- (void)delayedIssueAuthorImageDownloadRequest {
	self.downloadTask = [cacheController downloadImageForAuthor:videoDetail];
}

#pragma mark Setter
- (void)setImageForChannel:(NMChannel *)chn {
	// check if there's local cache
	if ( [cacheController setImageForChannel:chn imageView:self] ) {
		return;
	}
		
	// no local cache. need to get from server
	if ( downloadTask ) {
		// stop listening to notification
		[notificationCenter removeObserver:self name:NMDidDownloadImageNotification object:downloadTask];
		[notificationCenter removeObserver:self name:NMDidFailDownloadImageNotification object:downloadTask];
		// cancel the previous download task
		[downloadTask releaseDownload];
	} else {
		// clean up any previous delayed request
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedIssueDownloadRequest) object:nil];
	}
	self.downloadTask = nil;
	
	// issue delay request
	[self performSelector:@selector(delayedIssueChannelImageDownloadRequest) withObject:nil afterDelay:0.5];
}

- (void)setImageForAuthorThumbnail:(NMVideoDetail *)dtl {
	
}

@end
