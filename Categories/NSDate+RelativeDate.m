//
//  NSDate+RelativeDate.m
//  ipad
//
//  Created by Chris Haugli on 4/2/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NSDate+RelativeDate.h"

@implementation NSDate (RelativeDate)

- (NSString *)relativeDateString
{
    NSTimeInterval ageInSeconds = [[NSDate date] timeIntervalSinceDate:self];

    if (ageInSeconds <= 0) {
        return @"Just now";
    } else if (ageInSeconds < 60) {
        return [NSString stringWithFormat:@"%i sec ago", (NSInteger)ageInSeconds];
    } else if (ageInSeconds < 60*60) {
        return [NSString stringWithFormat:@"%i min ago", (NSInteger)(ageInSeconds / 60)];
    } else if (ageInSeconds < 60*60*24) {
        NSInteger hours = (NSInteger)(ageInSeconds / (60*60));
        return [NSString stringWithFormat:@"%i %@ ago", hours, (hours == 1 ? @"hour" : @"hours")];
    } else if (ageInSeconds < 60*60*24*30) {
        NSInteger days = (NSInteger)(ageInSeconds / (60*60*24));
        if (days == 1) return @"Yesterday";
        return [NSString stringWithFormat:@"%i days ago", days];
    } else if (ageInSeconds < 60*60*24*365) {
        NSInteger months = (NSInteger)(ageInSeconds / (60*60*24*30));
        return [NSString stringWithFormat:@"%i %@ ago", months, (months == 1 ? @"month": @"months")];
    } else {
        NSInteger years = (NSInteger)(ageInSeconds / (60*60*24*365));
        return [NSString stringWithFormat:@"%i %@ ago", years, (years == 1 ? @"year" : @"years")];
    }
}

@end
