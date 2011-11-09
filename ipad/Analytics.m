//
//  Analytics.m
//  ipad
//
//  Created by Chris Haugli on 10/28/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "Analytics.h"

@implementation Analytics

+ (id)sharedAPI {
#ifdef MIXPANEL
    return [MixpanelAPI sharedAPI];
#else
    return nil;
#endif
}

@end