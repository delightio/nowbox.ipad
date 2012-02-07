//
//  ThumbnailView.m
//  ipad
//
//  Created by Chris Haugli on 2/6/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "ThumbnailView.h"

@implementation ThumbnailView

@synthesize contentView;
@synthesize image;
@synthesize label;
@synthesize activityIndicator;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Load the view from a nib
        [[NSBundle mainBundle] loadNibNamed:@"ThumbnailView" owner:self options:nil];
        
        if (CGRectEqualToRect(frame, CGRectZero)) {
            self.frame = contentView.bounds;
        }

        contentView.frame = self.bounds;        
        contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:contentView];
        
        // Set the font depending on if it's available (iOS 4 doesn't have Futura Condensed Medium)
        UIFont *font = [UIFont fontWithName:@"Futura-CondensedMedium" size:label.font.pointSize];
        if (!font) {
            font = [UIFont fontWithName:@"Futura-Medium" size:label.font.pointSize];
        }
        [label setFont:font];
    }
    return self;
} 

- (void)dealloc
{
    [contentView release];
    [image release];
    [label release];
    [activityIndicator release];
    
    [super dealloc];
}

@end
