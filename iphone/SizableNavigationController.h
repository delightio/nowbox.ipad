//
//  SizableNavigationController.h
//  ipad
//
//  Created by Chris Haugli on 11/30/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoPlaybackModelController.h"

@class PhoneVideoPlaybackViewController;

@interface SizableNavigationController : NSObject {
    NSMutableArray *_viewControllers;
}

@property (nonatomic, retain) UIView *view;
@property (nonatomic, readonly, retain) UIViewController *visibleViewController;
@property (nonatomic, readonly, retain) NSArray *viewControllers;
@property (nonatomic, assign) VideoPlaybackModelController *playbackModelController;
@property (nonatomic, assign) PhoneVideoPlaybackViewController *playbackViewController;

- (id)initWithRootViewController:(UIViewController *)viewController;
- (void)pushViewController:(UIViewController *)viewController;
- (void)popViewController;
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration;

@end
