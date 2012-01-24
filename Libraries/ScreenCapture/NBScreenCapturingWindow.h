//
//  NBScreenCapturingWindow.h
//  ipad
//
//  Created by Chris Haugli on 1/23/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NBScreenCapturingWindowDelegate;

@interface NBScreenCapturingWindow : UIWindow

- (void)setDelegate:(id<NBScreenCapturingWindowDelegate>)delegate;

@end

@protocol NBScreenCapturingWindowDelegate <NSObject>
- (void)screenCapturingWindow:(NBScreenCapturingWindow *)window sendEvent:(UIEvent *)event;
@end

