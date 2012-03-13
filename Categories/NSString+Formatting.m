//
//  NSString+Formatting.m
//  ipad
//
//  Created by Chris Haugli on 3/12/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NSString+Formatting.h"

@implementation NSString (Formatting)

- (NSString *)stringLimitedToLength:(NSUInteger)length
{
    if ([self length] <= length) return self;
    
    NSString *cutOffString = [self substringToIndex:length];
    NSRange lastWhitespace = [cutOffString rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]
                                                                options:NSBackwardsSearch];
    if (lastWhitespace.location != NSNotFound) {
        cutOffString = [cutOffString substringToIndex:lastWhitespace.location];
    }
    
    return [NSString stringWithFormat:@"%@...", cutOffString];
}

@end
