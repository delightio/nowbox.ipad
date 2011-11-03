//
//  OnBoardProcessViewController.h
//  ipad
//
//  Created by Chris Haugli on 11/2/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OnBoardProcessViewController : UIViewController {
    NSMutableIndexSet *subscribingCategories;
}

@property (nonatomic, retain) IBOutlet UIView *loginView;
@property (nonatomic, retain) IBOutlet UIView *infoView;
@property (nonatomic, retain) IBOutlet UIView *channelsView;
@property (nonatomic, retain) NSArray *featuredCategories;

// Step 1: YouTube login / category selection
@property (nonatomic, retain) IBOutlet UIView *categoriesView;

- (IBAction)switchToInfoView:(id)sender;
- (IBAction)switchToChannelsView:(id)sender;

@end
