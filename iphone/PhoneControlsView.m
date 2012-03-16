//
//  PhoneControlsView.m
//  ipad
//
//  Created by Chris Haugli on 2/22/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "PhoneControlsView.h"
#import "UIFont+BackupFont.h"

@implementation PhoneControlsView

@synthesize backgroundView;

- (void)awakeFromNib
{
    [super awakeFromNib];

    UIFont *labelFont = [UIFont fontWithName:@"Futura-CondensedMedium" size:16.0f backupFontName:@"Futura-Medium" size:13.0f];
    durationLabel.font = labelFont;
    currentTimeLabel.font = labelFont;
    seekBubbleButton.titleLabel.font = labelFont;
}

- (void)dealloc
{
    [backgroundView release];
    [super dealloc];
}

@end
