//
//  PhoneOnBoardProcessViewController.m
//  ipad
//
//  Created by Chris Haugli on 3/28/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "PhoneOnBoardProcessViewController.h"
#import "OnBoardProcessCategoryView.h"
#import "UIFont+BackupFont.h"
#import <QuartzCore/QuartzCore.h>

@interface PhoneOnBoardProcessViewController (PrivateMethods)
- (void)updateSelectedButtonImage:(UIButton *)button;
@end

@implementation PhoneOnBoardProcessViewController

@synthesize categoryOverlayView;

- (void)dealloc
{
    [categoryOverlayView release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.categoryGrid.horizontalItemPadding = 1.0f;
    self.categoryGrid.verticalItemPadding = 1.0f;
    self.categoryGrid.itemSize = CGSizeMake(152, 46);
    self.categoryGrid.numberOfColumns = 2;
    self.categoryGrid.layer.masksToBounds = YES;
    self.categoryGrid.layer.cornerRadius = 5.0f;
    self.categoryGrid.superview.layer.masksToBounds = YES;
    self.categoryGrid.superview.layer.cornerRadius = 5.0f;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.categoryOverlayView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (IBAction)categorySelected:(id)sender
{
	[super categorySelected:sender];
    [self updateSelectedButtonImage:sender];
}

- (IBAction)dismissCategoryOverlayView:(id)sender
{
    [UIView animateWithDuration:0.3
                     animations:^{
                         categoryOverlayView.alpha = 0;
                     }
                     completion:^(BOOL finished){
                         [categoryOverlayView removeFromSuperview];
                         self.categoryOverlayView = nil;
                     }];
}

#pragma mark - Private methods

- (void)updateSelectedButtonImage:(UIButton *)button
{
    if ([button isSelected]) {
        // We could have configured this in the xib, but then the checked image wouldn't have adjusted on highlight
        [button setImage:[UIImage imageNamed:@"phone_onboard_category_checked.png"] forState:UIControlStateNormal];
    } else {
        [button setImage:[UIImage imageNamed:@"phone_onboard_category_unchecked.png"] forState:UIControlStateNormal];
    }    
}

#pragma mark - Notifications

- (void)handleDidSubscribeNotification:(NSNotification *)aNotification 
{
    NMChannel *channel = [[aNotification userInfo] objectForKey:@"channel"];
    [self.subscribingChannels removeObject:channel];
    
    if ([self.subscribingChannels count] == 0) {
        // All channels have been subscribed to
        [[NMTaskQueueController sharedTaskQueueController] issueGetSubscribedChannels];
    }
}

- (void)handleDidGetChannelsNotification:(NSNotification *)aNotification
{
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.settingUpView.alpha = 0;
                         self.proceedToChannelsButton.alpha = 1;
                     }];
}

#pragma mark - GridScrollViewDelegate

- (UIView *)gridScrollView:(GridScrollView *)gridScrollView viewForItemAtIndex:(NSUInteger)index
{
    if (gridScrollView == self.categoryGrid) {
        // Categories
        NMCategory *category = [self.featuredCategories objectAtIndex:index];
        
		OnBoardProcessCategoryView *categoryView = (OnBoardProcessCategoryView *)[gridScrollView dequeueReusableSubview];
        if (!categoryView) {
			categoryView = [[[OnBoardProcessCategoryView alloc] init] autorelease];
            [categoryView.button addTarget:self action:@selector(categorySelected:) forControlEvents:UIControlEventTouchUpInside];
            [categoryView.button.titleLabel setFont:[UIFont fontWithName:@"Futura-CondensedMedium" size:20.0 backupFontName:@"Futura-Medium" size:16.0]];
            [categoryView.button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateSelected | UIControlStateHighlighted];
        }
        
        [categoryView.button setTag:index];
        [categoryView.button setTitle:category.title forState:UIControlStateNormal];
        [categoryView.button setSelected:[self.selectedCategoryIndexes containsIndex:index]];
        [self updateSelectedButtonImage:categoryView.button];
        
        return categoryView;
    }
    
    return [super gridScrollView:gridScrollView viewForItemAtIndex:index];
}

@end
