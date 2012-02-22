//
//  NMSeekBar.m
//  SeekBarApp
//
//  Created by Bill So on 19/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NMSeekBar.h"
#import "NMSeekBarLayoutLayer.h"

@implementation NMSeekBar
@synthesize nubLayer, nubPosition;
@synthesize currentTime, bufferTime, duration;

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	
	NMSeekBarLayoutLayer * selfLayer = (NMSeekBarLayoutLayer *)self.layer;
	selfLayer.parentBar = self;
	selfLayer.sublayerTransform = CATransform3DMakeTranslation(0.0f, 7.5f, 0.0f);
	CGFloat myWidth = self.bounds.size.width;
	selfLayer.originalWidth = myWidth;
    
	// background layer
    UIImage *backgroundImage = [UIImage imageNamed:@"playback-progress-background"];
	CALayer * theLayer = [CALayer layer];
	theLayer.contents = (id)backgroundImage.CGImage;
	theLayer.anchorPoint = CGPointMake(0.0, 0.5f);
    if (NM_RUNNING_ON_IPAD) {
        theLayer.frame = CGRectMake(1.0f, 1.0f, myWidth, backgroundImage.size.height);
    } else {
        theLayer.frame = CGRectMake(1.0f, 0.0f, myWidth, backgroundImage.size.height);
        theLayer.masksToBounds = YES;
        theLayer.cornerRadius = 5.0f;
    }
	[selfLayer addSublayer:theLayer];
	selfLayer.barBackgroundLayer = theLayer;
	
	// buffer layer
    UIImage *bufferImage = [UIImage imageNamed:@"progress-gray-side"];
	theLayer = [CALayer layer];
	theLayer.contents = (id)bufferImage.CGImage;
	theLayer.anchorPoint = CGPointMake(0.0, 0.5f);
    if (NM_RUNNING_ON_IPAD) {
        theLayer.frame = CGRectMake(1.0f, 1.0f, 0.0f, bufferImage.size.height);
    } else {
        theLayer.frame = CGRectMake(1.0f, 0.0f, 0.0f, bufferImage.size.height);
        theLayer.masksToBounds = YES;
        theLayer.cornerRadius = 5.0f;
    }
	[selfLayer addSublayer:theLayer];
	selfLayer.bufferLayer = theLayer;
	
	// progress layer
    UIImage *brightImage = [UIImage imageNamed:@"progress-bright-side"];
	theLayer = [CALayer layer];
	theLayer.contents = (id)brightImage.CGImage;
	theLayer.anchorPoint = CGPointMake(0.0, 0.5f);
    if (NM_RUNNING_ON_IPAD) {
        theLayer.frame = CGRectMake(1.0f, 1.0f, 0.0f, brightImage.size.height);
    } else {
        theLayer.frame = CGRectMake(1.0f, 0.0f, 0.0f, brightImage.size.height);
        theLayer.masksToBounds = YES;
        theLayer.cornerRadius = 5.0f;
    }
	[selfLayer addSublayer:theLayer];
	selfLayer.progressLayer = theLayer;
    
	// nub
    UIImage *nubImage = [UIImage imageNamed:@"progress-nub"];
	theLayer = [CALayer layer];
	theLayer.contents = (id)nubImage.CGImage;
    theLayer.bounds = CGRectMake(0.5f, 0.0f, nubImage.size.width, nubImage.size.height);
    theLayer.position = CGPointMake(0.5f, 4.5f);    
	[selfLayer addSublayer:theLayer];
	selfLayer.nubLayer = theLayer;
	self.nubLayer = theLayer;
	
	return self;
}

- (void)dealloc {
	[nubLayer release];
	[super dealloc];
}

//- (id)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code
//    }
//    return self;
//}

+ (Class)layerClass {
	return [NMSeekBarLayoutLayer class];
}

- (void)updateWidthPerPixel {
	if ( duration ) {
		widthPerSec = (self.bounds.size.width - 2.0f) / (CGFloat)(duration - 1);
	}
}

