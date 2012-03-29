//
//  PhoneOnBoardProcessViewController.h
//  ipad
//
//  Created by Chris Haugli on 3/28/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import "OnBoardProcessViewController.h"

@interface PhoneOnBoardProcessViewController : OnBoardProcessViewController

@property (nonatomic, retain) IBOutlet UIView *categoryOverlayView;

- (IBAction)dismissCategoryOverlayView:(id)sender;

@end
