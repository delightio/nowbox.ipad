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
#import "NMDataController.h"

@protocol GridControllerDelegate;

@interface GridController : NSObject <GridScrollViewDelegate, NSFetchedResultsControllerDelegate> {

}

@property (nonatomic, retain) IBOutlet UIView *view;
@property (nonatomic, retain) IBOutlet GridScrollView *gridView;
@property (nonatomic, retain) NMChannel *currentChannel;
@property (nonatomic, retain) NMVideo *currentVideo;
@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, assign) id<GridControllerDelegate> delegate;

- (void)pushToChannel:(NMChannel *)channel;
- (void)pushToVideo:(NMVideo *)video;
- (void)pop;

@end

@protocol GridControllerDelegate <NSObject>
- (void)gridController:(GridController *)gridController didSelectChannel:(NMChannel *)channel;
- (void)gridController:(GridController *)gridController didSelectVideo:(NMVideo *)video;
@end
