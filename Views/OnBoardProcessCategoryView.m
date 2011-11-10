//
//  OnBoardProcessCategoryView.m
//  ipad
//
//  Created by Chris Haugli on 11/10/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "OnBoardProcessCategoryView.h"

@implementation OnBoardProcessCategoryView

@synthesize contentView;
@synthesize button;
@synthesize titleLabel;
@synthesize title;

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
    
    titleLabel.text = @"";
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setupWithExistingFrame:NO];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupWithExistingFrame:YES];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupWithExistingFrame:NO];
    }
    return self;
}

- (void)dealloc
{
    [contentView release];
    [titleLabel release];
    [button release];
    [title release];
    
    [super dealloc];
}

- (void)setTitle:(NSString *)aTitle
{
    if (title != aTitle) {
        [title release];
        title = [aTitle copy];
        titleLabel.text = aTitle;
    }
}

@end
