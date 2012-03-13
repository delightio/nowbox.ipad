//
//  OnBoardProcessViewController.h
//  ipad
//
//  Created by Chris Haugli on 11/2/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SocialLoginViewController.h"
#import "GridScrollView.h"

@protocol OnBoardProcessViewControllerDelegate;
@class TwitterAccountPickerViewController;

@interface OnBoardProcessViewController : UIViewController <UIAlertViewDelegate, GridScrollViewDelegate> {    
    UIView *currentView;    
    
    // YouTube sync can take ages. Have a timeout while waiting for the compare channels notification.
    NSTimer *youtubeTimeoutTimer;
    
    // Force user to wait at info page at least a few seconds
    NSTimer *infoWaitTimer;
    
    BOOL youtubeSynced;
    BOOL infoWaitTimerFired;
    BOOL videosReady;
    BOOL userCreated;
    BOOL alertShowing;
    
    SocialLoginViewController *socialController;
	TwitterAccountPickerViewController * twitterAccountPicker;
}

@property (nonatomic, retain) NSArray *featuredCategories;
@property (nonatomic, retain) NSMutableIndexSet *selectedCategoryIndexes;
@property (nonatomic, retain) NSArray *subscribedChannels;
@property (nonatomic, retain) NSMutableSet *subscribingChannels;
@property (nonatomic, assign) id<OnBoardProcessViewControllerDelegate> delegate;

// Step 1: Splash screen
@property (nonatomic, retain) IBOutlet UIView *splashView;
@property (nonatomic, retain) IBOutlet UIView *slideInView;
@property (nonatomic, retain) IBOutlet UIButton *tappableArea;

// Step 2: Category selection
@property (nonatomic, retain) IBOutlet UIView *categoriesView;
@property (nonatomic, retain) IBOutlet GridScrollView *categoryGrid;
@property (nonatomic, retain) IBOutlet UIButton *proceedToSocialButton;

// Step 3: Social login
@property (nonatomic, retain) IBOutlet UIView *socialView;
@property (nonatomic, retain) IBOutlet UIButton *youtubeButton;
@property (nonatomic, retain) IBOutlet UIButton *facebookButton;
@property (nonatomic, retain) IBOutlet UIButton *twitterButton;

// Step 4: NOWMOV info
@property (nonatomic, retain) IBOutlet UIView *infoView;
@property (nonatomic, retain) IBOutlet UIView *settingUpView;
@property (nonatomic, retain) IBOutlet UIButton *proceedToChannelsButton;

// Step 5: Auto-selected channels
@property (nonatomic, retain) IBOutlet UIView *channelsView;
@property (nonatomic, retain) IBOutlet GridScrollView *channelsScrollView;

- (IBAction)categorySelected:(id)sender;
- (IBAction)loginToYouTube:(id)sender;
- (IBAction)loginToFacebook:(id)sender;
- (IBAction)loginToTwitter:(id)sender;
- (IBAction)switchToCategoriesView:(id)sender;
- (IBAction)switchToSocialView:(id)sender;
- (IBAction)switchToInfoView:(id)sender;
- (IBAction)switchToChannelsView:(id)sender;
- (void)notifyVideosReady;
- (void)updateSocialNetworkButtonTexts;

@end

@protocol OnBoardProcessViewControllerDelegate <NSObject>
- (void)onBoardProcessViewControllerDidFinish:(OnBoardProcessViewController *)controller;
@end