//
//  GridViewController.h
//  ipad
//
//  Created by Chris Haugli on 2/6/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PagingGridView.h"
#import "CustomPageControl.h"
#import "GridDataSource.h"

@interface GridViewController : UIViewController <PagingGridViewDelegate, CustomPageControlDelegate> {
    BOOL scrollingToPage;
}

@property (nonatomic, retain) IBOutlet PagingGridView *gridView;
@property (nonatomic, retain) IBOutlet CustomPageControl *pageControl;
@property (nonatomic, retain) GridDataSource *gridDataSource;

- (IBAction)searchButtonPressed:(id)sender;
- (IBAction)refreshButtonPressed:(id)sender;
- (IBAction)settingsButtonPressed:(id)sender;

@end
