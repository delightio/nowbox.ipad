//
//  NMVideo.h
//  Nowmov
//
//  Created by Bill So on 10/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class NMChannel;
@class NMAVPlayerItem;
@class NMMovieDetailView;

@interface NMVideo :  NSManagedObject  
{
	NSInteger nm_playback_status;
	
	NMAVPlayerItem * nm_player_item;
	NMMovieDetailView * nm_movie_detail_view;
}

@property (nonatomic, retain) NSString * author_profile_link;
@property (nonatomic, retain) NSString * author_username;
@property (nonatomic, retain) NSString * service_external_id;
@property (nonatomic, retain) NSString * nm_description;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSDate * created_at;
@property (nonatomic, retain) NSDate * nm_fetch_timestamp;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * total_mentions;
@property (nonatomic, retain) NSString * nm_direct_url;
@property (nonatomic, retain) NSNumber * nm_error;
@property (nonatomic, retain) NSNumber * nm_retry_count;
@property (nonatomic, retain) NSNumber * nm_sort_order;
@property (nonatomic) NSInteger nm_playback_status;
@property (nonatomic, retain) NSString * service_name;
@property (nonatomic, retain) NSNumber * vid;
@property (nonatomic, retain) NSString * reason_included;
@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, retain) NSString * thumbnail;

@property (nonatomic, assign) NMAVPlayerItem * nm_player_item;
@property (nonatomic, assign) NMMovieDetailView * nm_movie_detail_view;

/*!
 Create a new player item. The caller of this method owns the object. The caller takes full ownership of this object.
 */
- (NMAVPlayerItem *)createPlayerItem;

@end

@interface NMVideo (CoreDataAccessors)

- (NSString *)primitiveNm_direct_url;

@end