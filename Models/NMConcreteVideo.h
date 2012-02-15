//
//  NMVideo.h
//  ipad
//
//  Created by Bill So on 18/1/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMVideoDetail, NMAuthor, NMVideo, NMFacebookInfo;
@class NMMovieDetailView, NMAVPlayerItem;

@interface NMConcreteVideo : NSManagedObject {
//	NSInteger nm_playback_status;
	
	NMAVPlayerItem * nm_player_item;
	NMMovieDetailView * nm_movie_detail_view;
	NSInteger nm_playback_status;
	NSInteger nm_direct_url_expiry;
}

@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSString * external_id;
@property (nonatomic, retain) NSNumber * nm_did_play;
@property (nonatomic, retain) NSString * nm_direct_sd_url;
@property (nonatomic, retain) NSString * nm_direct_url;
@property (nonatomic) NSInteger nm_direct_url_expiry;
@property (nonatomic, retain) NSNumber * nm_error;
@property (nonatomic, retain) NSNumber * nm_favorite;
@property (nonatomic, retain) NSNumber * nm_id;
@property (nonatomic) NSInteger nm_playback_status;
@property (nonatomic, retain) NSNumber * nm_retry_count;
@property (nonatomic, retain) NSString * nm_thumbnail_file_name;
@property (nonatomic, retain) NSNumber * nm_watch_later;
@property (nonatomic, retain) NSDate * published_at;
@property (nonatomic, retain) NSNumber * source;
@property (nonatomic, retain) NSString * thumbnail_uri;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * view_count;
@property (nonatomic, retain) NSSet *channels;
@property (nonatomic, retain) NMVideoDetail *detail;
@property (nonatomic, retain) NMAuthor *author;
@property (nonatomic, retain) NSSet * facebookMentions;

@property (nonatomic, assign) NMAVPlayerItem * nm_player_item;
@property (nonatomic, assign) NMMovieDetailView * nm_movie_detail_view;

@end

@interface NMConcreteVideo (CoreDataGeneratedAccessors)

- (void)addChannelsObject:(NMConcreteVideo *)value;
- (void)removeChannelsObject:(NMConcreteVideo *)value;
- (void)addChannels:(NSSet *)values;
- (void)removeChannels:(NSSet *)values;

- (void)addFacebookMentionsObject:(NMFacebookInfo *)value;
- (void)removeFacebookMentionsObject:(NMFacebookInfo *)value;
- (void)addFacebookMentions:(NSSet *)values;
- (void)removeFacebookMentions:(NSSet *)values;

- (NSString *)primitiveNm_direct_url;
- (NSString *)primitiveNm_direct_sd_url;

@end
