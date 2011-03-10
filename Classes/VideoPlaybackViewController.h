//
//  VideoPlaybackViewController.h
//  Nowmov
//
//  Created by Bill So on 03/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@class NMVideo;
@class NMChannel;

@interface VideoPlaybackViewController : UIViewController {
	IBOutlet UIView * movieView;
	IBOutlet UIView * controlsContainerView;
	IBOutlet UILabel * channelNameLabel;
	IBOutlet UILabel * postedByLabel;
	IBOutlet UILabel * postSourceLabel;
	IBOutlet UILabel * videoTitleLabel;
	
	UIImageView * progressView;
	UILabel * currentTimeLabel, * totalDurationLabel;
	
	AVQueuePlayer * player;
	
	NSUInteger currentIndex;
	NSArray * sortedVideoList;
	NMChannel * currentChannel;
	
	// fake controls
	UIImageView * infoPanelImageView;
	UIImageView * volumePanelImageView;
	UIImageView * shareVideoPanelImageView;
}

@property (nonatomic, retain) NSArray * sortedVideoList;
@property (nonatomic, retain) NMChannel * currentChannel;

- (IBAction)showTweetView:(id)sender;
- (IBAction)showVolumeControlView:(id)sender;
- (IBAction)showShareActionView:(id)sender;
- (IBAction)backToChannelView:(id)sender;
- (IBAction)playStopVideo:(id)sender;
- (IBAction)setLikeVideo:(id)sender;
- (IBAction)skipCurrentVideo:(id)sender;

- (void)preparePlayer;
- (void)requestAddVideoAtIndex:(NSUInteger)idx;
- (void)getVideoInfoAtIndex:(NSUInteger)idx;

// playback view update
- (void)setCurrentTime:(NSInteger)sec;
- (void)setTotalLength:(NSInteger)sec;
- (void)updateControlsForVideoAtIndex:(NSUInteger)idx;

@end
