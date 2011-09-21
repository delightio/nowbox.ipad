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
@synthesize video;
@synthesize videoDetail;
@synthesize previewThumbnail;

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	cacheController = [NMCacheController sharedCacheController];
//	notificationCenter = [NSNotificationCenter defaultCenter];
	return self;
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	cacheController = [NMCacheController sharedCacheController];
//	notificationCenter = [NSNotificationCenter defaultCenter];
	
	return self;
}

//- (void)awakeFromNib {
//	cacheController = [NMCacheController sharedCacheController];
//	notificationCenter = [NSNotificationCenter defaultCenter];
//}

- (void)dealloc {
//	[notificationCenter removeObserver:self];
	[downloadTask release];
	[channel release];
	[videoDetail release];
	[previewThumbnail release];
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
	[cacheController handleImageDownloadNotification:aNotification];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.downloadTask = nil;
}

- (void)handleImageDownloadFailedNotification:(NSNotification *)aNotification {
	[cacheController handleImageDownloadFailedNotification:aNotification];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.downloadTask = nil;
}

#pragma mark delayed method call
- (void)delayedIssueChannelImageDownloadRequest {
	self.downloadTask = [cacheController downloadImageForChannel:channel imageView:self];
}

- (void)delayedIssueAuthorImageDownloadRequest {
	self.downloadTask = [cacheController downloadImageForAuthor:videoDetail imageView:self];
}

- (void)delayedIssueVideoImageDownloadRequest {
	self.downloadTask = [cacheController downloadImageForVideo:video imageView:self];
}

#pragma mark Setter
- (void)setImageForChannel:(NMChannel *)chn {
	self.channel = chn;
	// check if there's local cache
	[cacheController setImageForChannel:chn imageView:self];
}

- (void)setImageForAuthorThumbnail:(NMVideoDetail *)dtl {
	self.videoDetail = dtl;
	// check if there's local cache
	[cacheController setImageForAuthor:dtl imageView:self];
}

- (void)setImageForVideoThumbnail:(NMVideo *)vdo {
	self.video = vdo;
	// check if there's local cache
	[cacheController setImageForVideo:vdo imageView:self];
}

- (void)setImageForPreviewThumbnail:(NMPreviewThumbnail *)pv {
	self.previewThumbnail = pv;
	// check if there's local cache
	[cacheController setImageForPreviewThumbnail:pv imageView:self];
}

- (void)cancelDownload {
	// stop listening first
	if ( downloadTask ) {
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		[downloadTask releaseDownload];
		self.downloadTask = nil;
	}
}

@end
