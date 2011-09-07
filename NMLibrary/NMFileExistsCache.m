//
//  NMCacheDictionary.m
//  ipad
//
//  Created by Bill So on 6/9/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMFileExistsCache.h"

@implementation NMFileExistsCache

- (id)initWithCapacity:(NSUInteger)numItems {
	self = [super init];
	if ( numItems < 5 ) numItems = 5;		// cache size minimum of 5
	cleanSize = numItems / 5 > 3 ? numItems / 5 : 3;
	cacheDictionary = [[NSMutableDictionary alloc] initWithCapacity:numItems];
	orderList = [[NSMutableArray alloc] initWithCapacity:numItems];
	cacheMaxSize = numItems;
	yesNumber = [[NSNumber alloc] initWithBool:YES];
	noNumber = [[NSNumber alloc] initWithBool:NO];
	return self;
}

- (void)dealloc {
	[cacheDictionary release];
	[orderList release];
	[yesNumber release];
	[noNumber release];
	[super dealloc];
}

- (void)setFileExists:(BOOL)abool atPath:(NSString *)path {
	if ( cacheSize > cacheMaxSize ) {
		// since we don't check for duplicated items, cacheSize is only a best guess. Get the accurate count here
		cacheSize = [cacheDictionary count];
		if ( cacheSize > cacheMaxSize ) {
			// remove a few older items from the cache. older items are in the head of the list
			NSArray * oldStuff = [orderList subarrayWithRange:NSMakeRange(0, cleanSize)];
			[cacheDictionary removeObjectsForKeys:oldStuff];
			cacheSize -= cleanSize;
		}
	}
	[cacheDictionary setObject:(abool ? yesNumber : noNumber) forKey:path];
	[orderList addObject:path];
	cacheSize++;
}

- (NMFileExistsType)fileExistsAtPath:(NSString *)path {
	// tri-state
	NSNumber * val = [cacheDictionary objectForKey:path];
	if ( val ) {
		return [val boolValue] ? NMFileExists : NMFileDoesNotExist;
	}
	return NMFileExistsNotCached;
}

//- (void)setObject:(id)anObject forKey:(id)aKey {
//	if ( cacheSize > cacheMaxSize ) {
//		// since we don't check for duplicated items, cacheSize is only a best guess. Get the accurate count here
//		cacheSize = [cacheDictionary count];
//		if ( cacheSize > cacheMaxSize ) {
//			// remove a few older items from the cache. older items are in the head of the list
//			NSArray * oldStuff = [orderList subarrayWithRange:NSMakeRange(0, 3)];
//			[cacheDictionary removeObjectsForKeys:oldStuff];
//			cacheSize -= 3;
//		}
//	}
//	[cacheDictionary setObject:anObject forKey:aKey];
//	[orderList addObject:aKey];
//	cacheSize++;
//}

//- (id)objectForKey:(id)aKey {
//	return [cacheDictionary objectForKey:aKey];
//}

@end