#pragma mark Time attributes
- (void)setCurrentTime:(NSInteger)cTime {
	currentTime = cTime;
	// set the width
	NMSeekBarLayoutLayer * theLayer = (NMSeekBarLayoutLayer *)self.layer;
	CGRect theRect = theLayer.progressLayer.bounds;
	theRect.size.width = roundf(widthPerSec * ((CGFloat)cTime));
	if ( theRect.size.width > self.bounds.size.width ) {
		theRect.size.width = self.bounds.size.width - 2.0f;
	}
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	theLayer.progressLayer.bounds = theRect;
	nubLayer.position = CGPointMake(theRect.size.width + 0.5f, (NM_RUNNING_ON_IPAD ? 3.5f : 4.0f));
	[CATransaction commit];
}

- (void)setBufferTime:(NSInteger)bTime {
	bufferTime = bTime;
	// set the width
	NMSeekBarLayoutLayer * theLayer = (NMSeekBarLayoutLayer *)self.layer;
	CGRect theRect = theLayer.bufferLayer.bounds;
	theRect.size.width = roundf(widthPerSec * ((CGFloat)bTime));
	if ( theRect.size.width > self.bounds.size.width ) {
		theRect.size.width = self.bounds.size.width - 2.0f;
	}
    if (!NM_RUNNING_ON_IPAD) {
        // We don't reach the end otherwise
        theRect.size.width += 2;
    }
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	theLayer.bufferLayer.bounds = theRect;
	[CATransaction commit];
}

- (void)setDuration:(NSInteger)d {
	duration = d;
	if ( d ) widthPerSec = (self.bounds.size.width - 2.0f) / (CGFloat)(d - 1);	// less the duration by 1 to offset YouTube video inaccuracy
	else widthPerSec = 0.0f;
	// reset size of other bar
	NMSeekBarLayoutLayer * theLayer = (NMSeekBarLayoutLayer *)self.layer;
	CGRect theRect = theLayer.progressLayer.bounds;
	theRect.size.width = 0.0f;
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	theLayer.progressLayer.bounds = theRect;
	theLayer.bufferLayer.bounds = theRect;
	nubLayer.position = CGPointMake(0.5f, (NM_RUNNING_ON_IPAD ? 3.5f : 4.0f));
	[CATransaction commit];
}

- (CGPoint)nubPosition {
	return nubLayer.position;
}

- (BOOL)pointInsideNub:(CGPoint)point {
    // Since nub is small, accept a touch area bigger than the nub
    CGRect largerNub = CGRectMake(nubLayer.frame.origin.x - nubLayer.frame.size.width * 2,
                                  nubLayer.frame.origin.y - nubLayer.frame.size.height * 2,
                                  nubLayer.frame.size.width * 5,
                                  nubLayer.frame.size.height * 5);
    
    if (CGRectContainsPoint(largerNub, point)) {
        return YES;
    }
    return NO;
}

#pragma mark UIControl
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint thePoint = [touch locationInView:self];
    return [self pointInsideNub:thePoint];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if ( !self.tracking ) return;
	UITouch * aTouch = [touches anyObject];
	CGPoint thePoint = [aTouch locationInView:self];
//	if ( thePoint.x > self.bounds.size.width || thePoint.x < 0.0f ) return;
    if (thePoint.x > self.bounds.size.width) thePoint.x = self.bounds.size.width;
    if (thePoint.x < 0.0f) thePoint.x = 0.0f;
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	nubLayer.position = CGPointMake(thePoint.x + 0.5f, (NM_RUNNING_ON_IPAD ? 3.5f : 4.0f));
	[CATransaction commit];
	currentTime = (NSInteger)(thePoint.x / widthPerSec);
	[self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    // Accept a region slightly outside this view to give us a larger hit area for the nub
    if (point.x > -20 && point.y > -20 && point.x < self.bounds.size.width + 20 && point.y < self.bounds.size.height + 20) {
        return YES;
    }
    
    return [super pointInside:point withEvent:event];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
