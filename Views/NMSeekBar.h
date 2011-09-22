//
//  NMSeekBar.h
//  SeekBarApp
//
//  Created by Bill So on 19/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 Seek bar supports:
 - Video time seek
 - Show buffering progress
 - Show playback progress
 */

@interface NMSeekBar : UIControl {
	CALayer * nubLayer;
	NSInteger currentTime;
	NSInteger bufferTime;
	NSInteger duration;
	CGFloat widthPerSec;
}

@property (nonatomic, retain) CALayer * nubLayer;
@property (nonatomic) NSInteger currentTime;
@property (nonatomic) NSInteger bufferTime;
@property (nonatomic) NSInteger duration;
@property (nonatomic, readonly) CGPoint nubPosition;

- (void)updateWidthPerPixel;

@end
