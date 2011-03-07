//
//  VideoPlaybackViewController.h
//  Nowmov
//
//  Created by Bill So on 03/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

@class NMVideo;
@class NMChannel;

@interface VideoPlaybackViewController : UIViewController {
	NMVideo * currentVideo;
	NMChannel * currentChannel;
}

@property (nonatomic, retain) NMVideo * currentVideo;
@property (nonatomic, retain) NMChannel * currentChannel;

- (IBAction)closeView:(id)sender;

@end
