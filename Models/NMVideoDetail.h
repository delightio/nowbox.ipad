//
//  NMVideoDetail.h
//  ipad
//
//  Created by Bill So on 18/1/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMConcreteVideo;

@interface NMVideoDetail : NSManagedObject

@property (nonatomic, retain) NSString * nm_description;
@property (nonatomic, retain) NMConcreteVideo *video;

@end
