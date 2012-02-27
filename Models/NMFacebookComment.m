//
//  NMFacebookComment.m
//  ipad
//
//  Created by Bill So on 2/9/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "NMFacebookComment.h"
#import "NMPersonProfile.h"


@implementation NMFacebookComment

@dynamic created_time;
@dynamic message;
@synthesize object_id;
@dynamic facebookInfo;
@dynamic fromPerson;

- (NSString *)relativeTimeString
{
    NSTimeInterval ageInSeconds = [[NSDate date] timeIntervalSince1970] - [self.created_time floatValue];
    
    if (ageInSeconds < 60) {
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
