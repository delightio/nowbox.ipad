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

@class NMVideo;
@class NMChannel;

@interface VideoPlaybackViewController : UIViewController <UIPopoverControllerDelegate> {
	IBOutlet NMMovieView * movieView;
	IBOutlet NMControlsView * controlsContainerView;
	IBOutlet UILabel * channelNameLabel;
	IBOutlet UILabel * postedByLabel;
	IBOutlet UILabel * postSourceLabel;
	IBOutlet UILabel * videoTitleLabel;
	
	UIImageView * progressView;
	UILabel * currentTimeLabel, * totalDurationLabel;
	AVPlayerLayer * currentPlayerLayer;
	BOOL isAspectFill;
	BOOL firstShowControlView;
	
	AVQueuePlayer * player;
	
	NSUInteger currentIndex;
	NSArray * sortedVideoList;
	NMChannel * currentChannel;
	
	// fake controls
	UIImageView * infoPanelImageView;
	UIImageView * volumePanelImageView;
	UIImageView * shareVideoPanelImageView;
	BOOL videoDurationInvalid;
	
	@private
    NSManagedObjectContext *managedObjectContext_;
    NSFetchedResultsController *fetchedResultsController_;
}

@property (nonatomic, retain) NSArray * sortedVideoList;
@property (nonatomic, retain) NMChannel * currentChannel;
@property (nonatomic, readonly) NMVideo * currentVideo;
@property (nonatomic, retain) AVPlayerLayer * currentPlayerLayer;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

- (IBAction)showTweetView:(id)sender;
- (IBAction)showVolumeControlView:(id)sender;
- (IBAction)showShareActionView:(id)sender;
- (IBAction)backToChannelView:(id)sender;
- (IBAction)playStopVideo:(id)sender;
- (IBAction)setLikeVideo:(id)sender;
- (IBAction)skipCurrentVideo:(id)sender;
- (IBAction)showSharePopover:(id)sender;

- (void)stopVideo;
- (void)preparePlayer;
- (void)requestAddVideoAtIndex:(NSUInteger)idx;
//- (void)getVideoInfoAtIndex:(NSUInteger)idx;

// playback view update
- (void)setCurrentTime:(NSInteger)sec;
- (void)updateControlsForVideoAtIndex:(NSUInteger)idx;

@end
