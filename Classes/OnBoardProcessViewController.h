//
//  OnBoardProcessViewController.h
//  ipad
//
//  Created by Chris Haugli on 11/2/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SocialLoginViewController.h"
#import "CategorySelectionGrid.h"
#import "GridScrollView.h"
#import "GradientView.h"

@protocol OnBoardProcessViewControllerDelegate;

@interface OnBoardProcessViewController : UIViewController <UIAlertViewDelegate, GridScrollViewDelegate> {
    BOOL scrollingFromPageControl;
    
    UIView *currentView;    
    NSTimer *youtubeTimeoutTimer;
    BOOL youtubeSynced;
    
    SocialLoginViewController *socialController;
}

@property (nonatomic, retain) NSArray *featuredCategories;
@property (nonatomic, retain) NSArray *subscribedChannels;
@property (nonatomic, retain) NSMutableSet *subscribingChannels;
@property (nonatomic, assign) id<OnBoardProcessViewControllerDelegate> delegate;

@property (nonatomic, retain) IBOutlet GradientView *mainGradient;

// Step 1: Category selection
@property (nonatomic, retain) IBOutlet UIView *categoriesView;
@property (nonatomic, retain) IBOutlet CategorySelectionGrid *categoryGrid;
@property (nonatomic, retain) IBOutlet UIButton *proceedToSocialButton;

// Step 2: Social login
@property (nonatomic, retain) IBOutlet UIView *socialView;
@property (nonatomic, retain) IBOutlet UIButton *youtubeButton;
@property (nonatomic, retain) IBOutlet UIButton *facebookButton;
@property (nonatomic, retain) IBOutlet UIButton *twitterButton;

// Step 3: NOWMOV info
@property (nonatomic, retain) IBOutlet UIView *infoView;
@property (nonatomic, retain) IBOutlet UIButton *proceedToChannelsButton;

// Step 4: Auto-selected channels
@property (nonatomic, retain) IBOutlet UIView *channelsView;
@property (nonatomic, retain) IBOutlet GridScrollView *channelsScrollView;
@property (nonatomic, retain) IBOutlet UIPageControl *channelsPageControl;

- (IBAction)loginToYouTube:(id)sender;
- (IBAction)loginToFacebook:(id)sender;
- (IBAction)loginToTwitter:(id)sender;
- (IBAction)switchToSocialView:(id)sender;
- (IBAction)switchToInfoView:(id)sender;
- (IBAction)switchToChannelsView:(id)sender;
- (IBAction)pageControlValueChanged:(id)sender;
- (void)notifyVideosReady;

@end

@protocol OnBoardProcessViewControllerDelegate <NSObject>
- (void)onBoardProcessViewControllerDidFinish:(OnBoardProcessViewController *)controller;
@end