//
//  NMCategory.m
//  ipad
//
//  Created by Bill So on 11/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMCategory.h"
#import "NMChannel.h"


@implementation NMCategory

@dynamic nm_id;
@dynamic nm_last_refresh;
@dynamic nm_sort_order;
@dynamic title;
@dynamic channels;

- (void)awakeFromInsert {
	self.nm_last_refresh = [NSDate dateWithTimeIntervalSince1970:0.0f];
}

@end
