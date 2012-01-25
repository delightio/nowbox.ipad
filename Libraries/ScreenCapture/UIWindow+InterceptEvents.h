//
//  UIWindow+InterceptEvents.h
//  ipad
//
//  Created by Chris Haugli on 1/24/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NBScreenCapturingWindow.h"

@interface UIWindow (InterceptEvents)

- (void)NBsetDelegate:(id<NBScreenCapturingWindowDelegate>)delegate;
- (void)NBsendEvent:(UIEvent *)event;

@end
