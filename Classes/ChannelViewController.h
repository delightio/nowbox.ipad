//
//  ChannelViewController.h
//  Nowmov
//
//  Created by Bill So on 03/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//


#import "ChannelTableCellView.h"

@class VideoPlaybackViewController;

@interface ChannelViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, ChannelTableCellDelegate, UIPopoverControllerDelegate> {
	IBOutlet UITableView * channelTableView;
    IBOutlet UIImageView *tableOverlayImageView;
    IBOutlet UIImageView *headerOverlayImageView;
	VideoPlaybackViewController * videoViewController;
	
@private
	NSUInteger numberOfChannels;
    NSFetchedResultsController *fetchedResultsController_;
    NSManagedObjectContext *managedObjectContext_;
}

@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController * fetchedResultsController;
@property (nonatomic, retain) VideoPlaybackViewController * videoViewController;

- (IBAction)getChannels:(id)sender;
- (IBAction)showLoginView:(id)sender;
- (IBAction)getFacebookProfile:(id)sender;

@end

