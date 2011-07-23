//
//  VideoPlaybackViewController.h
//  Nowmov
//
//  Created by Bill So on 03/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "NMLibrary.h"
#import "NMMovieView.h"
#import "NMMovieDetailView.h"
#import "NMControlsView.h"
#import "VideoPlaybackModelController.h"
#import "NMAVQueuePlayer.h"
#import "NMAVPlayerItem.h"

@class NMVideo;
@class NMChannel;
@class NMTaskQueueController;
@class ChannelPanelController;


/*!
 Things begin with "setCurrentChannel". This is where the app initialize the data structure for playback.
 
 The viewDidLoad and class init methods are places where we create view objects for display purpose.
 */
@interface VideoPlaybackViewController : UIViewController <UIPopoverControllerDelegate, UIScrollViewDelegate, NMVideoListUpdateDelegate, VideoPlaybackModelControllerDelegate, NMAVQueuePlayerPlaybackDelegate> {
	IBOutlet UIScrollView * controlScrollView;
	//IBOutlet UITextView * debugMessageView;
	NMMovieView * movieView;
	
	NMMovieDetailView * loadedMovieDetailView;
	NSMutableArray * movieDetailViewArray;
	
	NMControlsView * loadedControlView;
	ChannelPanelController * channelController;
	
	UILabel * currentTimeLabel, * totalDurationLabel;
	BOOL isAspectFill;
	BOOL firstShowControlView;
	CGFloat movieXOffset;
	
	CGFloat currentXOffset;
	NSUInteger numberOfVideos;
	NMChannel * currentChannel;
	NMTaskQueueController * nowmovTaskController;
	VideoPlaybackModelController * playbackModelController;
	
	BOOL videoDurationInvalid;
	BOOL bufferEmpty;
	BOOL didPlayToEnd;
	id timeObserver;
	
	@private
    NSManagedObjectContext *managedObjectContext_;
	NSNotificationCenter * defaulNotificationCenter;
}

@property (nonatomic, retain) NMChannel * currentChannel;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) IBOutlet NMMovieDetailView * loadedMovieDetailView;
@property (nonatomic, retain) IBOutlet NMControlsView * loadedControlView;	// it's a proxy. it does not retain the view loaded.
@property (nonatomic, retain) IBOutlet ChannelPanelController * channelController;

//- (IBAction)showTweetView:(id)sender;
//- (IBAction)showVolumeControlView:(id)sender;
//- (IBAction)showShareActionView:(id)sender;
- (IBAction)playStopVideo:(id)sender;
- (IBAction)vote:(id)sender;
- (IBAction)skipCurrentVideo:(id)sender;
- (IBAction)showSharePopover:(id)sender;
- (IBAction)toggleChannelPanel:(id)sender;
- (IBAction)inspectViewStructure:(id)sender;

- (IBAction)refreshVideoList:(id)sender;

- (void)stopVideo;
//- (void)requestAddVideoAtIndex:(NSUInteger)idx;
//- (void)getVideoInfoAtIndex:(NSUInteger)idx;

// playback view update
- (void)setCurrentTime:(NSInteger)sec;
//- (void)updateControlsForVideoAtIndex:(NSUInteger)idx;
- (void)setPlaybackCheckpoint;

// interface for Channel List View
- (void)playVideo:(NMVideo *)aVideo;

@end
