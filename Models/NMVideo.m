// 
//  NMVideo.m
//  Nowmov
//
//  Created by Bill So on 10/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMVideo.h"
#import "NMChannel.h"
#import "NMDataType.h"
#import "NMAVPlayerItem.h"

@implementation NMVideo 

@dynamic author_profile_link;
@dynamic author_username;
@dynamic service_external_id;
@dynamic nm_description;
@dynamic created_at;
@dynamic nm_fetch_timestamp;
@dynamic title;
@dynamic total_mentions;
@dynamic nm_direct_url;
@dynamic nm_sort_order;
@dynamic nm_error;
@dynamic nm_playback_status;
@dynamic nm_retry_count;
@dynamic service_name;
@dynamic vid;
@dynamic reason_included;
@dynamic channel;
@dynamic thumbnail;

@synthesize nm_player_item;

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

- (void)willSave {
	[self setPrimitiveValue:[NSNumber numberWithInteger:nm_playback_status] forKey:@"nm_playback_status"];
	[super willSave];
}

- (NMAVPlayerItem *)createPlayerItem {
	if ( nm_playback_status > NMVideoQueueStatusResolvingDirectURL ) {
		NSString * urlStr = [self primitiveNm_direct_url];
		if ( urlStr && ![urlStr isEqualToString:@""] ) {
			NMAVPlayerItem * item = [[NMAVPlayerItem alloc] initWithURL:[NSURL URLWithString:urlStr]];
			return item;
		}
	}
	return nil;
}

@end
