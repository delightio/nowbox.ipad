//
//  NMVideoDetail.h
//  ipad
//
//  Created by Bill So on 27/06/2011.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NMVideo;

@interface NMVideoDetail : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * author_username;
@property (nonatomic, retain) NSString * author_profile_uri;
@property (nonatomic, retain) NSString * author_thumbnail_uri;
@property (nonatomic, retain) NSString * nm_description;
@property (nonatomic, retain) NMVideo * video;

@end
