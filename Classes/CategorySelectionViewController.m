//
//  CategorySelectionViewController.m
//  ipad
//
//  Created by Chris Haugli on 11/3/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "CategorySelectionViewController.h"

@implementation CategorySelectionViewController

@synthesize categories;

- (id)initWithCategories:(NSArray *)aCategories
{
    self = [super init];
    if (self) {
        self.categories = aCategories;
    }
    return self;
}

- (void)dealloc
{
    [categories release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 600, 400)];
    
    
    
    self.view = view;
    [view release];
}

@end
