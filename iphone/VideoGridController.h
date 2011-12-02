//
//  VideoGridController.h
//  ipad
//
//  Created by Chris Haugli on 12/1/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import "GridController.h"

@interface VideoGridController : GridController <UIActionSheetDelegate> {
    BOOL isLoadingNewVideos;
}

@property (nonatomic, retain) NMChannel *currentChannel;
@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

- (IBAction)itemPressed:(id)sender;

@end
