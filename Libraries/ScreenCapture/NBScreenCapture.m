//
//  NBScreenCapture.m
//  ipad
//
//  Created by Chris Haugli on 1/18/12.
//  Copyright (c) 2012 Pipely Inc. All rights reserved.Luce Restaurant - San Francisco, CA | OpenTable
//

#import "NBScreenCapture.h"
#import "UIWindow+InterceptEvents.h"
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import </usr/include/objc/objc-class.h>

#define kScaleFactor 0.5f
#define kFrameRate 1.0f
#define kBitRate 500.0*1024.0

@interface NBScreenCapture(Private)
- (void) writeVideoFrameAtTime:(CMTime)time;
@end

@implementation NBScreenCapture

@synthesize currentScreen, frameRate, captureDelegate;

void Swizzle(Class c, SEL orig, SEL new){
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, new);
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
        class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    else
        method_exchangeImplementations(origMethod, newMethod);
}

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

    // ISA swizzling
//    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
//        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen]) {
//            object_setClass(window, [NBScreenCapturingWindow class]);
//            [(NBScreenCapturingWindow *)window setDelegate:self];
//        }
//    }

    // Method swizzling
    Swizzle([UIWindow class], @selector(sendEvent:), @selector(NBsendEvent:));
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
        [window NBsetDelegate:self];
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

- (CGContextRef) createBitmapContextOfSize:(CGSize) size {
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
    
    bitmapBytesPerRow   = (size.width * 4);
    bitmapByteCount     = (bitmapBytesPerRow * size.height);
    colorSpace = CGColorSpaceCreateDeviceRGB();
    if (bitmapData != NULL) {
        free(bitmapData);
    }
    bitmapData = malloc( bitmapByteCount );
    if (bitmapData == NULL) {
        fprintf (stderr, "Memory not allocated!");
        return NULL;
    }
    
    context = CGBitmapContextCreate (bitmapData,
                                     size.width,
                                     size.height,
                                     8,      // bits per component
                                     bitmapBytesPerRow,
                                     colorSpace,
                                     kCGImageAlphaNoneSkipFirst);
    
    CGContextSetAllowsAntialiasing(context,NO);
    if (context== NULL) {
        free (bitmapData);
        fprintf (stderr, "Context not created!");
        return NULL;
    }
    CGColorSpaceRelease( colorSpace );
    
    return context;
}

- (UIImage*)screenshot 
{
    CGSize windowSize = [[UIScreen mainScreen] bounds].size;
    CGSize imageSize = CGSizeMake(windowSize.width * kScaleFactor, windowSize.height * kScaleFactor);
    CGContextRef context = [self createBitmapContextOfSize:imageSize];
        
    // Iterate over every window from back to front
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen]) {
/*            CGAffineTransform flipVertical = CGAffineTransformMake(kScaleFactor, 0, 0, -kScaleFactor, 0, imageSize.height);
            CGContextConcatCTM(context, flipVertical);
            [[window layer] renderInContext:context];*/
                        
            // Center the context around the window's anchor point
            CGContextTranslateCTM(context, [window center].x, [window center].y);
            // Apply the window's transform about the anchor point
            CGContextConcatCTM(context, [window transform]);
            // Offset by the portion of the bounds left of and above the anchor point
            CGContextTranslateCTM(context,
                                  -[window bounds].size.width * [[window layer] anchorPoint].x,
                                  -[window bounds].size.height * [[window layer] anchorPoint].y);

            CGContextConcatCTM(context, CGAffineTransformMake(-kScaleFactor, 0, 0, kScaleFactor, imageSize.width, 0));
            
            // Render the layer hierarchy to the current context
            [[window layer] renderInContext:context];
            
            // Draw touch points
            NSMutableArray *objectsToRemove = [NSMutableArray array];
            CGContextSetRGBStrokeColor(context, 0, 0, 255, 0.7);
            CGContextSetLineWidth(context, 5.0);
            CGContextSetLineJoin(context, kCGLineJoinRound);
            CGContextSetAllowsAntialiasing(context, YES);
            CGPoint lastLocations[8];
            CGPoint startLocation;
            NSInteger strokeCount = 0;
            
            @synchronized(self) {
                for (NSMutableDictionary *touch in pendingTouches) {
                    CGPoint location = [[touch objectForKey:@"location"] CGPointValue];
                    NSInteger decayCount = [[touch objectForKey:@"decayCount"] integerValue];
                    UITouchPhase phase = [[touch objectForKey:@"phase"] intValue];
                    
                    // Increase the decay count
                    [touch setObject:[NSNumber numberWithInteger:decayCount+1] forKey:@"decayCount"];
                    if (decayCount >= 0) {
                        [objectsToRemove addObject:touch];
                    }
                    
                    CGFloat diameter = 30 - 20*decayCount;
                    switch (phase) {
                        case UITouchPhaseBegan:
                            startLocation = location;
                            CGContextMoveToPoint(context, location.x, location.y);
                            break;
                        case UITouchPhaseEnded:
                        case UITouchPhaseCancelled:
                            CGContextStrokePath(context);
                            double distance = sqrt((location.y - startLocation.y)*(location.y - startLocation.y) + (location.x - startLocation.x)*(location.x-startLocation.x));

                            if (distance > 10 && strokeCount > 0) {
                                CGPoint lastLocation = (strokeCount < 8 ? lastLocations[8 - strokeCount] : lastLocations[0]);
                                double angle = atan2(location.y - lastLocation.y, location.x - lastLocation.x);
                                NSLog(@"last location: %f, %f.\nCurrent location: %f, %f", lastLocation.y, lastLocation.x, location.y, location.x);
                                NSLog(@"angle: %.2f, distance: %f", angle * 180 / M_PI, distance);

                                CGContextSetRGBFillColor(context, 0, 0, 255, 1.0); 
                                CGContextMoveToPoint(context, location.x, location.y);
                                CGContextAddLineToPoint(context, location.x + 50*cos(angle + M_PI + M_PI/8), location.y + 50*sin(angle + M_PI + M_PI/8));
                                CGContextAddLineToPoint(context, location.x + 50*cos(angle + M_PI - M_PI/8), location.y + 50*sin(angle + M_PI - M_PI/8));
                                CGContextAddLineToPoint(context, location.x, location.y);
                                CGContextFillPath(context);
                            } else {
                                CGContextSetRGBFillColor(context, 0, 0, 255, 0.7);                                 
                                CGContextFillEllipseInRect(context, CGRectMake(location.x - diameter / 2, location.y - diameter / 2, diameter, diameter));                                      
                            }
                            break;
                        case UITouchPhaseMoved:
                        case UITouchPhaseStationary:
                            CGContextAddLineToPoint(context, location.x, location.y);
                            for (NSInteger i = 0; i <= 6; i++) {
                                lastLocations[i] = lastLocations[i+1];
                            }
                            lastLocations[7] = location;
                            strokeCount++;
                            break;
                    }
                }
                [pendingTouches removeObjectsInArray:objectsToRemove];
            }
            
            CGContextSetAllowsAntialiasing(context, NO);
        }
    }
    
    // Retrieve the screenshot image
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGContextRelease(context);
        
    return image;
}

