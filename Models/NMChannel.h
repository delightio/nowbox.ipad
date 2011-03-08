//
//  NMChannel.h
//  Nowmov
//
//  Created by Bill So on 07/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class NMVideo;

@interface NMChannel :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * nm_description;
@property (nonatomic, retain) NSNumber * count;
@property (nonatomic, retain) NSString * reason;
@property (nonatomic, retain) NSString * channel_name;
@property (nonatomic, retain) NSSet* videos;
@property (nonatomic, retain) NSString * thumbnail;

@end


@interface NMChannel (CoreDataGeneratedAccessors)
- (void)addVideosObject:(NMVideo *)value;
- (void)removeVideosObject:(NMVideo *)value;
- (void)addVideos:(NSSet *)value;
- (void)removeVideos:(NSSet *)value;

@end

