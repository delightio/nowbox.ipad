//
//  NMSeekBarLayoutLayer.h
//  SeekBarApp
//
//  Created by Bill So on 19/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@class NMSeekBar;

@interface NMSeekBarLayoutLayer : CALayer {
	CALayer * bufferLayer, * progressLayer, * barBackgroundLayer, * nubLayer;
	CGFloat originalWidth;
	NMSeekBar * parentBar;
}

@property (nonatomic) CGFloat originalWidth;
@property (nonatomic, retain) CALayer * bufferLayer;
@property (nonatomic, retain) CALayer * progressLayer;
@property (nonatomic, retain) CALayer * barBackgroundLayer;
@property (nonatomic, retain) CALayer * nubLayer;
@property (nonatomic, assign) NMSeekBar * parentBar;

@end
