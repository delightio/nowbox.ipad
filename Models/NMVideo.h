//
//  NMVideo.h
//  ipad
//
//  Created by Bill So on 1/18/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMChannel, NMConcreteVideo;
@class NMAVPlayerItem;

@interface NMVideo : NSManagedObject

@property (nonatomic, retain) NSNumber * nm_make_dirty;
@property (nonatomic, retain) NSNumber * nm_sort_order;
@property (nonatomic, retain) NSNumber * nm_session_id;
@property (nonatomic, retain) NMConcreteVideo *video;
@property (nonatomic, retain) NMChannel *channel;

/*!
 Create a new player item. The caller of this method owns the object. The caller takes full ownership of this object.
 */
- (NMAVPlayerItem *)createPlayerItem;

@end
