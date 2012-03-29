//
//  OnBoardProcessCategoryView.m
//  ipad
//
//  Created by Chris Haugli on 11/28/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "OnBoardProcessCategoryView.h"

@implementation OnBoardProcessCategoryView

@synthesize contentView;
@synthesize button;
@synthesize thumbnailImageView;

- (void)setupWithExistingFrame:(BOOL)useExistingFrame
{
    [[NSBundle mainBundle] loadNibNamed:@"OnBoardProcessCategoryView" owner:self options:nil];
    
    if (useExistingFrame) {
        contentView.frame = self.bounds;
    } else {
        self.frame = contentView.bounds;
    }
    
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:contentView];
    
    thumbnailImageView.adjustsImageOnHighlight = YES;
    
    [button addTarget:self action:@selector(buttonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(buttonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:self action:@selector(buttonTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
    [button addTarget:self action:@selector(buttonTouchUp:) forControlEvents:UIControlEventTouchDragExit];
    [button addTarget:self action:@selector(buttonTouchUp:) forControlEvents:UIControlEventTouchCancel];
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setupWithExistingFrame:NO];
    }
    return self;
}

- (void)dealloc
{
    [contentView release];
    [button release];
    [thumbnailImageView release];
    
    [super dealloc];
}

- (void)buttonTouchDown:(id)sender
{
    [thumbnailImageView setHighlighted:YES];
}

- (void)buttonTouchUp:(id)sender
{
    [thumbnailImageView setHighlighted:NO];
}

@end
