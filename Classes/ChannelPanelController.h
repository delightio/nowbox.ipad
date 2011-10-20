//
//  ChannelPanelController.h
//  ipad
//
//  Created by Bill So on 6/13/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import "NMStyleUtility.h"
#import "AGOrientedTableView.h"

@class VideoPlaybackViewController;

typedef enum {
	NMFullScreenPlaybackMode,
	NMHalfScreenMode,
	NMFullScreenChannelMode,
} NMPlaybackViewModeType;

@interface ChannelPanelController : NSObject <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, UIPopoverControllerDelegate, UIGestureRecognizerDelegate> {
    IBOutlet UITableView * tableView;
	// toolbar buttons
	IBOutlet UIButton * settingButton;
	IBOutlet UIButton * filterButton;
    IBOutlet UIButton * fullScreenButton;
	
	UIView *panelView;
@private
	NMStyleUtility * styleUtility;
	NSUInteger numberOfChannels;
    NSFetchedResultsController *fetchedResultsController_;
    NSManagedObjectContext *managedObjectContext_;
	NSMutableArray *containerViewPool;
	VideoPlaybackViewController * videoViewController;
	NSInteger selectedIndex;
    NSInteger highlightedVideoIndex;
    NMChannel *highlightedChannel;
	NMPlaybackViewModeType displayMode;
}

@property (nonatomic, retain) IBOutlet UITableView * tableView;
@property (nonatomic, retain) IBOutlet UIView *panelView;
@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController * fetchedResultsController;
@property (nonatomic, assign) VideoPlaybackViewController * videoViewController;
@property (nonatomic, readonly) NSInteger selectedIndex;
@property (nonatomic, assign) NSInteger highlightedVideoIndex;
@property (nonatomic, assign) NMChannel *highlightedChannel;
@property (nonatomic, assign) NMPlaybackViewModeType displayMode;

- (void)didSelectNewVideoWithChannel:(NMChannel *)theChannel andVideoIndex:(NSInteger)newVideoIndex;

- (IBAction)showFeatureDebugView:(id)sender;

- (IBAction)toggleTableEditMode:(id)sender;
- (IBAction)debugRefreshChannel:(id)sender;
- (IBAction)showSettingsView:(id)sender;
- (IBAction)showChannelManagementView:(id)sender;

- (CGRect)currentVideoCellFrameInView:(UIView *)view;
-(void)customPanning:(UIPanGestureRecognizer *)sender;
-(NSInteger)highlightedChannelIndex;
- (void)postAnimationChangeForDisplayMode:(NMPlaybackViewModeType)aMode;

@end
