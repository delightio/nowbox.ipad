//
//  CategorySelectionViewController.m
//  ipad
//
//  Created by Chris Haugli on 11/3/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "CategorySelectionViewController.h"
#import "NMTaskQueueController.h"
#import "NMCategory.h"
#import "NMChannel.h"
#import "NMTaskType.h"
#import <QuartzCore/QuartzCore.h>

@implementation CategorySelectionViewController

@synthesize categoryGrid;
@synthesize progressView;
@synthesize selectedCategoryIndexes;
@synthesize delegate;

- (id)initWithCategories:(NSArray *)aCategories selectedCategoryIndexes:(NSMutableIndexSet *)aSelectedCategoryIndexes subscribedChannels:(NSSet *)aSubscribedChannels
{
    self = [super initWithNibName:@"CategorySelectionView" bundle:[NSBundle mainBundle]];
    if (self) {
        categories = [[NSArray alloc] initWithArray:aCategories];
        subscribedChannels = [[NSSet alloc] initWithSet:aSubscribedChannels];
        selectedCategoryIndexes = [[NSMutableIndexSet alloc] initWithIndexSet:aSelectedCategoryIndexes];
        subscribingChannels = [[NSMutableSet alloc] init];
        unsubscribingChannels = [[NSMutableSet alloc] init];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(handleDidGetFeaturedChannelsNotification:) name:NMDidGetFeaturedChannelsForCategories object:nil];
        [nc addObserver:self selector:@selector(handleDidSubscribeNotification:) name:NMDidSubscribeChannelNotification object:nil];
        [nc addObserver:self selector:@selector(handleDidUnsubscribeNotification:) name:NMDidUnsubscribeChannelNotification object:nil];
        [nc addObserver:self selector:@selector(handleDidGetChannelsNotification:) name:NMDidGetChannelsNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [categories release];
    [subscribedChannels release];
    [selectedCategoryIndexes release];
    [subscribingChannels release];
    [unsubscribingChannels release];
    [categoryGrid release];
    [progressView release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Interests";
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissView:)] autorelease];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(updateCategories:)] autorelease];

    NSMutableArray *categoryTitles = [NSMutableArray array];
    for (NMCategory *category in categories) {
        [categoryTitles addObject:category.title];
    }
    
    [categoryGrid setCategoryTitles:categoryTitles];
    [categoryGrid setSelectedButtonIndexes:selectedCategoryIndexes];
    
    [progressView.layer setCornerRadius:25.0f];
    [progressView.layer setMasksToBounds:YES];
}

- (void)viewDidUnload
{
    self.categoryGrid = nil;
    self.progressView = nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

#pragma mark - Actions

- (void)dismissView:(id)sender 
{
    [delegate categorySelectionViewControllerWillDismiss:self];
	[self dismissModalViewControllerAnimated:YES];
}

- (void)updateCategories:(id)sender 
{
    NSIndexSet *oldIndexes = selectedCategoryIndexes;
    NSIndexSet *newIndexes = categoryGrid.selectedButtonIndexes;
    
    if ([oldIndexes isEqualToIndexSet:newIndexes]) {
        [self dismissView:sender];
    } else {
        // Get new list of featured channels
        progressView.hidden = NO;
        categoryGrid.userInteractionEnabled = NO;
        [[NMTaskQueueController sharedTaskQueueController] issueGetFeaturedChannelsForCategories:[categories objectsAtIndexes:categoryGrid.selectedButtonIndexes]];
    }
}

#pragma mark - Notifications

- (void)handleDidGetFeaturedChannelsNotification:(NSNotification *)aNotification
{
    NSArray *featuredChannels = [[aNotification userInfo] objectForKey:@"channels"];
    [subscribingChannels removeAllObjects];
    
    // Unsubscribe to channels that are no longer present
    for (NMChannel *oldChannel in subscribedChannels) {
        BOOL found = NO;
        for (NMChannel *newChannel in featuredChannels) {
            if ([newChannel.nm_id isEqualToNumber:oldChannel.nm_id]) {
                found = YES;
                break;
            }
        }
        
        if (!found) {
            [[NMTaskQueueController sharedTaskQueueController] issueSubscribe:NO channel:oldChannel];
            [unsubscribingChannels addObject:oldChannel];
            NSLog(@"--> unsubscribing to %@", oldChannel.title);
        }
    }

    // Subscribe to new channels that weren't there before
    for (NMChannel *newChannel in featuredChannels) {        
        BOOL found = NO;
        for (NMChannel *oldChannel in subscribedChannels) {
            if ([oldChannel.nm_id isEqualToNumber:newChannel.nm_id]) {
                found = YES;
                break;
            }
        }
        
        if (!found) {
            [[NMTaskQueueController sharedTaskQueueController] issueSubscribe:YES channel:newChannel];
            [subscribingChannels addObject:newChannel];
            NSLog(@"--> subscribing to %@", newChannel.title);  
        }
    }
    
    if ([unsubscribingChannels count] == 0 && [subscribingChannels count] == 0) {
        // No changes
        [self dismissView:nil];
    }
}

- (void)handleDidSubscribeNotification:(NSNotification *)aNotification 
{
    NMChannel *channel = [[aNotification userInfo] objectForKey:@"channel"];
    [subscribingChannels removeObject:channel];
    
    if ([subscribingChannels count] == 0 && [unsubscribingChannels count] == 0) {
        // All channels have been subscribed to / unsubscribed from - ready to get the channel list
        [[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
    }
}

- (void)handleDidUnsubscribeNotification:(NSNotification *)aNotification 
{
    NMChannel *channel = [[aNotification userInfo] objectForKey:@"channel"];
    [unsubscribingChannels removeObject:channel];
    
    if ([subscribingChannels count] == 0 && [unsubscribingChannels count] == 0) {
        // All channels have been subscribed to / unsubscribed from - ready to get the channel list
        [[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
    }
}

- (void)handleDidGetChannelsNotification:(NSNotification *)aNotification 
{
    [self dismissView:nil];
}

@end
