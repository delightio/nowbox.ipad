//
//  NBScreenCapture.m
//  ipad
//
//  Created by Chris Haugli on 1/18/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.Luce Restaurant - San Francisco, CA | OpenTable
//

#import "NBScreenCapture.h"
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "UIResponder+InterceptTouches.h"
#import </usr/include/objc/objc-class.h>

#define kScaleFactor 0.5f
#define kFrameRate 2.0f
#define kBitRate 500.0*1024.0

@interface NBScreenCapture(Private)
- (void) writeVideoFrameAtTime:(CMTime)time;
@end

@implementation NBScreenCapture

@synthesize currentScreen, frameRate, captureDelegate;

- (void) initialize {
    // Initialization code
    self.currentScreen = nil;
    self.frameRate = kFrameRate;     // frames per seconds
    _recording = false;
    videoWriter = nil;
    videoWriterInput = nil;
    avAdaptor = nil;
    startedAt = nil;
    bitmapData = NULL;
    pendingTouches = [[NSMutableArray alloc] init];
    
//    Swizzle([UIResponder class], @selector(touchesBegan:withEvent:), @selector(customTouchesBegan:withEvent:));
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen]) {
            object_setClass(window, [NBScreenCapturingWindow class]);
            [(NBScreenCapturingWindow *)window setDelegate:self];
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWillResignActive:) 
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDidBecomeActive:) 
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (id) init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void) cleanupWriter {
    [avAdaptor release];
    avAdaptor = nil;
    
    [videoWriterInput release];
    videoWriterInput = nil;
    
    [videoWriter release];
    videoWriter = nil;
    
    [startedAt release];
    startedAt = nil;
    
    if (bitmapData != NULL) {
        free(bitmapData);
        bitmapData = NULL;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self cleanupWriter];
    [pendingTouches release];
    
    [super dealloc];
}

- (NSString *)outputPath {
    return [NSString stringWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0], @"output.mp4"];
}

#pragma mark - Notifications

- (void)handleWillResignActive:(NSNotification *)notification
{
    NSLog(@"stop recording");
    [self stopRecording];
    UISaveVideoAtPathToSavedPhotosAlbum([self outputPath], nil, nil, nil);
}

- (void)handleDidBecomeActive:(NSNotification *)notification
{
    NSLog(@"start recording");
    [self startRecording];
}

#pragma mark -

- (UIImage*)screenshot 
{
    // Create a graphics context with the target size
    // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
    // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
    CGSize windowSize = [[UIScreen mainScreen] bounds].size;
    CGSize imageSize = CGSizeMake(windowSize.width * kScaleFactor, windowSize.height * kScaleFactor);

    if (NULL != UIGraphicsBeginImageContextWithOptions)
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    else
        UIGraphicsBeginImageContext(imageSize);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Iterate over every window from back to front
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) 
    {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen])
        {
            // -renderInContext: renders in the coordinate space of the layer,
            // so we must first apply the layer's geometry to the graphics context
            CGContextSaveGState(context);
            // Center the context around the window's anchor point
            CGContextTranslateCTM(context, [window center].x, [window center].y);
            // Apply the window's transform about the anchor point
            CGContextConcatCTM(context, [window transform]);
            
            // Offset by the portion of the bounds left of and above the anchor point
            CGContextTranslateCTM(context,
                                  -[window bounds].size.width * [[window layer] anchorPoint].x,
                                  -[window bounds].size.height * [[window layer] anchorPoint].y);
            
            CGContextConcatCTM(context, CGAffineTransformMakeScale(kScaleFactor, kScaleFactor));
            
            // Render the layer hierarchy to the current context
            [[window layer] renderInContext:context];
            
            // Draw touch points
            @synchronized(self) {
                NSMutableArray *objectsToRemove = [NSMutableArray array];
                for (NSMutableDictionary *touch in pendingTouches) {
                    CGPoint location = [[touch objectForKey:@"location"] CGPointValue];
                    NSInteger decayCount = [[touch objectForKey:@"decayCount"] integerValue];
                    NSTimeInterval timestamp = [[touch objectForKey:@"timestamp"] floatValue];
                    
                    [touch setObject:[NSNumber numberWithInteger:decayCount+1] forKey:@"decayCount"];
                    if (decayCount > 2) {
                        [objectsToRemove addObject:touch];
                    }
                    
                    CGContextSetRGBFillColor(context, 0, 0, 255, 1.0 - 0.3*decayCount - (timestamp - CACurrentMediaTime()));
                    CGFloat diameter = 50 - 20*decayCount;
                    CGContextFillEllipseInRect(context, CGRectMake(location.x - diameter / 2, location.y - diameter / 2, diameter, diameter));          
                }
                [pendingTouches removeObjectsInArray:objectsToRemove];
            }
            
            // Restore the context
            CGContextRestoreGState(context);
        }
    }
    
    // Retrieve the screenshot image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)takeScreenshot
{
    if (!processing) {
        [self performSelectorInBackground:@selector(takeScreenshotInCurrentThread) withObject:nil];
    } else {
        NSLog(@"Frame rate too high to keep up. Dropping frame.");
    }
}


//static int frameCount = 0;            //debugging

