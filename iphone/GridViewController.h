//
//  GridViewController.h
//  ipad
//
//  Created by Chris Haugli on 2/6/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PagingGridView.h"

@interface GridViewController : UIViewController <PagingGridViewDataSource>

@property (nonatomic, retain) IBOutlet PagingGridView *gridView;

- (IBAction)searchButtonPressed:(id)sender;
- (IBAction)refreshButtonPressed:(id)sender;
- (IBAction)settingsButtonPressed:(id)sender;

@end
