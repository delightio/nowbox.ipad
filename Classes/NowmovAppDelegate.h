//
//  NowmovAppDelegate.h
//  Nowmov
//
//  Created by Bill So on 03/03/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NowmovViewController;

@interface NowmovAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    NowmovViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet NowmovViewController *viewController;

@end

