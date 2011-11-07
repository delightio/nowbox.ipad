//
//  OnBoardProcessViewController.h
//  ipad
//
//  Created by Chris Haugli on 11/2/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CategorySelectionGrid.h"
#import "CategorySelectionViewController.h"
#import "GridScrollView.h"

@protocol OnBoardProcessViewControllerDelegate;

@interface OnBoardProcessViewController : UIViewController <UIAlertViewDelegate, GridScrollViewDelegate, CategorySelectionViewControllerDelegate> {
    BOOL userCreated;
    NSMutableSet *subscribingChannels;
    BOOL scrollingFromPageControl;
    
    UIView *currentView;    
}

@property (nonatomic, retain) NSArray *featuredCategories;
@property (nonatomic, retain) NSSet *featuredChannels;
@property (nonatomic, retain) NSArray *subscribedChannels;
@property (nonatomic, assign) id<OnBoardProcessViewControllerDelegate> delegate;

// Step 1: YouTube login / category selection
@property (nonatomic, retain) IBOutlet UIView *loginView;
@property (nonatomic, retain) IBOutlet CategorySelectionGrid *categoryGrid;

// Step 2: NOWMOV info
@property (nonatomic, retain) IBOutlet UIView *infoView;
@property (nonatomic, retain) IBOutlet UIButton *proceedToChannelsButton;

// Step 3: Auto-selected channels
@property (nonatomic, retain) IBOutlet UIView *channelsView;
@property (nonatomic, retain) IBOutlet GridScrollView *channelsScrollView;
@property (nonatomic, retain) IBOutlet UIPageControl *channelsPageControl;

- (IBAction)loginToYouTube:(id)sender;
- (IBAction)switchToInfoView:(id)sender;
- (IBAction)switchToChannelsView:(id)sender;
- (IBAction)addInterests:(id)sender;
- (IBAction)pageControlValueChanged:(id)sender;
- (void)notifyVideosReady;

@end

@protocol OnBoardProcessViewControllerDelegate <NSObject>
- (void)onBoardProcessViewControllerDidFinish:(OnBoardProcessViewController *)controller;
@end