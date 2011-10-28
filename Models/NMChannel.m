//
//  NMChannel.m
//  ipad
//
//  Created by Bill So on 8/31/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMChannel.h"
#import "NMCategory.h"
#import "NMChannelDetail.h"
#import "NMPreviewThumbnail.h"
#import "NMVideo.h"


@implementation NMChannel

@dynamic nm_current_page;
@dynamic nm_hidden;
@dynamic nm_id;
@dynamic nm_last_vid;
@dynamic nm_populated;
@dynamic nm_sort_order;
@dynamic nm_subscribed;
@dynamic nm_thumbnail_file_name;
@dynamic nm_time_elapsed_timescale;
@dynamic nm_time_elapsed_value;
@dynamic nm_video_last_refreshed;
@dynamic subscriber_count;
@dynamic populated_at;
@dynamic resource_uri;
@dynamic thumbnail_uri;
@dynamic title;
@dynamic type;
@dynamic video_count;
@dynamic categories;
@dynamic detail;
@dynamic previewThumbnails;
@dynamic videos;

- (void)awakeFromFetch {
	didFirstPopulateStatusCheck = NO;
}

- (NSNumber *)nm_populated {
	NSNumber * abool;
	[self willAccessValueForKey:@"nm_populated"];
	if ( didFirstPopulateStatusCheck ) {
		abool = [self primitiveNm_populated];
	} else {
		didFirstPopulateStatusCheck = YES;
		NSDate * theDate = [self primitivePopulated_at];
		if ( [theDate compare:[NSDate dateWithTimeIntervalSince1970:0.0f]] != NSOrderedDescending ) {
			// not populated yet
			abool = [NSNumber numberWithBool:NO];
		} else {
			abool = [NSNumber numberWithBool:YES];
		}
		[self setPrimitiveNm_populated:abool];
	}
	[self didAccessValueForKey:@"nm_populated"];
	return abool;
}

- (void)setPopulated_at:(NSDate *)aDate {
	[self willChangeValueForKey:@"populated_at"];
	[self setPrimitivePopulated_at:aDate];
	[self didChangeValueForKey:@"populated_at"];
	
	// update the cached value as well
	if ( [aDate compare:[NSDate dateWithTimeIntervalSince1970:0.0f]] != NSOrderedDescending ) {
		// not populated yet
		[self setPrimitiveNm_populated:[NSNumber numberWithBool:NO]];
	} else {
		[self setPrimitiveNm_populated:[NSNumber numberWithBool:YES]];
	}
	didFirstPopulateStatusCheck = YES;
}

@end
