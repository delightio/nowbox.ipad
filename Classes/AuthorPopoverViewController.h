//
//  AuthorPopoverViewController.h
//  ipad
//
//  Created by Chris Haugli on 10/25/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMVideo.h"

@interface AuthorPopoverViewController : UIViewController {
    BOOL subscribed;
}

@property (nonatomic, retain) UIButton *subscribeButton;
@property (nonatomic, retain) UIButton *watchNowButton;
@property (nonatomic, retain) NMVideo *video;

- (id)initWithVideo:(NMVideo *)video;

@end
