//
//  NMAVPlayerItem.m
//  ipad
//
//  Created by Bill So on 11/06/2011.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "NMAVPlayerItem.h"
#import "NMLibrary.h"


@implementation NMAVPlayerItem

@synthesize nmVideo;

- (void)dealloc {
	[nmVideo release];
	[super dealloc];
}

@end
