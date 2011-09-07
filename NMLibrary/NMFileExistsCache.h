//
//  NMCacheDictionary.h
//  ipad
//
//  Created by Bill So on 6/9/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	NMFileExistsNotCached,
	NMFileExists,
	NMFileDoesNotExist,
} NMFileExistsType;

/*!
 NMFileExistsCache not officially an NSDictionary subsclass. It's a wrapper of NSMutableDictionary where the size of the dictionary is constrained to avoid ever expanding memory cache.
 */

@interface NMFileExistsCache : NSObject {
	NSMutableDictionary * cacheDictionary;
	NSMutableArray * orderList;
	NSUInteger cacheSize;
	NSUInteger cacheMaxSize;
	NSUInteger cleanSize;
	NSNumber * yesNumber, *noNumber;
}

- (id)initWithCapacity:(NSUInteger)numItems;
- (void)setFileExists:(BOOL)abool atPath:(NSString *)path;
- (NMFileExistsType)fileExistsAtPath:(NSString *)path;
//- (void)setObject:(id)anObject forKey:(id)aKey;
//- (id)objectForKey:(id)aKey;

@end
