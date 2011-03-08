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
	
	NMVideo * currentVideo;
	NMChannel * currentChannel;
	
	// fake controls
	UIImageView * infoPanelImageView;
	UIImageView * volumePanelImageView;
	UIImageView * shareVideoPanelImageView;
}

@property (nonatomic, retain) NMVideo * currentVideo;
@property (nonatomic, retain) NMChannel * currentChannel;

- (IBAction)showTweetView:(id)sender;
- (IBAction)showVolumeControlView:(id)sender;
- (IBAction)showShareActionView:(id)sender;
- (IBAction)backToChannelView:(id)sender;
- (IBAction)playStopVideo:(id)sender;
- (IBAction)setLikeVideo:(id)sender;
- (IBAction)skipCurrentVideo:(id)sender;

- (void)preparePlayer;

// progress indicator
- (void)setCurrentTime:(NSInteger)sec;
- (void)setTotalLength:(NSInteger)sec;

@end
