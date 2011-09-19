//
//  NMSeekBarLayoutLayer.m
//  SeekBarApp
//
//  Created by Bill So on 19/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMSeekBarLayoutLayer.h"

@implementation NMSeekBarLayoutLayer
@synthesize bufferLayer, progressLayer;
@synthesize barBackgroundLayer, nubLayer;
@synthesize originalWidth;

//- (id)init
//{
//    self = [super init];
//    if (self) {
//        // Initialization code here.
//    }
//    
//    return self;
//}

- (void)dealloc {
	[bufferLayer release];
	[progressLayer release];
	[barBackgroundLayer release];
	[nubLayer release];
	[super dealloc];
}

- (void)layoutSublayers {
	CGFloat newWidth = self.bounds.size.width;		// newWidth == width of the view in the new layout
	if ( newWidth == originalWidth ) {
		[super layoutSublayers];
		return;
	}
	
	CGRect theFrame = barBackgroundLayer.bounds;
	theFrame.size.width = newWidth;
	barBackgroundLayer.bounds = theFrame;
	
	// update length
	theFrame = bufferLayer.bounds;
	theFrame.size.width = theFrame.size.width * newWidth / originalWidth;
	bufferLayer.bounds = theFrame;
	
	theFrame = progressLayer.bounds;
	theFrame.size.width = theFrame.size.width * newWidth / originalWidth;
	progressLayer.bounds = theFrame;
	nubLayer.position = CGPointMake(theFrame.size.width + 0.5f, nubLayer.position.y);
	
	originalWidth = newWidth;
}

@end
