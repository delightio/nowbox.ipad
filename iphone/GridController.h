//
//  GridController.h
//  ipad
//
//  Created by Chris Haugli on 11/29/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GridScrollView.h"
#import "NMChannel.h"
#import "NMVideo.h"

@protocol GridControllerDelegate;
@class SizableNavigationController;

@interface GridController : UIViewController <GridScrollViewDelegate, NSFetchedResultsControllerDelegate, UISearchBarDelegate>

@property (nonatomic, retain) IBOutlet GridScrollView *gridView;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UIButton *backButton;
@property (nonatomic, retain) IBOutlet UIButton *actionButton;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, assign) SizableNavigationController *navigationController;
@property (nonatomic, assign) id<GridControllerDelegate> delegate;

- (IBAction)backButtonPressed:(id)sender;
- (IBAction)actionButtonPressed:(id)sender;

@end

@protocol GridControllerDelegate <NSObject>
- (void)gridController:(GridController *)gridController didSelectChannel:(NMChannel *)channel;
- (void)gridController:(GridController *)gridController didSelectVideo:(NMVideo *)video;
@end
