//
//  NSString+Formatting.h
//  ipad
//
//  Created by Chris Haugli on 3/12/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Formatting)

// Returns a string shorter than or equal to the specified length, cut off (with ellipses) at whitespace if possible.
- (NSString *)stringLimitedToLength:(NSUInteger)length;

@end
