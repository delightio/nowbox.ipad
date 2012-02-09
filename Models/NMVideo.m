//
//  NMVideo.m
//  ipad
//
//  Created by Bill So on 1/18/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMVideo.h"
#import "NMChannel.h"
#import "NMConcreteVideo.h"
#import "NMAVPlayerItem.h"
#import "NMDataType.h"


@implementation NMVideo

@dynamic nm_sort_order;
@dynamic nm_session_id;
@dynamic video;
@dynamic channel;
@dynamic personProfile;

- (NMAVPlayerItem *)createPlayerItem {
	if ( self.video.nm_playback_status > NMVideoQueueStatusResolvingDirectURL ) {
		//		NSString * urlStr = NM_USE_HIGH_QUALITY_VIDEO ? [self primitiveNm_direct_url] : [self primitiveNm_direct_sd_url];
		NSString * urlStr;
		if ( (NM_VIDEO_QUALITY == NMVideoQualityAutoSelect && NM_WIFI_REACHABLE) || NM_VIDEO_QUALITY == NMVideoQualityAlwaysHD ) {
			// use HD
			urlStr = self.video.nm_direct_url;
		} else {
			// usd SD
			urlStr = self.video.nm_direct_sd_url;
		}
		if ( urlStr && ![urlStr isEqualToString:@""] ) {
			NMAVPlayerItem * item = [[NMAVPlayerItem alloc] initWithURL:[NSURL URLWithString:urlStr]];
			item.nmVideo = self;
			self.video.nm_player_item = item;
			return [item autorelease];
		}
	}
	return nil;
}

@end
