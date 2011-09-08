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
    NSInteger highlightedChannelIndex, highlightedVideoIndex;
}

@property (nonatomic, retain) IBOutlet UITableView * tableView;
@property (nonatomic, retain) IBOutlet UIView *panelView;
@property (nonatomic, retain) IBOutlet UIButton * fullScreenButton;
@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController * fetchedResultsController;
@property (nonatomic, assign) VideoPlaybackViewController * videoViewController;
@property (nonatomic, readonly) NSInteger selectedIndex;
@property (nonatomic, assign) NSInteger highlightedVideoIndex;
@property (nonatomic, assign) NSInteger highlightedChannelIndex;

- (void)panelWillAppear;
- (void)panelWillDisappear;
- (void)panelWillBecomeFullScreen;
- (void)panelWillEnterHalfScreen:(NMPlaybackViewModeType)fromViewMode;

- (void)didSelectNewVideoWithChannelIndex:(NSInteger)newChannelIndex andVideoIndex:(NSInteger)newVideoIndex;

- (IBAction)showFeatureDebugView:(id)sender;

- (IBAction)toggleTableEditMode:(id)sender;
- (IBAction)debugRefreshChannel:(id)sender;
- (IBAction)showSettingsView:(id)sender;
- (IBAction)showChannelManagementView:(id)sender;

-(void)customPanning:(UIPanGestureRecognizer *)sender;

@end
