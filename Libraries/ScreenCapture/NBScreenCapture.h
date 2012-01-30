//
//  NBScreenCapture.h
//  ipad
//
//  Created by Chris Haugli on 1/18/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "NBScreenCapturingWindow.h"

/**
 * Delegate protocol.  Implement this if you want to receive a notification when the
 * view completes a recording.
 *
 * When a recording is completed, the NBScreenCapture will notify the delegate, passing
 * it the path to the created recording file if the recording was successful, or a value
 * of nil if the recording failed/could not be saved.
 */
@protocol ScreenCaptureViewDelegate <NSObject>
- (void) recordingFinished:(NSString*)outputPathOrNil;
@end

/**
 * NBScreenCapture, a UIView subclass that periodically samples its current display
 * and stores it as a UIImage available through the 'currentScreen' property.  The
 * sample/update rate can be configured (within reason) by setting the 'frameRate'
 * property.
 *
 * This class can also be used to record real-time video of its subviews, using the
 * 'startRecording' and 'stopRecording' methods.  A new recording will overwrite any
 * previously made recording file, so if you want to create multiple recordings per
 * session (or across multiple sessions) then it is your responsibility to copy/back-up
 * the recording output file after each session.
 *
 * To use this class, you must link against the following frameworks:
 *
 *  - AssetsLibrary
 *  - AVFoundation
 *  - CoreGraphics
 *  - CoreMedia
 *  - CoreVideo
 *  - QuartzCore
 *
 */

@interface NBScreenCapture : NSObject <NBScreenCapturingWindowDelegate> {
    //video writing
    AVAssetWriter *videoWriter;
    AVAssetWriterInput *videoWriterInput;
    AVAssetWriterInputPixelBufferAdaptor *avAdaptor;
    
    //recording state
    BOOL _recording;
    BOOL _paused;
    NSDate *startedAt;
    NSTimeInterval pauseStartedAt;
    NSTimeInterval pauseTime;
    void *bitmapData;
    BOOL processing;
    NSInteger frameCount;
    NSTimeInterval elapsedTime;
    
    NSTimer *screenshotTimer;
    NSMutableArray *pendingTouches;    
}

+ (void)start;
+ (void)stop;
+ (void)pause;
+ (void)resume;
+ (void)registerPrivateView:(UIView *)view;
+ (void)unregisterPrivateView:(UIView *)view;
+ (void)setHidesKeyboard:(BOOL)hidesKeyboard;
+ (void)openGLScreenCapture:(UIView *)view colorRenderBuffer:(GLuint)colorRenderBuffer;

@property(nonatomic, retain) UIImage *currentScreen;
@property(nonatomic, retain) NSMutableSet *privateViews;
@property(nonatomic, assign) BOOL hidesKeyboard;
@property(retain) UIImage *openGLImage;
@property(nonatomic, assign) CGRect openGLFrame;
@property(nonatomic, assign) float frameRate;
@property(nonatomic, assign) id<ScreenCaptureViewDelegate> captureDelegate;

@end