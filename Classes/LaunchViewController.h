//
//  LaunchViewController.h
//  ipad
//
//  Created by Bill So on 6/13/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@class VideoPlaybackViewController;

@interface LaunchViewController : UIViewController {
    IBOutlet UILabel * debugLabel;
}

- (IBAction)showPlaybackController:(id)sender;

- (void)showVideoView;
- (void)checkUpdateChannels;

@end
