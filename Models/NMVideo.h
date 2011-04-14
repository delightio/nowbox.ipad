//
//  NMVideo.h
//  Nowmov
//
//  Created by Bill So on 10/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <AVFoundation/AVFoundation.h>

@class NMChannel;

@interface NMVideo :  NSManagedObject  
{
	NSInteger nm_playback_status_;
	NSInteger nm_retry_count_;
}

@property (nonatomic, retain) NSString * author_profile_link;
@property (nonatomic, retain) NSString * author_username;
@property (nonatomic, retain) NSString * service_external_id;
@property (nonatomic, retain) NSString * nm_description;
@property (nonatomic, retain) NSDate * created_at;
@property (nonatomic, retain) NSDate * nm_fetch_timestamp;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * total_mentions;
@property (nonatomic, retain) NSString * nm_direct_url;
@property (nonatomic, retain) NSNumber * nm_error;
@property (nonatomic) NSInteger nm_retry_count;
@property (nonatomic, retain) NSNumber * nm_sort_order;
@property (nonatomic) NSInteger nm_playback_status;
@property (nonatomic, retain) NSString * service_name;
@property (nonatomic, retain) NSNumber * vid;
@property (nonatomic, retain) NSString * reason_included;
@property (nonatomic, retain) NMChannel * channel;

@end



