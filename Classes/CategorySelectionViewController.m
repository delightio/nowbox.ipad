//
//  CategorySelectionViewController.m
//  ipad
//
//  Created by Chris Haugli on 11/3/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "CategorySelectionViewController.h"
#import "NMCategory.h"

#define kGridMargin 30

@implementation CategorySelectionViewController

@synthesize categoryGrid;

- (id)initWithCategories:(NSArray *)aCategories
{
    self = [super init];
    if (self) {
        categories = [aCategories retain];
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
    self.title = @"Select Your Interests";
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissView:)] autorelease];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(updateCategories:)] autorelease];

    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 600, 400)];

    NSMutableArray *categoryTitles = [NSMutableArray array];
    for (NMCategory *category in categories) {
        [categoryTitles addObject:category.title];
    }
    
    categoryGrid = [[CategorySelectionGrid alloc] initWithFrame:CGRectMake(kGridMargin, kGridMargin, view.bounds.size.width - kGridMargin * 2, view.bounds.size.height - kGridMargin * 2)];
    [categoryGrid setCategoryTitles:categoryTitles];
    [categoryGrid setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [view addSubview:categoryGrid];
    [categoryGrid release];
    
    self.view = view;
    [view release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

#pragma mark - Actions

- (void)dismissView:(id)sender 
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)updateCategories:(id)sender 
{
    // TODO
    
    [self dismissView:sender];
}

@end
