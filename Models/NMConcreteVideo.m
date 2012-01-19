//
//  NMVideo.m
//  ipad
//
//  Created by Bill So on 18/1/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMConcreteVideo.h"
#import "NMChannel.h"
#import "NMVideoDetail.h"
#import "NMAVPlayerItem.h"


@implementation NMConcreteVideo

@dynamic duration;
@dynamic external_id;
@dynamic nm_did_play;
@dynamic nm_direct_sd_url;
@dynamic nm_direct_url;
@dynamic nm_direct_url_expiry;
@dynamic nm_error;
@dynamic nm_favorite;
@dynamic nm_id;
@dynamic nm_playback_status;
@dynamic nm_retry_count;
@dynamic nm_thumbnail_file_name;
@dynamic nm_watch_later;
@dynamic published_at;
@dynamic source;
@dynamic thumbnail_uri;
@dynamic title;
@dynamic view_count;
@dynamic channels;
@dynamic detail;
@dynamic author;

@synthesize nm_player_item;
@synthesize nm_movie_detail_view;

- (void)awakeFromInsert {
	self.nm_player_item = nil;
}

- (void)awakeFromFetch {
	self.nm_player_item = nil;
}

- (void)setNm_playback_status:(NSInteger)anInt {
	[self willChangeValueForKey:@"nm_playback_status"];
	nm_playback_status = anInt;
	[self didChangeValueForKey:@"nm_playback_status"];
}

- (NSInteger)nm_playback_status {
	[self willAccessValueForKey:@"nm_playback_status"];
	NSInteger i = nm_playback_status;
	[self didAccessValueForKey:@"nm_playback_status"];
	return i;
}

- (void)setNm_direct_url_expiry:(NSInteger)anInt {
	[self willChangeValueForKey:@"nm_direct_url_expiry"];
	nm_direct_url_expiry = anInt;
	[self didChangeValueForKey:@"nm_direct_url_expiry"];
}

- (NSInteger)nm_direct_url_expiry {
	[self willAccessValueForKey:@"nm_direct_url_expiry"];
	NSInteger i = nm_direct_url_expiry;
	[self didAccessValueForKey:@"nm_direct_url_expiry"];
	return i;
}

- (void)willSave {
	[self setPrimitiveValue:[NSNumber numberWithInteger:nm_playback_status] forKey:@"nm_playback_status"];
	[super willSave];
}

@end
