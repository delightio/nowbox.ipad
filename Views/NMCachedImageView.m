//
//  NMCachedImageView.m
//  ipad
//
//  Created by Bill So on 30/7/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "NMCachedImageView.h"
#import "UIImage+Tint.h"

@implementation NMCachedImageView
@synthesize downloadTask;
@synthesize category;
@synthesize channel;
@synthesize video;
@synthesize author;
//@synthesize videoDetail;
@synthesize previewThumbnail;
@synthesize adjustsImageOnHighlight;

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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[downloadTask release];
	[category release];
	[channel release];
	[video release];
	[author release];
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
	NMTask * theTask = [aNotification object];
	if ( theTask.command == NMCommandGetVideoThumbnail ) {
		NMVideo * vdo = [[aNotification userInfo] objectForKey:@"target_object"];
		NSLog(@"\tdownloaded thumbnail for video: %@", vdo.title);
	}
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
	self.downloadTask = [cacheController downloadImageForAuthor:author imageView:self];
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

- (void)setImageForAuthorThumbnail:(NMAuthor *)anAuthor {
	self.author = anAuthor;
	// check if there's local cache
	[cacheController setImageForAuthor:anAuthor imageView:self];
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

- (void)setImageForCategory:(NMCategory *)cat {
	self.category = cat;
	[cacheController setImageForCategory:cat imageView:self];
}

- (void)setImage:(UIImage *)image {
    [super setImage:image];
    
    if (self.adjustsImageOnHighlight) {
        self.highlightedImage = [image tintedImageUsingColor:[UIColor colorWithWhite:0.0 alpha:0.4]];
    }
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
