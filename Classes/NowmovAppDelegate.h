//
//  NowmovAppDelegate.h
//  Nowmov
//
//  Created by Bill So on 03/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ChannelViewController;

@interface NowmovAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    ChannelViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet ChannelViewController *viewController;

@end

