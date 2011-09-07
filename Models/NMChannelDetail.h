//
//  NMChannelDetail.h
//  ipad
//
//  Created by Bill So on 8/31/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMChannel;

@interface NMChannelDetail : NSManagedObject

@property (nonatomic, retain) NSString * nm_description;
@property (nonatomic, retain) NMChannel *channel;

@end
