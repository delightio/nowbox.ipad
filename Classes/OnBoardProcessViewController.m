//
//  OnBoardProcessViewController.m
//  ipad
//
//  Created by Chris Haugli on 11/2/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "OnBoardProcessViewController.h"
#import "NMTaskQueueController.h"
#import "NMDataController.h"
#import "NMDataType.h"
#import "NMCategory.h"

#define kCategoryListNumberOfColumns 2
#define kCategoryListItemHeight 50
#define kCategoryListItemPadding 10

@implementation OnBoardProcessViewController

@synthesize loginView;
@synthesize infoView;
@synthesize channelsView;
@synthesize featuredCategories;
@synthesize categoriesView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        subscribingCategories = [[NSMutableIndexSet alloc] init];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(handleDidSubscribeNotification:) name:NMDidSubscribeChannelNotification object:nil];
        [nc addObserver:self selector:@selector(handleLaunchFailNotification:) name:NMDidFailSubscribeChannelNotification object:nil];
        [nc addObserver:self selector:@selector(handleDidGetChannelsNotification:) name:NMDidGetChannelsNotification object:nil];
        [nc addObserver:self selector:@selector(handleLaunchFailNotification:) name:NMDidFailGetChannelsNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [subscribingCategories release];
    [loginView release];
    [infoView release];
    [channelsView release];
    [featuredCategories release];
    [categoriesView release];
    
    [super dealloc];
}

#pragma mark - Actions

- (void)categoryButtonPressed:(id)sender
{
    UIButton *categoryButton = (UIButton *)sender;
    NSInteger categoryIndex = [categoryButton tag];
    if ([subscribingCategories containsIndex:categoryIndex]) {
        [categoryButton setBackgroundImage:[[UIImage imageNamed:@"button-gray-background"] stretchableImageWithLeftCapWidth:7 topCapHeight:0] forState:UIControlStateNormal];
        [categoryButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];        
        [subscribingCategories removeIndex:categoryIndex];
    } else {
        [categoryButton setBackgroundImage:[[UIImage imageNamed:@"button-red-background"] stretchableImageWithLeftCapWidth:7 topCapHeight:0] forState:UIControlStateNormal];
        [categoryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [subscribingCategories addIndex:categoryIndex];
    }
}

- (void)transitionFromView:(UIView *)view1 toView:(UIView *)view2
{
    view2.frame = CGRectOffset(self.view.bounds, self.view.bounds.size.width, 0);
    [self.view addSubview:view2];
    
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         view1.frame = CGRectOffset(view1.frame, -self.view.bounds.size.width, 0);
                         view2.frame = CGRectOffset(view2.frame, -self.view.bounds.size.width, 0);
                     }
                     completion:^(BOOL finished){
                         [view1 removeFromSuperview];                         
                     }];    
}

- (IBAction)switchToInfoView:(id)sender
{
    [self transitionFromView:loginView toView:infoView];
    
    // Start subscribing to channels based on user's category choices
    // for (...)
    //        [[NMTaskQueueController sharedTaskQueueController] issueSubscribe:YES channel:channel];
    //        [[NMTaskQueueController sharedTaskQueueController] issueSubscribe:YES channel:channel];        
}

- (IBAction)switchToChannelsView:(id)sender
{
    [self transitionFromView:infoView toView:channelsView];
}

- (IBAction)switchToPlaybackView:(id)sender
{
    [self dismissModalViewControllerAnimated:NO];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"playback_background_pattern"]];
    loginView.backgroundColor = [UIColor clearColor];
    infoView.backgroundColor = [UIColor clearColor];
    channelsView.backgroundColor = [UIColor clearColor];
    
    // Sort the categories by name
    NSArray *categories = [[[NMTaskQueueController sharedTaskQueueController] dataController] categories];
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    self.featuredCategories = [categories sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter]];
    [sorter release];
    
    // Now we can populate the featured category list
    CGFloat itemWidth = (categoriesView.frame.size.width - (kCategoryListNumberOfColumns - 1) * kCategoryListItemPadding) / kCategoryListNumberOfColumns;
    
    NSInteger row = 0, col = 0;
    for (NMCategory *category in featuredCategories) {
        UIButton *categoryButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        categoryButton.frame = CGRectMake(col * (itemWidth + kCategoryListItemPadding), row * (kCategoryListItemHeight + kCategoryListItemPadding),
                                          itemWidth, kCategoryListItemHeight);
        [categoryButton setTitle:category.title forState:UIControlStateNormal];
        [categoryButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [categoryButton setBackgroundImage:[[UIImage imageNamed:@"button-gray-background"] stretchableImageWithLeftCapWidth:7 topCapHeight:0] forState:UIControlStateNormal];
        [categoryButton setTag:row*kCategoryListNumberOfColumns + col];
        [categoryButton addTarget:self action:@selector(categoryButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [categoriesView addSubview:categoryButton];
        
        col++;
        if (col >= kCategoryListNumberOfColumns) {
            row++;            
            col = 0;
        }
    }
    
    // Show the login page to start
    [loginView setFrame:self.view.bounds];
    [self.view addSubview:loginView];    
}

- (void)viewDidUnload
{
    self.loginView = nil;
    self.categoriesView = nil;
    self.featuredCategories = nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - Notifications

- (void)handleDidSubscribeNotification:(NSNotification *)aNotification 
{
    NSLog(@"Did subscribe:\n%@", [aNotification userInfo]);
    NMCategory *category = [[aNotification userInfo] objectForKey:@"category"];
    NSInteger subscribedIndex = [featuredCategories indexOfObject:category];
    [subscribingCategories removeIndex:subscribedIndex];
}

- (void)handleLaunchFailNotification:(NSNotification *)aNotification 
{
    // TODO
}

@end
