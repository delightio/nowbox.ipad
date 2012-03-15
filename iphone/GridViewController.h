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
#import "GlowLabel.h"

@interface GridViewController : UIViewController <PagingGridViewDelegate, UIScrollViewDelegate, CustomPageControlDelegate> {
    BOOL scrollingToPage;
    NSUInteger currentPage;
}

@property (nonatomic, retain) IBOutlet PagingGridView *gridView;
@property (nonatomic, retain) IBOutlet UIView *nowboxLogo;
@property (nonatomic, retain) IBOutlet GlowLabel *titleLabel;
@property (nonatomic, retain) IBOutlet UIButton *backButton;
@property (nonatomic, retain) IBOutlet UIButton *refreshButton;
@property (nonatomic, retain) IBOutlet CustomPageControl *pageControl;
@property (nonatomic, retain) GridDataSource *gridDataSource;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aManagedObjectContext nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
- (IBAction)refreshButtonPressed:(id)sender;
- (IBAction)backButtonPressed:(id)sender;

@end