- (void)takeScreenshotInCurrentThread
{
    if (!_recording) return;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    processing = YES;
    
    NSLog(@"start screenshot");
    @synchronized(self) {
        self.currentScreen = [self screenshot];
    }
    NSLog(@"stop screenshot");
    
    /*    //debugging
     if (frameCount < 600) {
     NSString* filename = [NSString stringWithFormat:@"Documents/frame_%d.png", frameCount];
     NSString* pngPath = [NSHomeDirectory() stringByAppendingPathComponent:filename];
     [UIImagePNGRepresentation(self.currentScreen) writeToFile: pngPath atomically: YES];
     frameCount++;
     }*/
    
    if (_recording) {
        float millisElapsed = [[NSDate date] timeIntervalSinceDate:startedAt] * 1000.0;
        [self writeVideoFrameAtTime:CMTimeMake((int)millisElapsed, 1000)];
    }    
    
    [pool drain];
    
    processing = NO;
}
                                        
- (NSURL*) tempFileURL {
    NSString *outputPath = [self outputPath];
    NSURL* outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:outputPath]) {
        NSError* error;
        if ([fileManager removeItemAtPath:outputPath error:&error] == NO) {
            NSLog(@"Could not delete old recording file at path:  %@", outputPath);
        }
    }
    
    return [outputURL autorelease];
}

-(BOOL) setUpWriter {
    NSError* error = nil;
    videoWriter = [[AVAssetWriter alloc] initWithURL:[self tempFileURL] fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(videoWriter);
    
    //Configure video
    NSDictionary* videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithDouble:kBitRate], AVVideoAverageBitRateKey,
                                           nil ];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:[[UIScreen mainScreen] bounds].size.width * kScaleFactor], AVVideoWidthKey,
                                   [NSNumber numberWithInt:[[UIScreen mainScreen] bounds].size.height * kScaleFactor], AVVideoHeightKey,
                                   videoCompressionProps, AVVideoCompressionPropertiesKey,
                                   nil];
    
    videoWriterInput = [[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings] retain];
    
    NSParameterAssert(videoWriterInput);
    videoWriterInput.expectsMediaDataInRealTime = YES;
    NSDictionary* bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];                                      
    
    avAdaptor = [[AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:bufferAttributes] retain];
    
    //add input
    [videoWriter addInput:videoWriterInput];
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:CMTimeMake(0, 1000)];
    
    return YES;
}

- (void) completeRecordingSession {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    [videoWriterInput markAsFinished];
    
    // Wait for the video
    int status = videoWriter.status;
    while (status == AVAssetWriterStatusUnknown) {
        NSLog(@"Waiting...");
        [NSThread sleepForTimeInterval:0.5f];
        status = videoWriter.status;
    }
    
    @synchronized(self) {
        BOOL success = [videoWriter finishWriting];
        if (!success) {
            NSLog(@"finishWriting returned NO");
        }
        
        [self cleanupWriter];
        
        id delegateObj = self.captureDelegate;
        NSString *outputPath = [self outputPath];
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
        
        NSLog(@"Completed recording, file is stored at:  %@", outputURL);
        if ([delegateObj respondsToSelector:@selector(recordingFinished:)]) {
            [delegateObj performSelectorOnMainThread:@selector(recordingFinished:) withObject:(success ? outputURL : nil) waitUntilDone:YES];
        }
        
        [outputURL release];
    }
    
    [pool drain];
}

- (bool) startRecording {
    bool result = NO;
    @synchronized(self) {
        if (! _recording) {
            result = [self setUpWriter];
            startedAt = [[NSDate date] retain];
            _recording = true;
            
            screenshotTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f/kFrameRate target:self selector:@selector(takeScreenshot) userInfo:nil repeats:YES];
        }
    }
    
    return result;
}

- (void) stopRecording {
    @synchronized(self) {
        if (_recording) {
            _recording = false;
            [screenshotTimer invalidate]; screenshotTimer = nil;            
            [self completeRecordingSession];
        }
    }
}

-(void) writeVideoFrameAtTime:(CMTime)time {
    if (![videoWriterInput isReadyForMoreMediaData]) {
        NSLog(@"Not ready for video data");
    }
    else {
        @synchronized (self) {
            UIImage* newFrame = [self.currentScreen retain];
            CVPixelBufferRef pixelBuffer = NULL;
            CGImageRef cgImage = CGImageCreateCopy([newFrame CGImage]);
            CFDataRef image = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
            
            int status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, avAdaptor.pixelBufferPool, &pixelBuffer);
            if(status != 0){
                //could not get a buffer from the pool
                NSLog(@"Error creating pixel buffer:  status=%d", status);
            } else {
                // set image data into pixel buffer
                CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
                uint8_t* destPixels = CVPixelBufferGetBaseAddress(pixelBuffer);
                CFDataGetBytes(image, CFRangeMake(0, CFDataGetLength(image)), destPixels);  //XXX:  will work if the pixel buffer is contiguous and has the same bytesPerRow as the input data
                
                if(status == 0){
                    BOOL success = [avAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:time];
                    if (!success)
                        NSLog(@"Warning:  Unable to write buffer to video: %@", videoWriter.error);
                }
                
                CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
                CVPixelBufferRelease( pixelBuffer );
            }
            
            //clean up
            [newFrame release];
            CFRelease(image);
            CGImageRelease(cgImage);
        }
        
    }
    
}

#pragma mark - NBScreenCapturingWindowDelegate

- (void)screenCapturingWindow:(NBScreenCapturingWindow *)window sendEvent:(UIEvent *)event
{
    @synchronized(self) {
        for (UITouch *touch in [event allTouches]) {
            if (touch.timestamp > 0) {
                CGPoint location = [touch locationInView:touch.window];
                NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGPoint:location], @"location",
                                                   touch.window, @"window",
                                                   touch.view, @"view",
                                                   [NSNumber numberWithInteger:0], @"decayCount", 
                                                   [NSNumber numberWithFloat:touch.timestamp], @"timestamp",
                                                   nil];
                [pendingTouches addObject:dictionary];
            }
        }
    }
}

@end