// 
//  NMVideo.m
//  Nowmov
//
//  Created by Bill So on 10/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMVideo.h"
#import "NMDataType.h"
#import "NMChannel.h"
#import "NMVideoDetail.h"
#import "NMAVPlayerItem.h"

@implementation NMVideo 

@dynamic external_id;
@dynamic published_at;
@dynamic title;
@dynamic view_count;
@dynamic nm_favorite;
@dynamic nm_watch_later;
@dynamic nm_did_play;
@dynamic nm_direct_url;
@dynamic nm_direct_sd_url;
@dynamic nm_sort_order;
@dynamic nm_error;
@dynamic nm_playback_status;
@dynamic nm_retry_count;
@dynamic nm_session_id;
@dynamic nm_thumbnail_file_name;
@dynamic source;
@dynamic nm_id;
@dynamic channel;
@dynamic thumbnail_uri;
@dynamic duration;
@dynamic detail;

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

- (NMAVPlayerItem *)createPlayerItem {
	if ( self.nm_playback_status > NMVideoQueueStatusResolvingDirectURL ) {
//		NSString * urlStr = NM_USE_HIGH_QUALITY_VIDEO ? [self primitiveNm_direct_url] : [self primitiveNm_direct_sd_url];
		NSString * urlStr;
		if ( (NM_VIDEO_QUALITY == NMVideoQualityAutoSelect && NM_WIFI_REACHABLE) || NM_VIDEO_QUALITY == NMVideoQualityAlwaysHD ) {
			// use HD
			urlStr = [self primitiveNm_direct_url];
		} else {
			// usd SD
			urlStr = [self primitiveNm_direct_sd_url];
		}
		if ( urlStr && ![urlStr isEqualToString:@""] ) {
			NMAVPlayerItem * item = [[NMAVPlayerItem alloc] initWithURL:[NSURL URLWithString:urlStr]];
			item.nmVideo = self;
			self.nm_player_item = item;
			return [item autorelease];
		}
	}
	return nil;
}

@end
