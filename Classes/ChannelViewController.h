//
//  ChannelViewController.h
//  Nowmov
//
//  Created by Bill So on 03/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//


#import "ChannelTableCellView.h"

@interface ChannelViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, ChannelTableCellDelegate> {
	IBOutlet UITableView * channelTableView;
    IBOutlet UIImageView *tableOverlayImageView;
    IBOutlet UIImageView *headerOverlayImageView;
@private
	NSUInteger numberOfChannels;
    NSFetchedResultsController *fetchedResultsController_;
    NSManagedObjectContext *managedObjectContext_;
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

- (IBAction)getChannels:(id)sender;
- (IBAction)showLoginView:(id)sender;

@end

