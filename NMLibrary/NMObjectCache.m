//
//  NMObjectCache.m
//  ipad
//
//  Created by Bill So on 1/28/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMObjectCache.h"

@implementation NMObjectCache

- (id)init {
	self = [super init];
	sizeLimit = 32;
	cache = [[NSMutableDictionary alloc] initWithCapacity:4];
	cacheKeyArray = [[NSMutableArray alloc] initWithCapacity:4];
	return self;
}

- (void)dealloc {
	[cacheKeyArray release];
	[cache release];
	[super dealloc];
}

- (id)objectForKey:(id)aKey {
	return [cache objectForKey:aKey];
}

- (void)setObject:(id)obj forKey:(id)aKey {
	// restrict growth of the cache array
	if ( [cacheKeyArray count] == sizeLimit ) {
		// remove oldest 8 elements
		NSRange theRange = NSMakeRange(sizeLimit - 8, 8);
		NSArray * keyAy = [cacheKeyArray subarrayWithRange:theRange];
		[keyAy retain];
		[cacheKeyArray removeObjectsInRange:theRange];
		[cache removeObjectsForKeys:keyAy];
		[keyAy release];
	}
	[cache setObject:obj forKey:aKey];
	[cacheKeyArray insertObject:aKey atIndex:0];
}

@end
