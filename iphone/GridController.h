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
@class GridNavigationController;

@interface GridController : NSObject <GridScrollViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, retain) IBOutlet UIView *view;
@property (nonatomic, retain) IBOutlet GridScrollView *gridView;
@property (nonatomic, retain) IBOutlet UIButton *backButton;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) NMChannel *currentChannel;
@property (nonatomic, retain) NMVideo *currentVideo;
@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, assign) GridNavigationController *navigationController;
@property (nonatomic, assign) id<GridControllerDelegate> delegate;

- (IBAction)itemPressed:(id)sender;
- (IBAction)backButtonPressed:(id)sender;

@end

@protocol GridControllerDelegate <NSObject>
- (void)gridController:(GridController *)gridController didSelectChannel:(NMChannel *)channel;
- (void)gridController:(GridController *)gridController didSelectVideo:(NMVideo *)video;
@end
