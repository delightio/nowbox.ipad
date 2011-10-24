//
//  TouchForwardingView.h
//  ipad
//
//  Created by Chris Haugli on 10/20/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TouchForwardingView : UIView {
    id target;
    SEL action;
}

- (void)addTarget:(id)target action:(SEL)action;

@end
