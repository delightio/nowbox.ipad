//
//  VideoPlaybackViewController.h
//  Nowmov
//
//  Created by Bill So on 03/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "NMMovieView.h"
#import "NMControlsView.h"
#import "NMLibrary.h"
#import "VideoPlaybackModelController.h"

@class NMVideo;
@class NMChannel;
@class NMTaskQueueController;


@interface VideoPlaybackViewController : UIViewController <UIPopoverControllerDelegate, NSFetchedResultsControllerDelegate, UIScrollViewDelegate, NMVideoListUpdateDelegate, VideoPlaybackModelControllerDelegate> {
	IBOutlet UIScrollView * controlScrollView;
	IBOutlet UITextView * debugMessageView;
	IBOutlet UIScrollView * prototypeChannelScrollView;
	NMMovieView * movieView;
	
	NMControlsView * loadedControlView;
	
	UILabel * currentTimeLabel, * totalDurationLabel;
	BOOL isAspectFill;
	BOOL firstShowControlView;
	BOOL freshStart;
	BOOL rowCountHasChanged;
	NSIndexPath ** indexPathCache;
	
	CGFloat currentXOffset;
	NSUInteger numberOfVideos;
	CGPoint beginDraggingContentOffset;
	NMChannel * currentChannel;
	NMTaskQueueController * nowmovTaskController;
	VideoPlaybackModelController * playbackModelController;
	
	BOOL videoDurationInvalid;
	BOOL bufferEmpty;
	BOOL didPlayToEnd;
	
	@private
    NSManagedObjectContext *managedObjectContext_;
	UIView *prototypeChannelPanel;
	UIView *prototypeChannelContent;
}

@property (nonatomic, retain) NMChannel * currentChannel;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) IBOutlet UIView *prototypeChannelPanel;
@property (nonatomic, retain) IBOutlet UIView *prototypeChannelContent;
@property (nonatomic, assign) IBOutlet NMControlsView * loadedControlView;	// it's a proxy. it does not retain the view loaded.

//- (IBAction)showTweetView:(id)sender;
//- (IBAction)showVolumeControlView:(id)sender;
//- (IBAction)showShareActionView:(id)sender;
- (IBAction)backToChannelView:(id)sender;
- (IBAction)playStopVideo:(id)sender;
- (IBAction)vote:(id)sender;
- (IBAction)skipCurrentVideo:(id)sender;
- (IBAction)showSharePopover:(id)sender;
- (IBAction)togglePrototypeChannelPanel:(id)sender;

- (IBAction)refreshVideoList:(id)sender;

- (void)stopVideo;
- (void)preparePlayer;	// prepare an AVPlayerLayer for the first time
//- (void)requestAddVideoAtIndex:(NSUInteger)idx;
//- (void)getVideoInfoAtIndex:(NSUInteger)idx;

// playback view update
- (void)setCurrentTime:(NSInteger)sec;
//- (void)updateControlsForVideoAtIndex:(NSUInteger)idx;
- (void)setPlaybackCheckpoint;

@end
