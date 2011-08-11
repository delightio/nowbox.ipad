//
//  NMCategory.h
//  ipad
//
//  Created by Bill So on 8/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMChannel;

@interface NMCategory : NSManagedObject

@property (nonatomic, retain) NSNumber * nm_id;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NMChannel *channels;

@end
