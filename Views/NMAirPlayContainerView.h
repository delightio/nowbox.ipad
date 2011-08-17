//
//  NMAirPlayContainerView.h
//  ipad
//
//  Created by Bill So on 17/8/11.
//  Copyright (c) 2011 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NMControlsView;

@interface NMAirPlayContainerView : UIView {
	NMControlsView * controlsView;
}

@property (nonatomic, assign) NMControlsView * controlsView;

@end
