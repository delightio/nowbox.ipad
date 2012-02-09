//
//  NMObjectCache.h
//  ipad
//
//  Created by Bill So on 1/28/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NMObjectCache : NSObject {
	NSMutableDictionary *cache;
	NSMutableArray *cacheKeyArray;
	NSInteger sizeLimit;
}

- (id)objectForKey:(id)aKey;
- (void)setObject:(id)obj forKey:(id)aKey;

@end
