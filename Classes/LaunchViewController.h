//
//  LaunchViewController.h
//  ipad
//
//  Created by Bill So on 6/13/11.
//  Copyright 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@class VideoPlaybackViewController;
@class ipadAppDelegate;

@interface LaunchViewController : UIViewController <UITextFieldDelegate> {
    IBOutlet UIButton * progressLabel;
	BOOL appFirstLaunch;
	ipadAppDelegate * applicationDelegate;
}

@property (nonatomic, assign) ipadAppDelegate * applicationDelegate;

- (void)checkUpdateChannels;

@end
