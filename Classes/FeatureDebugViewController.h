//
//  SearchDebugViewController.h
//  ipad
//
//  Created by Bill So on 18/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "NMLibrary.h"

@class VideoPlaybackViewController;

@interface FeatureDebugViewController : UIViewController <NSFetchedResultsControllerDelegate> {
	IBOutlet UITableView * tableView;
	NMChannel * targetChannel;
	NMChannel * selectedChannel;
	VideoPlaybackViewController * playbackViewController;
}

@property (nonatomic, retain) NMChannel * targetChannel;
@property (nonatomic, retain) NMChannel * selectedChannel;
@property (nonatomic, retain) VideoPlaybackViewController * playbackViewController;
@property (nonatomic, retain) NSFetchedResultsController * fetchedResultsController;

- (IBAction)submitSearch:(id)sender;
- (IBAction)submitSubscribeChannel:(id)sender;
- (IBAction)submitUnsubscribeChannel:(id)sender;
- (IBAction)getCurrentSubscription:(id)sender;
- (IBAction)fetchMoreVideoForCurrentChannel:(id)sender;
- (IBAction)debugPlaybackQueue:(id)sender;

@end