- (void)takeScreenshot
{
    if (!processing) {
        [self performSelectorInBackground:@selector(takeScreenshotInCurrentThread) withObject:nil];
    } else {
        NSLog(@"Frame rate too high to keep up.");
    }
    
    if (_recording) {
        float millisElapsed = [[NSDate date] timeIntervalSinceDate:startedAt] * 1000.0;
        @synchronized(self) {
            [self writeVideoFrameAtTime:CMTimeMake((int)millisElapsed, 1000)];
        } 
    }
}


//static int frameCount = 0;            //debugging

- (void)takeScreenshotInCurrentThread
{
    if (!_recording) return;
    
    processing = YES;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    @synchronized(self) {
        NSLog(@"start screenshot");
        self.currentScreen = [self screenshot];
        NSLog(@"stop screenshot");
    }
    
    /*    //debugging
     if (frameCount < 600) {
     NSString* filename = [NSString stringWithFormat:@"Documents/frame_%d.png", frameCount];
     NSString* pngPath = [NSHomeDirectory() stringByAppendingPathComponent:filename];
     [UIImagePNGRepresentation(self.currentScreen) writeToFile: pngPath atomically: YES];
     frameCount++;
     }*/
    
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
                                         [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];                                      
//                                         [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];                                      
    
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
    if (![videoWriterInput isReadyForMoreMediaData] || !currentScreen) {
        NSLog(@"Not ready for video data");
    } else {
        @synchronized (self) {
            UIImage* newFrame = [self.currentScreen retain];
            CVPixelBufferRef pixelBuffer = NULL;
            CGImageRef cgImage = CGImageCreateCopy([newFrame CGImage]);
            CFDataRef image = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
            
            int status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, avAdaptor.pixelBufferPool, &pixelBuffer);
            if(status != 0){
                //could not get a buffer from the pool
                NSLog(@"Error creating pixel buffer:  status=%d, pixelBufferPool=%p", status, avAdaptor.pixelBufferPool);
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
                
                // UITouch objects seem to get reused. We can't copy or clone them, so create a poor man's touch object using a dictionary.
                NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGPoint:location], @"location",
                                                   [NSNumber numberWithInteger:0], @"decayCount", 
                                                   [NSNumber numberWithInt:touch.phase], @"phase",
                                                   nil];
                [pendingTouches addObject:dictionary];
            }
        }
    }
}

@end