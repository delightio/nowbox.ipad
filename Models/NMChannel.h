//
//  NMChannel.h
//  Nowmov
//
//  Created by Bill So on 05/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface NMChannel :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * nm_description;
@property (nonatomic, retain) NSNumber * count;
@property (nonatomic, retain) NSString * reason;
@property (nonatomic, retain) NSString * channel_name;

@end



