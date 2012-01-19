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

@interface NMVideo : NSManagedObject

@property (nonatomic, retain) NSNumber * nm_sort_order;
@property (nonatomic, retain) NSNumber * nm_session_id;
@property (nonatomic, retain) NMConcreteVideo *video;
@property (nonatomic, retain) NMChannel *channel;

@end
