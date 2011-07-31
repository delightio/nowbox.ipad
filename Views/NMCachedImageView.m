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

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
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
	[channel release];
	[videoDetail release];
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
#ifdef DEBUG_IMAGE_CACHE
	NSLog(@"download notification");
#endif
	// update the view
	NSDictionary * userInfo = [aNotification userInfo];
	self.image = [userInfo objectForKey:@"image"];
	[notificationCenter removeObserver:self];
	self.downloadTask = nil;
}

- (void)handleImageDownloadFailedNotification:(NSNotification *)aNotification {
	[notificationCenter removeObserver:self];
	self.downloadTask = nil;
	// TODO: retry?
}

#pragma mark delayed method call
- (void)delayedIssueChannelImageDownloadRequest {
	self.downloadTask = [cacheController downloadImageForChannel:channel];
	[notificationCenter addObserver:self selector:@selector(handleImageDownloadNotification:) name:NMDidDownloadImageNotification object:self.downloadTask];
	[notificationCenter addObserver:self selector:@selector(handleImageDownloadFailedNotification:) name:NMDidFailDownloadImageNotification object:self.downloadTask];
}

- (void)delayedIssueAuthorImageDownloadRequest {
	self.downloadTask = [cacheController downloadImageForAuthor:videoDetail];
	[notificationCenter addObserver:self selector:@selector(handleImageDownloadNotification:) name:NMDidDownloadImageNotification object:self.downloadTask];
	[notificationCenter addObserver:self selector:@selector(handleImageDownloadFailedNotification:) name:NMDidFailDownloadImageNotification object:self.downloadTask];
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
	self.channel = chn;
	[self performSelector:@selector(delayedIssueChannelImageDownloadRequest) withObject:nil afterDelay:0.5];
}

- (void)setImageForAuthorThumbnail:(NMVideoDetail *)dtl {
	// check if there's local cache
	if ( [cacheController setImageForAuthor:dtl imageView:self] ) {
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
	self.videoDetail = dtl;
	[self performSelector:@selector(delayedIssueAuthorImageDownloadRequest) withObject:nil afterDelay:0.5];
}

@end
