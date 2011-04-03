//
//  SocialSignInViewController.h
//  Nowmov
//
//  Created by Bill So on 24/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FBConnect.h"

@class VideoPlaybackViewController;


@interface SocialSignInViewController : UIViewController {
	VideoPlaybackViewController * videoViewController;
}

@property (nonatomic, retain) VideoPlaybackViewController * videoViewController;

- (IBAction)connectFacebook:(id)sender;
- (IBAction)connectTwitter:(id)sender;

@end
