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
	AVQueuePlayer * player;
	
	NMVideo * currentVideo;
	NMChannel * currentChannel;
}

@property (nonatomic, retain) NMVideo * currentVideo;
@property (nonatomic, retain) NMChannel * currentChannel;

- (IBAction)closeView:(id)sender;

- (void)preparePlayer;

@end
