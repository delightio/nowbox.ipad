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
	IBOutlet UIView *scrollToTopArea;
    
	UIView *panelView;
    NSMutableSet *recycledVideoCells;

@private
	NMStyleUtility * styleUtility;
    NSFetchedResultsController *fetchedResultsController_;
    NSManagedObjectContext *managedObjectContext_;
	NSMutableArray *containerViewPool;
	VideoPlaybackViewController * videoViewController;
	NSInteger selectedIndex;
    NMChannel *highlightedChannel;
	NMPlaybackViewModeType displayMode;
    BOOL massUpdate;
    NSMutableSet *refreshingChannels;
}

@property (nonatomic, retain) IBOutlet UITableView * tableView;
@property (nonatomic, retain) IBOutlet UIView *panelView;
@property (nonatomic, retain) IBOutlet UIButton *refreshButton;
@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController * fetchedResultsController;
@property (nonatomic, assign) VideoPlaybackViewController * videoViewController;
@property (nonatomic, readonly) NSInteger selectedIndex;
@property (nonatomic, retain) NMVideo *highlightedVideo;
@property (nonatomic, assign) NMChannel *highlightedChannel;
@property (nonatomic, assign) NMPlaybackViewModeType displayMode;
@property (nonatomic, retain) NSMutableSet *recycledVideoCells;

- (void)didSelectNewVideo:(NMVideo *)theVideo withChannel:(NMChannel *)theChannel;

- (IBAction)showFeatureDebugView:(id)sender;

- (IBAction)toggleTableEditMode:(id)sender;
- (IBAction)refreshChannels:(id)sender;
- (IBAction)showSettingsView:(id)sender;
- (IBAction)showChannelManagementView:(id)sender;

-(void)customPanning:(UIPanGestureRecognizer *)sender;
-(NSInteger)highlightedChannelIndex;
- (void)postAnimationChangeForDisplayMode:(NMPlaybackViewModeType)aMode;

@end
