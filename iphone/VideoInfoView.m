//
//  VideoInfoView.m
//  ipad
//
//  Created by Chris Haugli on 2/13/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "VideoInfoView.h"

@implementation VideoInfoView

@synthesize channelTitleLabel;
@synthesize videoTitleLabel;
@synthesize channelThumbnail;

- (void)dealloc
{
    [channelTitleLabel release];
    [videoTitleLabel release];
    [channelThumbnail release];
    
    [super dealloc];
}

@end
