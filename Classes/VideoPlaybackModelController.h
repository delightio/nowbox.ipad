//
//  VideoPlaybackModelController.h
//  ipad
//
//  Created by Bill So on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMLibrary.h"


@class NMVideo;
@class NMChannel;
@class VideoPlaybackModelController;

@protocol VideoPlaybackModelControllerDelegate <NSObject>

- (void)controller:(VideoPlaybackModelController *)ctrl shouldBeginPlayingVideo:(NMVideo *)vid;
- (void)controller:(VideoPlaybackModelController *)ctrl didResolvedURLOfVideo:(NMVideo *)vid;
- (void)controller:(VideoPlaybackModelController *)ctrl didUpdateVideoListWithTotalNumberOfVideo:(NSUInteger)totalNum;
- (void)didLoadNextVideoManagedObjectForController:(VideoPlaybackModelController *)ctrl;
- (void)didLoadPreviousVideoManagedObjectForController:(VideoPlaybackModelController *)ctrl;
- (void)didLoadCurrentVideoManagedObjectForController:(VideoPlaybackModelController *)ctrl;

@end


/*!
 Implement an abstracted list of video operated through exposed list methods and properties.
 Insert behaviour when refreshing the list of videos in the channel is not that clear for now. Need to check how to refresh all variables for caching - currentVideo, nextVideo, currentIndex...
 */

@interface VideoPlaybackModelController : NSObject <NSFetchedResultsControllerDelegate> {
	// core data operation
    NSIndexPath * currentIndexPath;
	NSIndexPath * nextIndexPath, * nextNextIndexPath;
	NSIndexPath * previousIndexPath;
	NMVideo * currentVideo, * nextVideo, * nextNextVideo, * previousVideo;
	BOOL rowCountHasChanged;
	BOOL changeSessionUpdateCount;
	NSUInteger numberOfVideos;
	
	NMChannel * channel;
	id <VideoPlaybackModelControllerDelegate> dataDelegate;
	
	// debug text view
	UITextView * debugMessageView;
	
	// task related
	NMTaskQueueController * nowmovTaskController;
	
	@private
	NSManagedObjectContext * managedObjectContext;
	NSFetchedResultsController * fetchedResultsController_;
}

@property (nonatomic, retain) NSIndexPath * currentIndexPath;
@property (nonatomic, retain) NSIndexPath * nextIndexPath;
@property (nonatomic, retain) NSIndexPath * nextNextIndexPath;
@property (nonatomic, retain) NSIndexPath * previousIndexPath;
@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController * fetchedResultsController;

@property (nonatomic, retain) NMVideo * currentVideo;
@property (nonatomic, retain) NMVideo * nextVideo;
@property (nonatomic, retain) NMVideo * nextNextVideo;
@property (nonatomic, retain) NMVideo * previousVideo;
@property (nonatomic, readonly) NMVideo * firstVideo;

@property (nonatomic, retain) NMChannel * channel;
@property (nonatomic, assign) id<VideoPlaybackModelControllerDelegate> dataDelegate;

@property (nonatomic, retain) UITextView * debugMessageView;

+ (VideoPlaybackModelController *)sharedVideoPlaybackModelController;
/*!
 The next video will become the "currentVideo".
 Returns YES if move is successful. No if the currentVideo is currently the last video
 */
- (BOOL)moveToNextVideo;

/*!
 The previous video will become the "currentVideo".
 Returns YES if move is successful. No if the currentVideo is the first video;
 */
- (BOOL)moveToPreviousVideo;

@end
