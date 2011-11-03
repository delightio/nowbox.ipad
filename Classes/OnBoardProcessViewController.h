//
//  OnBoardProcessViewController.h
//  ipad
//
//  Created by Chris Haugli on 11/2/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OnBoardProcessViewController : UIViewController <UIAlertViewDelegate> {
    BOOL userCreated;
    NSMutableIndexSet *subscribingCategories;
    NSMutableSet *subscribingChannels;    
    
    UIView *currentView;
}

@property (nonatomic, retain) NSArray *featuredCategories;

// Step 1: YouTube login / category selection
@property (nonatomic, retain) IBOutlet UIView *loginView;
@property (nonatomic, retain) IBOutlet UIView *categoriesView;

// Step 2: NOWMOV info
@property (nonatomic, retain) IBOutlet UIView *infoView;
@property (nonatomic, retain) IBOutlet UIButton *proceedToChannelsButton;

// Step 3: Auto-selected channels
@property (nonatomic, retain) IBOutlet UIView *channelsView;

- (IBAction)switchToInfoView:(id)sender;
- (IBAction)switchToChannelsView:(id)sender;

@end
