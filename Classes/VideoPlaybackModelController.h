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

/*!
 When changes happen in Core Data, the FRC delegate method in VideoPlaybackModelControllerDelegate is called. To invoke related interface change in the delegate object, this method is called.
 */
- (void)controller:(VideoPlaybackModelController *)ctrl didUpdateVideoListWithTotalNumberOfVideo:(NSUInteger)totalNum;
/*!
 
 */
- (void)didLoadNextNextVideoManagedObjectForController:(VideoPlaybackModelController *)ctrl;
- (void)didLoadNextVideoManagedObjectForController:(VideoPlaybackModelController *)ctrl;
- (void)didLoadPreviousVideoManagedObjectForController:(VideoPlaybackModelController *)ctrl;
- (void)didLoadCurrentVideoManagedObjectForController:(VideoPlaybackModelController *)ctrl;

// video refresh - happened when CDN link expire
- (void)shouldRevertNextNextVideoToNewStateForController:(VideoPlaybackModelController *)ctrl;
- (void)shouldRevertNextVideoToNewStateForController:(VideoPlaybackModelController *)ctrl;
- (void)shouldRevertCurrentVideoToNewStateForController:(VideoPlaybackModelController *)ctrl;

@end


/*!
 Implement an abstracted list of video operated through exposed list methods and properties.
 Insert behaviour when refreshing the list of videos in the channel is not that clear for now. Need to check how to refresh all variables for caching - currentVideo, nextVideo, currentIndex...
 */

@interface VideoPlaybackModelController : NSObject <NSFetchedResultsControllerDelegate> {
	// core data operation
    NSIndexPath * currentIndexPath, * previousIndexPath;
	NSIndexPath * nextIndexPath, * nextNextIndexPath;
	NMVideo * currentVideo, * nextVideo, * nextNextVideo, * previousVideo;
	NSInteger videoEncounteredBitArray;
	BOOL deletedOlderVideos;
	BOOL rowCountHasChanged;
	BOOL changeSessionUpdateCount;
	NSUInteger changeSessionVideoCount;
	NSUInteger numberOfVideos;
	
	NMChannel * channel;
	id <VideoPlaybackModelControllerDelegate> dataDelegate;
	
	// debug text view
	UITextView * debugMessageView;
	
	// task related
	NMTaskQueueController * nowboxTaskController;
	
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
@property (nonatomic, readonly) NSUInteger numberOfVideos;
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

/*!
 Return list of videos that should be buffered in the queue player. The queue video player should enqueue the videos in the order specified in the returned array.
 */
- (NSArray *)videosForBuffering;
/*!
 Check if the direct URL to videos has expired or not. If so, refresh them.
 */
- (BOOL)refreshDirectURLToBufferedVideos;

/*!
 Set the video for playback.
 */
- (void)setVideo:(NMVideo *)aVideo;

// index path management
//- (void)updateIndexPathsForChangeType:(NSFetchedResultsChangeType)type;

@end
